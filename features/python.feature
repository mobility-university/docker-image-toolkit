@disableMissingFeatureDescription
Feature: Python

  # ubuntu, debian, redhat, ...
  # TODO: __pycache__ gets generated and then used.....should not add such files
  @disableTooLongStep
  Scenario: standard
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN apk add python3

      COPY fckubi /fckubi
      RUN export PYTHONDONTWRITEBYTECODE=1 && /fckubi export --path=/export -- /usr/bin/python3.10 -B -c "print('hello')"
      RUN find /export -iname '*.pyc' | xargs rm  # TODO!!!

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then instantiating the image with command «/usr/bin/python3.10 -c print('huhuhi')» results in
      """
      huhuhi
      """
    Then it contains the following files
      """
      lib/ld-musl-x86_64.so.1
      usr/bin/python3.10
      usr/lib/libpython3.10.so.1.0
      usr/lib/python3.10/_collections_abc.py
      usr/lib/python3.10/_sitebuiltins.py
      usr/lib/python3.10/abc.py
      usr/lib/python3.10/codecs.py
      usr/lib/python3.10/encodings/__init__.py
      usr/lib/python3.10/encodings/aliases.py
      usr/lib/python3.10/encodings/utf_8.py
      usr/lib/python3.10/genericpath.py
      usr/lib/python3.10/io.py
      usr/lib/python3.10/os.py
      usr/lib/python3.10/posixpath.py
      usr/lib/python3.10/site.py
      usr/lib/python3.10/stat.py
      """

  Scenario: usage of environment
    Given a file «foo.py» is created
      """
      #!/usr/bin/env python3
      print('worked')
      """
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN apk add python3

      COPY fckubi /fckubi
      COPY foo.py /foo.py
      RUN chmod +x /foo.py

      # TODO: remove PATH
      RUN PATH=/usr/bin /fckubi export --binary /usr/bin/env --path=/export -- /foo.py
      RUN chmod 777 /export/usr/bin/* # TODO
      RUN find /export -iname '*.pyc' | xargs rm  # TODO!!!

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then instantiating the image with command «/foo.py» results in
      """
      worked
      """
    Then it contains the following files
      """
      bin/busybox
      foo.py
      lib/ld-musl-x86_64.so.1
      usr/bin/env
      usr/bin/python3
      usr/bin/python3.10
      usr/lib/libpython3.10.so.1.0
      usr/lib/python3.10/_collections_abc.py
      usr/lib/python3.10/_sitebuiltins.py
      usr/lib/python3.10/abc.py
      usr/lib/python3.10/codecs.py
      usr/lib/python3.10/encodings/__init__.py
      usr/lib/python3.10/encodings/aliases.py
      usr/lib/python3.10/encodings/utf_8.py
      usr/lib/python3.10/genericpath.py
      usr/lib/python3.10/io.py
      usr/lib/python3.10/os.py
      usr/lib/python3.10/posixpath.py
      usr/lib/python3.10/site.py
      usr/lib/python3.10/stat.py
      """

  Scenario: dynamic libraries
    Given a file «foo.py» is created
      """
      import json

      print(json.dumps({"foo": "bar"}))
      """
    And a file «foo.sh» is created
      """
      #!/bin/sh
      /usr/bin/python3.10 /foo.py
      """
    And created a Docker build description like this
      """
      FROM alpine as development

      RUN apk add python3


      COPY fckubi /fckubi
      COPY foo.py /foo.py
      COPY foo.sh /foo.sh

      RUN /fckubi export --path=/export -- sh /foo.sh
      RUN find /export -iname '*.pyc' | xargs rm  # TODO!!!

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then it contains the following files
      """
      bin/busybox
      bin/sh
      foo.py
      foo.sh
      lib/ld-musl-x86_64.so.1
      usr/bin/python3.10
      usr/lib/libpython3.10.so.1.0
      usr/lib/python3.10/_collections_abc.py
      usr/lib/python3.10/_sitebuiltins.py
      usr/lib/python3.10/abc.py
      usr/lib/python3.10/codecs.py
      usr/lib/python3.10/collections/__init__.py
      usr/lib/python3.10/copyreg.py
      usr/lib/python3.10/encodings/__init__.py
      usr/lib/python3.10/encodings/aliases.py
      usr/lib/python3.10/encodings/utf_8.py
      usr/lib/python3.10/enum.py
      usr/lib/python3.10/functools.py
      usr/lib/python3.10/genericpath.py
      usr/lib/python3.10/io.py
      usr/lib/python3.10/json/__init__.py
      usr/lib/python3.10/json/decoder.py
      usr/lib/python3.10/json/encoder.py
      usr/lib/python3.10/json/scanner.py
      usr/lib/python3.10/keyword.py
      usr/lib/python3.10/lib-dynload/_json.cpython-310-x86_64-linux-gnu.so
      usr/lib/python3.10/operator.py
      usr/lib/python3.10/os.py
      usr/lib/python3.10/posixpath.py
      usr/lib/python3.10/re.py
      usr/lib/python3.10/reprlib.py
      usr/lib/python3.10/site.py
      usr/lib/python3.10/sre_compile.py
      usr/lib/python3.10/sre_constants.py
      usr/lib/python3.10/sre_parse.py
      usr/lib/python3.10/stat.py
      usr/lib/python3.10/types.py
      """
    Then instantiating the image with command «/usr/bin/python3.10 /foo.py» results in
      """
      {"foo": "bar"}
      """

  @disableTooLongStep
  Scenario: standard with link
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN apk add python3

      COPY fckubi /fckubi
      RUN export PYTHONDONTWRITEBYTECODE=1 && /fckubi export --path=/export -- /usr/bin/python3 -B -c "print('hello')"
      RUN chmod 777 /export/usr/bin/* # TODO
      RUN find /export -iname '*.pyc' | xargs rm  # TODO!!!

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
      usr/lib/python3.10/_collections_abc.py
      usr/lib/python3.10/_sitebuiltins.py
      usr/lib/python3.10/abc.py
      usr/lib/python3.10/codecs.py
      usr/lib/python3.10/encodings/__init__.py
      usr/lib/python3.10/encodings/aliases.py
      usr/lib/python3.10/encodings/utf_8.py
      usr/lib/python3.10/genericpath.py
      usr/lib/python3.10/io.py
      usr/lib/python3.10/os.py
      usr/lib/python3.10/posixpath.py
      usr/lib/python3.10/site.py
      usr/lib/python3.10/stat.py
      """
    Then instantiating the image with command «/usr/bin/python3 -c print('huhuhi')» results in
      """
      huhuhi
      """
