@disableMissingFeatureDescription
Feature: NGINX

  # TODO: deal about /var/run/*.pid
  @disableUnknownVariable
  Scenario: Usage
    Given created a Docker build description like this
      """
      FROM nginx:1.21.5-alpine as development

      RUN echo "#!/bin/sh" > /probe.sh \
       && echo "set -e" >> /probe.sh \
       && echo "sleep 1s" >> /probe.sh \
       && echo "curl --fail http://localhost" >> probe.sh \
       && chmod +x /probe.sh

      COPY fckubi /fckubi
      RUN ! ./probe.sh
      RUN /fckubi export \
        --path /export --probe /probe.sh -- nginx -g 'daemon off;'

      FROM scratch
      COPY --from=development /export /

      CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
      """
    When I build this docker image
    Then instantiating this image in the background with
      | options                                                                     |
      | -p=8080:80 --tmpfs=/var/cache/nginx --tmpfs=/var/log/nginx --tmpfs=/var/run |
    Then the image contains the following files
      """
      lib/ld-musl-x86_64.so.1
      lib/libcrypto.so.1.1
      lib/libssl.so.1.1
      lib/libz.so.1
      lib/libz.so.1.2.11
      usr/lib/libpcre2-8.so.0
      usr/lib/libpcre2-8.so.0.10.4
      usr/sbin/nginx
      usr/share/nginx/html/index.html
      var/run/nginx.pid
      """
    Then running «curl -s http://localhost:8080» results in
      """
      <!DOCTYPE html>
      <html>
      <head>
      <title>Welcome to nginx!</title>
      <style>
      html { color-scheme: light dark; }
      body { width: 35em; margin: 0 auto;
      font-family: Tahoma, Verdana, Arial, sans-serif; }
      </style>
      </head>
      <body>
      <h1>Welcome to nginx!</h1>
      <p>If you see this page, the nginx web server is successfully installed and
      working. Further configuration is required.</p>

      <p>For online documentation and support please refer to
      <a href="http://nginx.org/">nginx.org</a>.<br/>
      Commercial support is available at
      <a href="http://nginx.com/">nginx.com</a>.</p>

      <p><em>Thank you for using nginx.</em></p>
      </body>
      </html>
      """

  # usr/share/nginx/html/index.html wird nicht exportiert
  @disableUnknownVariable
  Scenario: Usage...too much sleep
    Given created a Docker build description like this
      """
      FROM nginx:1.21.5-alpine as development

      RUN echo "#!/bin/sh" > /probe.sh \
       && echo "set -e" >> /probe.sh \
       && echo "sleep 1s" >> /probe.sh \
       && echo "curl --fail http://localhost" >> probe.sh \
       && echo "sleep 1s" >> /probe.sh \
       && chmod +x /probe.sh

      COPY fckubi /fckubi
      RUN /fckubi export \
        --path /export --probe /probe.sh -- nginx -g 'daemon off;'

      FROM scratch
      COPY --from=development /export /

      CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
      """
    When I build this docker image
    Then instantiating this image in the background with
      | options                                                                     |
      | -p=8080:80 --tmpfs=/var/cache/nginx --tmpfs=/var/log/nginx --tmpfs=/var/run |
    Then running «curl -s http://localhost:8080» results in
      """
      <!DOCTYPE html>
      <html>
      <head>
      <title>Welcome to nginx!</title>
      <style>
      html { color-scheme: light dark; }
      body { width: 35em; margin: 0 auto;
      font-family: Tahoma, Verdana, Arial, sans-serif; }
      </style>
      </head>
      <body>
      <h1>Welcome to nginx!</h1>
      <p>If you see this page, the nginx web server is successfully installed and
      working. Further configuration is required.</p>

      <p>For online documentation and support please refer to
      <a href="http://nginx.org/">nginx.org</a>.<br/>
      Commercial support is available at
      <a href="http://nginx.com/">nginx.com</a>.</p>

      <p><em>Thank you for using nginx.</em></p>
      </body>
      </html>
      """
    Then the image contains the following files
      """
      lib/ld-musl-x86_64.so.1
      lib/libcrypto.so.1.1
      lib/libssl.so.1.1
      lib/libz.so.1
      lib/libz.so.1.2.11
      usr/lib/libpcre2-8.so.0
      usr/lib/libpcre2-8.so.0.10.4
      usr/sbin/nginx
      usr/share/nginx/html/index.html
      var/run/nginx.pid
      """
