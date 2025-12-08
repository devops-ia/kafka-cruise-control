# syntax=docker/dockerfile:1
ARG OPENJDK_VERSION=17
ARG NGINX_VERSION=1.25-alpine

###
# build stage
###
FROM amazoncorretto:${OPENJDK_VERSION} AS build

ARG CC_TAG=3.0.3
ARG CC_UI_TAG=0.4.0
ARG AWS_MSK_IAM_AUTH_VERSION=2.3.5

WORKDIR /cruise-control

RUN yum install -y git tar gzip curl && \
    git clone --depth 1 -b ${CC_TAG} https://github.com/linkedin/cruise-control.git . && \
    curl -fsSL -o cruise-control-ui.tar.gz \
      "https://github.com/linkedin/cruise-control-ui/releases/download/v${CC_UI_TAG}/cruise-control-ui-${CC_UI_TAG}.tar.gz" && \
    tar xzf cruise-control-ui.tar.gz && \
    mv cruise-control-ui cruise-control/ && \
    rm -f cruise-control-ui.tar.gz && \
    ./gradlew --no-daemon --no-parallel -x test jar copyDependantLibs && \
    mv cruise-control/build/libs/cruise-control-*.jar cruise-control/build/libs/cruise-control.jar && \
    mv cruise-control/build/dependant-libs/cruise-control-metrics-reporter-*.jar cruise-control/build/dependant-libs/cruise-control-metrics-reporter.jar && \
    curl -fsSL -o cruise-control/build/libs/aws-msk-iam-auth.jar \
      "https://github.com/aws/aws-msk-iam-auth/releases/download/v${AWS_MSK_IAM_AUTH_VERSION}/aws-msk-iam-auth-${AWS_MSK_IAM_AUTH_VERSION}-all.jar" && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/* /var/tmp/* ~/.gradle/caches/* ~/.gradle/wrapper/* cruise-control/.git

###
# cruise-control-ui
###
FROM nginx:${NGINX_VERSION} AS cruise-control-ui

ARG CC_UI_TAG=0.4.0
ARG UI_USER=nginx
ARG UI_UID=101
ARG UI_GID=101

LABEL maintainer="Iván Alejandro Marugán <hello@ialejandro.rocks>" \
      org.opencontainers.image.title="Cruise Control UI" \
      org.opencontainers.image.description="Cruise Control UI with Nginx" \
      org.opencontainers.image.version="${CC_UI_TAG}"

COPY --from=build --chown=${UI_UID}:${UI_GID} /cruise-control/cruise-control/cruise-control-ui/dist /usr/share/nginx/html

RUN mkdir -p /usr/share/nginx/html/static && \
    printf "local,local,/kafkacruisecontrol/\n" > /usr/share/nginx/html/static/config.csv && \
    chown -R ${UI_UID}:${UI_GID} /usr/share/nginx/html

USER ${UI_UID}

CMD ["nginx", "-g", "daemon off;"]

###
# cruise-control
###
FROM amazoncorretto:${OPENJDK_VERSION} AS cruise-control

ARG CC_TAG=3.0.3
ARG CC_USER=nobody
ARG CC_UID=99
ARG CC_GID=99

LABEL maintainer="Iván Alejandro Marugán <hello@ialejandro.rocks>" \
      org.opencontainers.image.title="Cruise Control" \
      org.opencontainers.image.description="Cruise Control server" \
      org.opencontainers.image.version="${CC_TAG}"

COPY --from=build --chown=${CC_UID}:${CC_GID} /cruise-control/config /cruise-control/config
COPY --from=build --chown=${CC_UID}:${CC_GID} /cruise-control/cruise-control/build/dependant-libs /cruise-control/cruise-control/build/dependant-libs
COPY --from=build --chown=${CC_UID}:${CC_GID} /cruise-control/cruise-control/build/libs/cruise-control.jar /cruise-control/cruise-control/build/libs/cruise-control.jar
COPY --from=build --chown=${CC_UID}:${CC_GID} /cruise-control/cruise-control/build/libs/aws-msk-iam-auth.jar /cruise-control/cruise-control/build/libs/aws-msk-iam-auth.jar
COPY --from=build --chown=${CC_UID}:${CC_GID} /cruise-control/kafka-cruise-control-start.sh /cruise-control/kafka-cruise-control-start.sh

RUN chmod +x /cruise-control/kafka-cruise-control-start.sh

USER ${CC_USER}
WORKDIR /cruise-control

CMD ["./kafka-cruise-control-start.sh", "config/cruisecontrol.properties"]
