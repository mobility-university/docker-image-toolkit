@disableMissingFeatureDescription
Feature: Motivation

  As a developer
  I want to see the difference between a normal image and a minimized image
  so that I can decide if this is useful in my project

  @skip
  Scenario: simple build
    Given created a Docker build description like this
      """
      FROM alpine:3.15.0 as development

      CMD ["/bin/echo", "hello"]
      """
    When I built this docker image
    Then it contains 367 files
    And it needs 5.6 MB

  @skip
  Scenario: minimized build
    Given created a Docker build description like this
      """
      FROM alpine:3.15.0 as development

      COPY docker-image-toolkit /docker-image-toolkit

      RUN /docker-image-toolkit export --binary /bin/sh --path=/export -- echo "test"

      FROM scratch
      COPY --from=development /export /
      CMD ["/bin/echo", "hello"]

      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/echo
      bin/sh
      lib/ld-musl-x86_64.so.1
      """
    And it contains 4 files
    And it needs 1.4 MB
    And instantiating the image with command «echo test» results in
      """
      test
      """
