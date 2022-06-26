Feature: Export Dry Run

  As a developer
  I want to specify a dry run command
  so that the images is minimized to exactly this command

  # TODO: ping example? libresolve
  # TODO: probe!
  # TODO: check why /bin/busybox is copied
  # TODO: segfault
  Scenario: simple build
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN echo '#!/bin/sh' > /my_command && chmod +x /my_command

      COPY docker-image-toolkit /docker-image-toolkit

      # TODO: remove binary
      RUN /docker-image-toolkit export --path=/export -- sh ./my_command

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

  @skip
  Scenario: failing call
    Given created a Docker build description like this
      """
      FROM alpine as development

      COPY docker-image-toolkit /docker-image-toolkit

      # TODO: remove binary
      RUN /docker-image-toolkit export --path=/export -- /bin/false

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

  Scenario: simple build «execve syscall»
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN echo '#!/bin/sh' > /my_command && echo "/my_command2" >> /my_command && chmod +x /my_command
      RUN echo '#!/bin/sh' > /my_command2 && chmod +x /my_command2

      COPY docker-image-toolkit /docker-image-toolkit

      # TODO: remove binary
      RUN /docker-image-toolkit export --path=/export -- sh ./my_command

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
      my_command2
      """

  Scenario: chaining
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN echo '#!/bin/sh' > /my_command && echo "echo test" >> /my_command && chmod +x /my_command
      RUN echo '#!/bin/sh' > /my_command2 && echo "echo test" >> /my_command2 && chmod +x /my_command2

      COPY docker-image-toolkit /docker-image-toolkit

      # TODO: remove binary
      RUN /docker-image-toolkit export \
        --path=/export -- ./my_command -- ./my_command2

      FROM scratch
      COPY --from=development /export /

      """
    When I build this docker image
    Then it contains the following files
      """
      my_command
      my_command2
      """

  @skip
  Scenario: follows exec
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN touch /my_file

      COPY docker-image-toolkit /docker-image-toolkit

      # TODO: remove binary
      RUN /docker-image-toolkit export --path=/export -- sh -c "cat /my_file"

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/cat
      bin/sh
      lib/ld-musl-x86_64.so.1
      my_file
      """

  @disableUnknownVariable
  Scenario: plain fork
    Given a file «fork.c» is created
      """
      #include <stdio.h>
      #include <unistd.h>

      int openFile(const char *filename)
      {
          if (!fopen(filename, "r"))
          {
              printf("Failed to open input file\n");
              return 1;
          }
          return 0;
      }

      int main() {
        if (fork() == 0) {
          printf("child\n");
          return openFile("child");
        } else {
          printf("parent\n");
          return openFile("parent");
        }
      }
      """
    Given created a Docker build description like this
      """
      FROM ubuntu as development

      RUN apt update && apt-get install -y gcc

      COPY docker-image-toolkit /docker-image-toolkit
      COPY fork.c /fork.c
      RUN touch /child /parent && gcc /fork.c -o/fork && /fork

      RUN /docker-image-toolkit export --path=/export -- /fork

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      child
      fork
      lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
      lib/x86_64-linux-gnu/libc.so.6
      lib64/ld-linux-x86-64.so.2
      parent
      """

  Scenario: supports «execve»
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN touch /my_file
      RUN echo '#!/bin/sh' > /my_command && \
        echo 'cat /my_file' >> /my_command && \
        chmod +x /my_command

      COPY docker-image-toolkit /docker-image-toolkit

      RUN /docker-image-toolkit export --path=/export -- ./my_command

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/cat
      lib/ld-musl-x86_64.so.1
      my_command
      my_file
      """

  Scenario: supports forking
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN touch /forked_file
      RUN touch /non_forked_file
      RUN echo '#!/bin/sh' > /my_command && \
        echo 'cat /forked_file&' >> /my_command && \
        echo 'cat /non_forked_file' >> /my_command && \
        echo 'wait' >> /my_command && \
        chmod +x /my_command

      COPY docker-image-toolkit /docker-image-toolkit

      RUN /docker-image-toolkit export \
        --path=/export -- ./my_command

      FROM scratch
      COPY --from=development /export /

      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/cat
      lib/ld-musl-x86_64.so.1
      my_command
      forked_file
      non_forked_file
      """
