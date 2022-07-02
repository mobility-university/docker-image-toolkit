@disableMissingFeatureDescription
Feature: Azure function

  @disableTooLongStep
  Scenario: standard
    Given created a Docker build description like this
      """
      FROM python:3.8.13-slim-bullseye as development

      RUN echo "#!/usr/bin/env python3" > test.py \
       && echo "from azure.core.exceptions import HttpResponseError, ResourceNotFoundError" >> /test.py \
       && echo "from azure.identity import DefaultAzureCredential" >> /test.py \
       && echo "from azure.keyvault.secrets import SecretClient" >> /test.py && chmod +x /test.py

      RUN pip3 install --upgrade pip --no-cache-dir && \
          python3 -m pip install --no-cache-dir \
            azure-cli==2.35.0 \
            azure-eventhub-checkpointstoreblob-aio==1.1.4 \
            azure-eventhub==5.7.0 \
            azure-functions==1.11.0 \
            azure-identity==1.9.0 \
            azure-keyvault-administration==4.0.0b3 \
            azure-keyvault-secrets==4.4.0 \
            azure-mgmt-resource==20.0.0

      COPY docker-image-toolkit /bin/docker-image-toolkit
      RUN docker-image-toolkit export \
        --path=/export \
        -- /test.py

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
