ARG OPENJDK_VERSION=11.0.13

FROM openjdk:${OPENJDK_VERSION}-slim-buster as base

ARG CC_TAG=migrate_to_kafka_2_5
ARG CC_UI_TAG=0.3.4

RUN apt update && apt install -y --no-install-recommends wget git                                                            && \
    git clone -b ${CC_TAG} https://github.com/linkedin/cruise-control.git                                                    && \
    wget https://github.com/linkedin/cruise-control-ui/releases/download/v${CC_UI_TAG}/cruise-control-ui-${CC_UI_TAG}.tar.gz && \
    tar xzvf cruise-control-ui-${CC_UI_TAG}.tar.gz                                                                           && \
    mv cruise-control-ui cruise-control/                                                                                     && \
    rm -f cruise-control*.tar.gz

WORKDIR /cruise-control

RUN ./gradlew jar && ./gradlew jar copyDependantLibs                               && \
    mv cruise-control/build/libs/cruise-control-*.jar                                 \
       cruise-control/build/libs/cruise-control.jar                                && \
    mv cruise-control/build/dependant-libs/cruise-control-metrics-reporter-*.jar      \
       cruise-control/build/dependant-libs/cruise-control-metrics-reporter.jar

FROM openjdk:${OPENJDK_VERSION}-jre-slim-buster

LABEL maintainer="Iván Alejandro Marugán <hello@ialejandro.rocks>"                               \
      description="Cruise Control for Apache Kafka (https://github.com/linkedin/cruise-control)" \
      version="1.0.0"

RUN mkdir -p /cruise-control/cruise-control-ui
COPY --from=base /cruise-control/cruise-control/build/libs/cruise-control.jar /cruise-control/cruise-control/build/libs/cruise-control.jar
COPY --from=base /cruise-control/config /cruise-control/config
COPY --from=base /cruise-control/kafka-cruise-control-start.sh /cruise-control/
COPY --from=base /cruise-control/cruise-control/build/dependant-libs /cruise-control/cruise-control/build/dependant-libs
COPY --from=base /cruise-control/cruise-control-ui/dist /cruise-control/cruise-control-ui/dist
RUN echo "local,local,/kafkacruisecontrol/" > /cruise-control/cruise-control-ui/dist/static/config.csv

WORKDIR /cruise-control

CMD ["./kafka-cruise-control-start.sh", "config/cruisecontrol.properties"]
