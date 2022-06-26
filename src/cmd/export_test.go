package cmd

import (
	"regexp"
	"testing"
)

// TestHelloName calls greetings.Hello with a name, checking
// for a valid return value.
func TestHelloName(t *testing.T) {
	name := "Gladys"
	want := regexp.MustCompile(`\b` + name + `\b`)
	//var a string[] := []
	// TODO: a := exeee(exportCmd, &args)
	msg := "Gladys"
	if !want.MatchString(msg) {
		t.Fatalf(`Hello("Gladys") = %q, want match for %#q, nil`, msg, want)
	}
}
