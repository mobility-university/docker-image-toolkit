package cmd

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"sync"
	"syscall"

	"github.com/spf13/cobra"
	"github.com/u-root/u-root/pkg/ldd"
	"golang.org/mobility-university/fckubi/strace"

	"golang.org/x/sys/unix"
)

var exportPath string = "/export"
var binaries []string
var directories []string
var probes []string
var configs []string
var verbose bool = false

var InfoLogger *log.Logger = log.New(os.Stderr, "INFO: ", log.Ldate|log.Ltime)
var WarningLogger *log.Logger = log.New(os.Stderr, "WARNING: ", log.Ldate|log.Ltime)
var ErrorLogger *log.Logger = log.New(os.Stderr, "ERROR: ", log.Ldate|log.Ltime)

// TODO: differ between write only files

var exportCmd = &cobra.Command{
	Use:   "export",
	Short: "Exports the filesystem needed for operations",
	Long: `Export everything used in your image. Not more, not less.

Add this to your Dockerimage as last step.

RUN /fckubi export --path /export -- /my_custom_program
	`,
	Run: exeee,
}

func CopyRecursive(src, dst string) (err error) {
	sfi, err := os.Stat(src)
	if verbose {
		InfoLogger.Printf("huhu: %s\n", sfi)
	}
	if err != nil {
		panic(fmt.Sprintf("cannot copy %s. %s", src, err))
	}
	target := filepath.Join(dst, src)
	if sfi.Mode().IsRegular() {
		os.MkdirAll(path.Dir(target), os.ModePerm)
		return CopyFile(src, target)
	} else if sfi.Mode().IsDir() {
		return CopyDirectory(src, target)
	} else {
		panic(fmt.Sprintf("%s is a unexpected file type", src))
	}
}

func CopyFile(src, dst string) (err error) {
	if verbose {
		InfoLogger.Printf("copy %s to %s\n", src, dst)
	}
	sfi, err := os.Stat(src)
	if err != nil {
		return
	}
	if !sfi.Mode().IsRegular() {
		// cannot copy non-regular files (e.g., directories,
		// symlinks, devices, etc.)
		return fmt.Errorf("CopyFile: non-regular source file %s (%q)", sfi.Name(), sfi.Mode().String())
	}
	dfi, err := os.Stat(dst)
	if err != nil {
		if !os.IsNotExist(err) {
			return
		}
	} else {
		if !(dfi.Mode().IsRegular()) {
			return fmt.Errorf("CopyFile: non-regular destination file %s (%q)", dfi.Name(), dfi.Mode().String())
		}
		if os.SameFile(sfi, dfi) {
			return
		}
	}
	if err = os.Link(src, dst); err == nil {
		return
	}
	err = copyFileContents(src, dst)
	return
}

// copyFileContents copies the contents of the file named src to the file named
// by dst. The file will be created if it does not already exist. If the
// destination file exists, all it's contents will be replaced by the contents
// of the source file.
func copyFileContents(src, dst string) (err error) {
	in, err := os.Open(src)
	if err != nil {
		return
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return
	}
	defer func() {
		cerr := out.Close()
		if err == nil {
			err = cerr
		}
	}()
	if _, err = io.Copy(out, in); err != nil {
		return
	}
	err = out.Sync()
	return
}

func splitByDelimiter(values []string, delimiter string) [][]string {
	// TODO: unittest :(
	var result [][]string
	var startIdx = 0
	for index, value := range append(values, delimiter) {
		if value == delimiter {
			result = append(result, values[startIdx:index])
			startIdx = index + 1
		}
	}

	return result
}

func exeee(cmd *cobra.Command, args []string) {
	if len(args) == 0 && len(binaries) == 0 && len(configs) == 0 {
		panic("need to provide binaries, configs or remains. running without anything is not allowed")
	}

	if verbose {
		InfoLogger.Printf("parameters (binaries: %v, directories: %v, configs: %v, remains: %v, probes: %v, verbose: %v)\n",
			strings.Join(binaries, ", "), strings.Join(directories, ", "), strings.Join(configs, ", "), strings.Join(args, ", "), strings.Join(probes, ", "), verbose)
	}

	err := os.MkdirAll(exportPath, os.ModePerm)
	if err != nil {
		panic(fmt.Sprintf("cannot create directory %v: %v", exportPath, err))
	}

	// TODO: fail if not binary, no config and also no remaining cmds
	if len(args) > 0 {
		if len(probes) > len(args) {
			panic(fmt.Sprintf("provided %d probes, but just %d commands to run", len(probes), len(args)))
		}
		for index, command := range splitByDelimiter(args, "--") {

			var probe string = ""
			if index < len(probes) {
				probe = probes[index]
			}

			var wg sync.WaitGroup
			wg.Add(1)
			if probe != "" {
				go func() {
					traceCommand(command)
				}()
				// "/bin/ash", "-c",
				cmd := exec.Command("/bin/sh", "-c", probe) // "sleep", "3s") // "/bin/true") // probe) // "/bin/true") // probe)
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				if verbose {
					InfoLogger.Printf("starting probe: %v\n", probe)
				}
				/*err := cmd.Start()
				if err != nil {
					panic(fmt.Sprintf("probe %v failed: %v", probe, err))
				}*/
				/*fmt.Printf("before sleep \n")
				time.Sleep(1 * time.Second)
				fmt.Printf("after sleep \n")*/
				err := cmd.Run()
				if err != nil {
					// TODO: find out why wait sometimes returns error!?
					//if cmd.ProcessState != nil && cmd.ProcessState.ExitCode() != 0 {
					panic(fmt.Sprintf("failed to wait for probe: %v cmd: %v cmd.ps: %v cmd.p: %v", err, cmd, cmd.ProcessState, cmd.Process))
					//}
				}

				wg.Done()
			} else {
				go func() {
					defer wg.Done()
					traceCommand(command)
				}()
			}
			wg.Wait()
		}
	}

	for _, pp := range configs {
		CopyRecursive(pp, exportPath)
	}

	for _, pp := range binaries {
		copyBinary(pp, exportPath)
	}

	for _, pp := range directories {

		os.MkdirAll(filepath.Join(exportPath, pp), os.ModePerm)
		// CopyDirectory(pp, exportPath)
	}
}

func traceCommand(command []string) error {
	if verbose {
		InfoLogger.Printf("execute %v\n", strings.Join(command, " "))
	}
	path, err := exec.LookPath(command[0])
	if err != nil {
		panic(fmt.Sprintf("could not find binary %v", command[0]))
	}
	appendBinary(path)
	cmd := exec.Command(command[0], command[1:]...)

	cmd.Stdin = os.Stdin
	if verbose {
		cmd.Stderr = os.Stderr
		cmd.Stdout = os.Stdout
	}
	runAndCollectTrace(cmd)
	return nil
}

func CopyDirectory(scrDir, dest string) error {
	entries, err := ioutil.ReadDir(scrDir)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		sourcePath := filepath.Join(scrDir, entry.Name())
		destPath := filepath.Join(dest, entry.Name())

		fileInfo, err := os.Stat(sourcePath)
		if err != nil {
			return err
		}

		stat, ok := fileInfo.Sys().(*syscall.Stat_t)
		if !ok {
			return fmt.Errorf("failed to get raw syscall.Stat_t data for '%s'", sourcePath)
		}

		switch fileInfo.Mode() & os.ModeType {
		case os.ModeDir:
			if err := CreateIfNotExists(destPath, 0755); err != nil {
				return err
			}
			if err := CopyDirectory(sourcePath, destPath); err != nil {
				return err
			}
		case os.ModeSymlink:
			if err := CopySymLink(sourcePath, destPath); err != nil {
				return err
			}
		default:
			os.MkdirAll(path.Dir(destPath), os.ModePerm)
			if err := Copy(sourcePath, destPath); err != nil {
				return err
			}
		}

		if err := os.Lchown(destPath, int(stat.Uid), int(stat.Gid)); err != nil {
			return err
		}

		isSymlink := entry.Mode()&os.ModeSymlink != 0
		if !isSymlink {
			if err := os.Chmod(destPath, entry.Mode()); err != nil {
				return err
			}
		}
	}
	return nil
}

func Copy(srcFile, dstFile string) error {
	out, err := os.Create(dstFile)
	if err != nil {
		return err
	}

	defer out.Close()

	in, err := os.Open(srcFile)
	if err != nil {
		panic(fmt.Sprintf("cannot copy %s", srcFile))
	}
	defer in.Close()
	if err != nil {
		return err
	}

	_, err = io.Copy(out, in)
	if err != nil {
		return err
	}

	return nil
}

func Exists(filePath string) bool {
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return false
	}

	return true
}

func CreateIfNotExists(dir string, perm os.FileMode) error {
	if Exists(dir) {
		return nil
	}

	if err := os.MkdirAll(dir, perm); err != nil {
		return fmt.Errorf("failed to create directory: '%s', error: '%s'", dir, err.Error())
	}

	return nil
}

func CopySymLink(source, dest string) error {
	link, err := os.Readlink(source)
	if err != nil {
		return err
	}
	return os.Symlink(link, dest)
}

func isReading(val uint64) bool {
	// TODO!!
	var v = val & syscall.O_ACCMODE
	return v == syscall.O_RDONLY || v == syscall.O_RDWR
	// return (val & syscall.O_ACCMODE & (syscall.O_RDONLY | syscall.O_RDWR)) == 0
}

/*
func isWriting(val uint64) bool {
	return (val & syscall.O_ACCMODE & syscall.O_WRONLY) != 0
}*/

func isDirectory(val uint64) bool {
	return (val&^syscall.O_ACCMODE)&(syscall.O_DIRECTORY|0x20000) != 0
}

// PrintTraces prints every trace event to w.
func RecordSysCallTraces() strace.EventCallback {
	/* open == 2 */

	/*
	   TODO:
	   remember path at ENTER syscall.
	   remove if syscall reports file not found.

	   then also remove write-first-read-second
	*/

	// const OPEN_DIRECTORY = 0x10000
	return func(t strace.Task, record *strace.TraceRecord) error {

		switch record.Event {

		case strace.SyscallEnter:
			if record.Syscall.Sysno == 59 /* execve*/ {
				path, err := strace.ReadString(t, record.Syscall.Args[0].Pointer(), unix.PathMax)
				if err != nil {
					panic(fmt.Sprintf("could not decode execve path: %v", err))
				}
				if path != "<nil>" {
					newPath, errlook := exec.LookPath(path) // TODO: lookup with execve PATH
					if errlook != nil {
						panic(fmt.Sprintf("Cannot find %s in PATH\n%s\n", path, errlook))
					}
					if _, err := os.Stat(newPath); err != nil {
						panic(fmt.Sprintf("File not exists %s\n", newPath))
					}
					// TODO: ignore directories!!!!
					appendBinary(newPath)
				}
			}

		case strace.SyscallExit:
			if record.Syscall.Sysno == 257 /* openat */ {
				path, err := strace.ReadString(t, record.Syscall.Args[1].Pointer(), unix.PathMax)
				if err != nil {
					return nil // TODO: debug into if this temporary files could be handled different
				}
				fileMode := uint64(record.Syscall.Args[2].Uint())
				fileHandle := int64(record.Syscall.Ret[0].Int())
				if fileHandle > 0 {
					if !isDirectory(fileMode) { // } fileMode&OPEN_DIRECTORY == 0 {
						if isReading(fileMode) && fileHandle > 0 { // was before:  fileMode%32768 == 0

							if path != "<nil>" {
								if _, err := os.Stat(path); err != nil {
									panic(fmt.Sprintf("File not exists %s\n", path))
								}

								appendPath(path)
							}
						}
					}
				}
			}
			if record.Syscall.Sysno == 0 /* read */ {
			} else if record.Syscall.Sysno == 228 /* clock_gettime */ {
			} else if record.Syscall.Sysno == 202 /* futex */ {
			} else if record.Syscall.Sysno == 3 /* close */ {
			} else if record.Syscall.Sysno == 4 /* stat */ {
			} else if record.Syscall.Sysno == 9 /* mmap */ {
			} else if record.Syscall.Sysno == 11 /* munmap */ {
			} else if record.Syscall.Sysno == 8 /* lseek */ {
			} else if record.Syscall.Sysno == 10 /* mprotect */ {
			} else if record.Syscall.Sysno == 72 /* fcntl */ {
			} else if record.Syscall.Sysno == 89 /* readlink */ {
			} else if record.Syscall.Sysno == 2 /* open */ {
				fileHandle := int64(record.Syscall.Ret[0].Int())
				path, err := strace.ReadString(t, record.Syscall.Args[0].Pointer(), unix.PathMax)
				if err != nil {
					if record.Syscall.Sysno == 2 /* open */ {
						return nil // TODO: debug into if this temporary files could be handled different
					}
					panic(fmt.Sprintf("could not decode path: %v (%v)", err, record.Syscall.Sysno))
				}
				fileMode := uint64(record.Syscall.Args[1].Uint())

				if !isDirectory(fileMode) { // fileMode&OPEN_DIRECTORY == 0 {
					if isReading(fileMode) && fileHandle > 0 {
						if path != "<nil>" {
							if _, err := os.Stat(path); err != nil {
								panic(fmt.Sprintf("File not exists %s\n", path))
							}
							// TODO: ignore directories!!!!#
							appendPath(path)
						}
					}
				}

				if verbose {
					InfoLogger.Printf("open file %v with %v\n", path, fileMode)
				}
			} else if record.Syscall.Sysno == 21 /* access */ {
				path, err := strace.ReadString(t, record.Syscall.Args[0].Pointer(), unix.PathMax)
				if err != nil {
					panic(fmt.Sprintf("could not decode access path: %v", err))
				}
				result := int64(record.Syscall.Ret[0].Int())

				if result == 0 {
					if path != "<nil>" {
						if _, err := os.Stat(path); err != nil {
							panic(fmt.Sprintf("File not exists %s\n", path))
						}
						// TODO: ignore directories!!!!
						appendPath(path)
					}
				}

				if verbose {
					InfoLogger.Printf("access file %v with %v\n", path, result)
				}
			} else if record.Syscall.Sysno == 59 /* execve*/ {
				path, err := strace.ReadString(t, record.Syscall.Args[0].Pointer(), unix.PathMax)
				if err != nil {
					panic(fmt.Sprintf("could not decode execve path: %v", err))
				}
				if path != "<nil>" {
					if _, err := os.Stat(path); err != nil {
						panic(fmt.Sprintf("File not exists %s\n", path))
					}
					appendBinary(path)
				}
			}
		case strace.NewChild:
			if verbose {
				InfoLogger.Printf("spawning new child %v for %v\n", record.NewChild.PID, record.PID)
			}
		default:
			if verbose {
				InfoLogger.Printf("other event %v\n", record.Event)
			}
		}
		return nil
	}
}

func runAndCollectTrace(cmd *exec.Cmd) []*strace.TraceRecord {
	// Write strace logs to t.Logf.
	if verbose {
		InfoLogger.Printf("running %v\n", cmd)
	}
	traceChan := make(chan *strace.TraceRecord)
	done := make(chan error, 1)

	go func() {
		done <- strace.Trace(cmd, RecordSysCallTraces())
		close(traceChan)
	}()

	var events []*strace.TraceRecord
	for r := range traceChan {
		events = append(events, r)
	}

	if err := <-done; err != nil {
		if os.IsNotExist(err) {
			panic(fmt.Sprintf("Trace exited with error -- did you compile the test programs? (cd ./test && make all): %v", err))
		} else {
			panic(fmt.Sprintf("Trace exited with error: %v", err))
		}
	}
	return events
}

func appendBinary(path string) {
	fileInfo, err := os.Stat(path)
	if err != nil {
		panic(fmt.Sprintf("file %v not avail", path))
	}

	if fileInfo.IsDir() {
		directories = append(directories, path)
	} else if fileInfo.Mode().IsRegular() {
		binaries = append(binaries, path)
	} else {
		panic(fmt.Sprintf("ignoring file: %v", path))
	}
}

func appendPath(path string) {
	fileInfo, err := os.Stat(path)
	if err != nil {
		panic(fmt.Sprintf("file %v not avail", path))
	}
	if fileInfo.IsDir() {
		directories = append(directories, path)
	} else if fileInfo.Mode().IsRegular() {
		configs = append(configs, path)
	} else {
		panic(fmt.Sprintf("ignoring file: %v", path))
	}
}

func copyBinary(src, dst string) {
	// TODO: unroll directories

	copyFileEasy(src, dst)

	dependencies, err := ldd.Ldd([]string{src})
	if err != nil {
		WarningLogger.Printf("ldd failed, but continue: %s -> %s: %s\n", src, dst, err)
	} else {
		for _, dependency := range dependencies {
			copyFileEasy(dependency.FullName, dst)
		}
	}
}

func copyFileEasy(src, pathbb string) {
	target := filepath.Join(pathbb, src)
	os.MkdirAll(path.Dir(target), os.ModePerm)
	CopyFile(src, target)
}

func init() {
	rootCmd.AddCommand(exportCmd)

	exportCmd.PersistentFlags().StringVar(&exportPath, "path", "/export", "path to output minimized file system")
	exportCmd.PersistentFlags().StringArrayVarP(&binaries, "binary", "b", binaries, "binaries to consider")
	exportCmd.PersistentFlags().StringArrayVarP(&configs, "config", "c", configs, "configuration paths to consider")
	exportCmd.PersistentFlags().StringArrayVarP(&probes, "probe", "", probes, "probes to run to")
	exportCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "", false, "verbose output")

}
