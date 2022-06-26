@disableMissingFeatureDescription
Feature: Java

  # ubuntu, debian, redhat, ...
  @disableTooLongStep @skip
  Scenario: standard
    Given created a Docker build description like this
      """
      FROM alpine as development

      RUN apk add openjdk11

      RUN mkdir HelloWorld
      RUN echo "package HelloWorld;" > HelloWorld/Main.java \
      && echo "public class Main {" >> HelloWorld/Main.java \
      && echo "public static void main(String[] args) {" >> HelloWorld/Main.java \
      && echo 'System.out.println("huhuhi");' >> HelloWorld/Main.java \
      && echo "}" >> HelloWorld/Main.java \
      && echo "}" >> HelloWorld/Main.java
      RUN echo 'Manifest-version: 1.0' > Manifest.txt \
      && echo 'Created-By: 1.0 (Macagua Corporation)' >> Manifest.txt \
      && echo 'Main-Class: HelloWorld.Main' >> Manifest.txt
      RUN javac HelloWorld/Main.java
      RUN jar cfm Main.jar Manifest.txt HelloWorld HelloWorld/Main.class
      RUN java -jar Main.jar
      ENV LD_LIBRARY_PATH=/usr/lib/jvm/java-11-openjdk/lib/server/

      COPY docker-image-toolkit /docker-image-toolkit
      RUN /docker-image-toolkit export --path=/export -- /usr/lib/jvm/java-11-openjdk/bin/java -jar Main.jar

      FROM scratch
      COPY --from=development /export /
      """
    When I build this docker image
    Then instantiating the image with command «/usr/lib/jvm/java-11-openjdk/bin/java -jar Main.jar» results in
      """
      huhuhi
      """
    Then it contains the following files
      """
      lib/ld-musl-x86_64.so.1
      lib/libz.so.1
      Main.jar
      usr/lib/jvm/java-11-openjdk/bin/java
      usr/lib/jvm/java-11-openjdk/lib/jli/libjli.so
      usr/lib/jvm/java-11-openjdk/lib/jvm.cfg
      usr/lib/jvm/java-11-openjdk/lib/libjava.so
      usr/lib/jvm/java-11-openjdk/lib/libjimage.so
      usr/lib/jvm/java-11-openjdk/lib/libnet.so
      usr/lib/jvm/java-11-openjdk/lib/libnio.so
      usr/lib/jvm/java-11-openjdk/lib/libverify.so
      usr/lib/jvm/java-11-openjdk/lib/libzip.so
      usr/lib/jvm/java-11-openjdk/lib/modules
      usr/lib/jvm/java-11-openjdk/lib/server/libjvm.so
      """

  Scenario: Spring Boot?
