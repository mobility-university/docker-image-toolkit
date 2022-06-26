@disableMissingFeatureDescription
Feature: Report Unused

  # TODO: Report files which are unused
  @skip @disableTooLongStep
  Scenario: standard
    Given created a Docker build description like this
      """
      FROM alpine

      # FIXME: replace python3 by a static docker-image-toolkit binary
      RUN apk add python3 strace
      COPY src/docker-image-toolkit.py /docker-image-toolkit
      RUN echo "#!/bin/sh" > /start.sh \
       && echo "echo hello" >> /start.sh \
       && echo "sleep 5s" >> /start.sh \
       && chmod +x /start.sh

      CMD ["/start.sh"]

      """
    When I build this docker image
    Then instantiating the image with command «/docker-image-toolkit --trace-unused-files=/unused --destination=/TODO_delete -- /start.sh» results in
      """
      huhuhi
      """
