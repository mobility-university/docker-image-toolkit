Feature: Help

  As a developer,
  I want to get a help,
  so that I know how to use this tool.

  Scenario: General
    When I execute «docker-image-toolkit»
    Then I get
      """
      Cause containers should improve security.

      Usage:
        docker-image-toolkit [command]

      Available Commands:
        apply       applies docker-image-toolkit into a docker image
        completion  Generate the autocompletion script for the specified shell
        export      Exports the filesystem needed for operations
        help        Help about any command
        inspect     inspects a docker container for unused files
        scan        Scans a docker image for vulnerabilities / bad practices
        validate    validates a docker image if docker-image-toolkit is applied correct

      Flags:
        -h, --help     help for docker-image-toolkit
        -t, --toggle   Help message for toggle

      Use "docker-image-toolkit [command] --help" for more information about a command.
      """

  Scenario: export
    When I execute «docker-image-toolkit export --help»
    Then I get
      """
      Export everything used in your image. Not more, not less.

      Add this to your Dockerimage as last step.

      RUN /docker-image-toolkit export --path /export -- /my_custom_program

      Usage:
        docker-image-toolkit export [flags]

      Flags:
        -b, --binary stringArray   binaries to consider
        -c, --config stringArray   configuration paths to consider
        -h, --help                 help for export
            --path string          path to output minimized file system (default "/export")
            --probe stringArray    probes to run to
            --verbose              verbose output
      """
