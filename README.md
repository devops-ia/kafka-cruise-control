# Cruise Control for Apache Kafka

## Introduction

Compile an optimize image of Cruise Control for Apache Kafka on Docker. Based on [linkedin/cruise-control](https://github.com/linkedin/cruise-control).

Default versions:

* Cruise Control: `2.5.142`
* Cruise Control UI: `0.4.0`
* AWS IAM Auth: `2.3.1`

## Image details (from dive)

```text
│ Image Details ├─────────────

Total Image size: 273 MB
Potential wasted space: 4.5 MB
Image efficiency score: 98 %
```

You can reproduce this summary with [`dive`](https://github.com/wagoodman/dive):

```command
dive build -t <tag-name> .
```

## Quick start

[**Available images**](https://hub.docker.com/r/devopsiaci/cruise-control/tags)

### Configure `cruise-control.properties`

Review: [sample.cruise-control.properties](./config/cruisecontrol.properties)

### Run container

```command
docker run --name <container-name>            \
  -p 9090:9090                                \
  -v config:/cruise-control/config            \
  -v config/config.csv:/cruise-control/config \
  jdk17-cc2.5.138-iam2.2.0
```

* More samples: [linkedin/cruise-control - configs](https://github.com/linkedin/cruise-control/tree/2.5.138/config)
* More info: [linkedin/cruise-control - wiki](https://github.com/linkedin/cruise-control/wiki/)

## Build your custom image

**REMEMBER**: Kafka and Cruise Control must be have the same Java running version. If you want other Java version check "Change Java version" and rebuild the image. [**All allowed tags**](https://hub.docker.com/r/devopsiaci/cruise-control/tags).

### Pull image

```command
docker build -t <tag-name> .
```

### Replace config

You **must** change the next values with your properly nodes:

```console
bootstrap.servers=<list-kafka-brokers>
zookeeper.connect=<list-zookeeper>
```

### Run container

```command
docker run --name <container-name>            \
  -p 9090:9090                                \
  -v config:/cruise-control/config            \
  -v config/config.csv:/cruise-control/config \
  <tag-name>
```

* More samples: [linkedin/cruise-control - configs](https://github.com/linkedin/cruise-control/tree/2.5.138/config)
* More info: [linkedin/cruise-control - wiki](https://github.com/linkedin/cruise-control/wiki/)

## Configure Nginx

By default, Cruise Control can't change the location path if you want use another than `/`, for example: `/my-kafka-cruise-control`. So, you should configure your webserver to modify the request:

```command
# sample cruise-control location
location /<locationPath> {

    # rewrites
    rewrite ^/<locationPath>/(.*) /$1 break;

    # proxy_pass configuration
    proxy_pass http://<ip-host>:<port-cruise-control>;
    proxy_pass_request_headers on;

    # sub_filters
    sub_filter /static/js          /<locationPath>/static/js;
    sub_filter /static/css         /<locationPath>/static/css;
    sub_filter /static/cc-logo.png /<locationPath>/static/cc-logo.png;
    sub_filter /kafkacruisecontrol /<locationPath>/kafkacruisecontrol;
    sub_filter_last_modified on;
    sub_filter_once off;
    sub_filter_types *;
}
```

## Change Java version

You can compile with other Java version, you can check all posible tags from: [amazoncorretto](https://hub.docker.com/_/amazoncorretto/tags)

```command
docker build --build-arg OPENJDK_VERSION=<version> -t <image-name> . # example version: 11
```

## Change Cruise Control and Cruise Control UI version

You can change the default Cruise Control version and Cruise Control UI version with `CC_TAG` and `CC_UI_TAG` arguments (please check [environment-requirements](https://github.com/linkedin/cruise-control#environment-requirements) and [compatibilities](https://github.com/linkedin/cruise-control#known-compatibility-issues))

```command
docker build --build-arg CC_TAG=<version> --build-arg CC_UI_TAG=<version> -t <image-name> . # example CC_TAG=2.5.138 and CC_UI_TAG=0.4.0
```
