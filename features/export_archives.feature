Feature: Export Archives

  warn on usage of archives in docker images

  # TODO: check why /bin/busybox is copied
  Scenario: simple build
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN echo '#!/bin/sh' > /my_command && chmod +x /my_command

      COPY docker-image-toolkit /docker-image-toolkit

      RUN /docker-image-toolkit export \
        --binary /my_command --path=/export

      FROM scratch
      COPY --from=development /export /

      """
    When I build this docker image
    Then it contains the following files
      """
      my_command
      """

  Scenario: ldd2
    Given created a Docker build description like this
      """
      FROM alpine as development

      COPY docker-image-toolkit /docker-image-toolkit

      RUN /docker-image-toolkit export \
        --binary /bin/true \
        --binary /bin/false \
        --path=/export

      FROM scratch
      COPY --from=development /export /

      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/false
      bin/true
      lib/ld-musl-x86_64.so.1
      """
