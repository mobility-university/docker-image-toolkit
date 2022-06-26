Feature: Help

  As a developer,
  I want to get a help,
  so that I know how to use this tool.

  Scenario: General
    When I execute «fckubi»
    Then I get
      """
      Cause containers should improve security.

      Usage:
        fckubi [command]

      Available Commands:
        apply       applies fckubi into a docker image
        completion  Generate the autocompletion script for the specified shell
        export      Exports the filesystem needed for operations
        help        Help about any command
        inspect     inspects a docker container for unused files
        scan        Scans a docker image for vulnerabilities / bad practices
        validate    validates a docker image if fckubi is applied correct

      Flags:
        -h, --help     help for fckubi
        -t, --toggle   Help message for toggle

      Use "fckubi [command] --help" for more information about a command.
      """

  Scenario: export
    When I execute «fckubi export --help»
    Then I get
      """
      Export everything used in your image. Not more, not less.

      Add this to your Dockerimage as last step.

      RUN /fckubi export --path /export -- /my_custom_program

      Usage:
        fckubi export [flags]

      Flags:
        -b, --binary stringArray   binaries to consider
        -c, --config stringArray   configuration paths to consider
        -h, --help                 help for export
            --path string          path to output minimized file system (default "/export")
            --probe stringArray    probes to run to
            --verbose              verbose output
      """
