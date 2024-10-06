# jarppe/clj-build:latest Docker image for clj/cljs development

Debian 12 slim based image with PostgreSQL client, recent Java, Clojure, Babashka
and Bun installed.

## Build

To build and push new image, run:

```bash
$ docker:build
```

## Extend

Project dev container image:

```Dockerfile
FROM jarppe/clj-build:latest AS build

COPY ./deps.edn /app/
RUN ["clojure", "-A:dev:test:calva", "-P"]
```

Project deployment image:

```Dockerfile
FROM jarppe/clj-build:latest AS build

# Download deps:

COPY ./deps.edn /app/
RUN ["clojure", "-P"]

# Build app:

COPY ./bb.edn ./src /app/
RUN bb build

# Make JRE:

ARG MODULES=java.base,java.logging
RUN \
  jlink --add-modules ${MODULES}                                                   \
        --strip-debug                                                              \
        --strip-java-debug-attributes                                              \
        --no-man-pages                                                             \
        --no-header-files                                                          \
        --vm=server                                                                \
        --include-locales=en                                                       \
        --compress=zip-6                                                           \
        --generate-cds-archive                                                     \
        --output /workspace/java

#
# Dist image:
#

FROM gcr.io/distroless/base-nossl:nonroot AS dist

WORKDIR /app

ARG JAVA_TOOL_OPTIONS="-XX:+UseG1GC -XX:MaxRAMPercentage=85 -XX:-OmitStackTraceInFastThrow -XX:ActiveProcessorCount=4"

COPY --from=build  /workspace/java            /opt/java
COPY --from=build  /workspace/target/app.jar  /workspace/app.jar

ENV TZ=UTC
ENV JAVA_HOME=/opt/java
ENV PATH=${JAVA_HOME}/bin:$PATH
ENV JAVA_TOOL_OPTIONS=${JAVA_TOOL_OPTIONS}

ENTRYPOINT ["/opt/java/bin/java"]
CMD ["-jar", "./app.jar"]
```
