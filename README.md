# Docker Image Toolkit

[![ci](https://github.com/mobility-university/docker-image-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/mobility-university/docker-image-toolkit/actions/workflows/ci.yml)

"_minimize images, maximize security, spin up faster_"

# Motivation

Docker should make the internet more secure.
But many images just base on an old base image and install your software on top of it. This results that you need to care about your security vulnerabilities as well as the security vulnerabilites in the base image. And due to mostly quite huge base images, they tend to contain many vulnerabilities.

It's quite difficult to built a image from scratch with just a static binary at the moment. There are different solutions for this:
* by using a systems programming language like:
  * Go: [Flags for compiling static binaries -ldflags '-extldflags "-static -lstdc++ -lm"'](https://github.com/golang/go/issues/40711)
  * Rust: [Flags for compiling static binaries: rustflags = ["-C", "target-feature=+crt-static"]](https://github.com/rust-lang/rust/blob/master/RELEASES.md#version-1190-2017-07-20)
  * D: [Flags for compiling static binaries: dflags "-static" platform="posix"](https://forum.dlang.org/post/udunaxcalnsrnzoomunq@forum.dlang.org)
  * C# [native single-executable](https://www.gdatasoftware.com/blog/2019/04/31587-native-single-binary-net-core)
  * C / C++
  * ...
* by using a framework, which hides the magic
  * [GraalVM for script languages like java, python, R](https://www.graalvm.org/)
  * [Custom static Python binary](https://wiki.python.org/moin/BuildStatically)
  * ...

There are solutions, but all are quite language/framework specific and not easy to use. 

## Is an alpine based image a solution?

Alpine images are smaller, so basically contain probably fewer vulnerabilites. But you need to switch your application from glibc to muslc. If you are unfamiliar with this, then this could introduce some confusion. Also is

## Do distroless images solve this?

Yes, partly. First they are difficult to use and for example the distroless python3 image contains more than your python3 application probably needs which could result in vulnerabilities.

# Solution

## Manual solution (ugly)

```Dockerfile
FROM ubuntu:20.04

# install everything needed for your app
RUN apt-get install -y my-binary-to-use
COPY my-awesome-app /my-awesome-app

# delete now everything that is not needed
RUN apt-get remove -y bash ash perl curl ... 
```

in case your application is a static image, it could be even simpler like

```Dockerfile
FROM scratch
COPY my-awesome-app /my-awesome-app
```

The idea now is to combine these two approaches. Take your app. Do not mind if it is a static binary or not and copy everything it needs to a empty docker image.

```Dockerfile
FROM ubuntu:20.04 as development # need to name the first layer

# install everything needed for your app
RUN apt-get install -y my-binary-to-use
COPY my-awesome-app /my-awesome-app

ADD https://github.com/mobility-university/docker-image-toolkit/v0.1.0/docker-image-toolkit.tar /bin
RUN docker-image-toolkit export \
  --path /export \
  --binary $(which my-binary-to-use) -- \
  /my-awesome-app --check

# now start a new empty docker image
FROM scratch
COPY --from=development:/export /
```

## References

- https://github.com/thomasfricke/container-hardening/blob/main/harden
- https://github.com/GoogleContainerTools/distroless
- https://github.com/docker-slim/docker-slim
- https://stenci.la/blog/2017-07-docker-with-strace/
