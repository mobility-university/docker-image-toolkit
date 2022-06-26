@disableMissingFeatureDescription @disableUseOutline
Feature: Dry Run

  Scenario: used files
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN echo "#!/bin/sh" > /my_command
      RUN chmod +x /my_command

      COPY docker-image-toolkit /docker-image-toolkit

      # TODO: remove binary
      RUN /docker-image-toolkit export \
        --binary /bin/sh \
        --path=/export -- ./my_command

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/sh
      lib/ld-musl-x86_64.so.1
      my_command
      """
