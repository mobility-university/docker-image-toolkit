Feature: Export_Binary

  As a developer,
  I want to specify binaries to be exported,
  so that I can add them when I know they are used during run time.

  # TODO: check why /bin/busybox is copied
  Scenario: Simple
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN echo '#!/bin/sh' > /my_command && chmod +x /my_command

      COPY fckubi /fckubi

      RUN /fckubi export --binary /my_command --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      my_command
      """

  Scenario: binary dependencies
    Given created a Docker build description like this
      """
      FROM alpine as development

      COPY fckubi /fckubi

      RUN /fckubi export --binary /bin/true --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/true
      lib/ld-musl-x86_64.so.1
      """

  @skip
  Scenario: binary dependencies with soft link
    Given created a Docker build description like this
      """
      FROM alpine as development

      COPY fckubi /fckubi
      RUN ln -s /bin/busybox /bin/my_symlink

      RUN /fckubi export --binary /bin/my_symlink --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/my_symlink
      lib/ld-musl-x86_64.so.1
      """

  Scenario: binary dependencies with hard link
    Given created a Docker build description like this
      """
      FROM alpine as development

      COPY fckubi /fckubi
      RUN ln /bin/busybox /bin/my_symlink

      RUN /fckubi export --binary /bin/my_symlink --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      bin/my_symlink
      lib/ld-musl-x86_64.so.1
      """

  Scenario: binary dependencies with hardlink2
    Given created a Docker build description like this
      """
      FROM alpine as development

      COPY fckubi /fckubi
      RUN apk update && apk add python3
      RUN ln /bin/busybox /bin/my_symlink

      RUN /fckubi export \
        --binary /usr/bin/python3 \
        --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      lib/ld-musl-x86_64.so.1
      usr/bin/python3
      usr/bin/python3.10
      usr/lib/libpython3.10.so.1.0
      """

  Scenario: ldd2
    Given created a Docker build description like this
      """
      FROM alpine as development

      COPY fckubi /fckubi

      RUN /fckubi export \
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
