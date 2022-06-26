Feature: Export Configuration

  As a developer,
  I want to export configuration,
  so that I can make sure it exists in the final image

  # TODO: check why /bin/busybox is copied
  Scenario: files
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN touch /my_file

      COPY docker-image-toolkit /docker-image-toolkit
      RUN /docker-image-toolkit export \
        --config /my_file --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      my_file
      """

  Scenario: folders
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN mkdir -p /my_folder

      COPY docker-image-toolkit /docker-image-toolkit
      RUN /docker-image-toolkit export \
        --config /my_folder --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """

      """

  Scenario: recursive
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN mkdir -p /my_folder && touch /my_folder/my_file

      COPY docker-image-toolkit /docker-image-toolkit
      RUN /docker-image-toolkit export \
        --config /my_folder --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      my_folder/my_file
      """

  Scenario: files in sub folders
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN mkdir -p /my_folder && touch /my_folder/my_file

      COPY docker-image-toolkit /docker-image-toolkit
      RUN /docker-image-toolkit export \
        --config /my_folder/my_file --path=/export

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      my_folder/my_file
      """
