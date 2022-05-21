# Cruise Control for Apache Kafka

## Introduction

Compile an optimize image of Cruise Control for Apache Kafka on Docker. Based on [linkedin/cruise-control](https://github.com/linkedin/cruise-control).

## Image details (from dive)

```text
│ Image Details ├─────────────

Total Image size: 473 MB
Potential wasted space: 4.5 MB
Image efficiency score: 98 % 
```

You can reproduce this summary with [`dive`](https://github.com/wagoodman/dive):

```command
dive build -t <tag-name> .
```

## Quick start!

**REMEMBER**: Kafka and Cruise Control must be have the same Java running version. If you want other Java version check "Change Java version" and rebuild the image.

### Pull image or build it

```command
docker pull devopsiaci/cruise-control:latest # default "openjdk-11.0.13" java version
```

or

```command
docker build -t <tag-name> .
```

### Replace config

You **must** change the next values with your properly nodes:

* `bootstrap.servers=<list-kafka-brokers>` # <kafka-broker>:<port>,<kafka-broker1>:<port>,<kafka-brokerN>:<port>
* `zookeeper.connect=<list-zookeeper>`     # <zookeeper>:<port>,<zookeeper1>:<port>,<zookeeperN>:<port>

### Run container

```command
docker run --name <container-name>            \
  -p 9090:9090                                \
  -v config:/cruise-control/config            \
  -v config/config.csv:/cruise-control/config \
  <tag-name>
```

* More samples: [linkedin/cruise-control - configs](https://github.com/linkedin/cruise-control/tree/migrate_to_kafka_2_4/config)
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

You can compile with other Java version, you can check all posible tags from: [openjdk](https://hub.docker.com/_/openjdk?tab=tags&page=1&ordering=last_updated&name=jre-slim-buster), remember filter by: `jre-slim-buster` and rebuild the image:

```command
docker build --arg OPENJDK_VERSION=<version> -t <image-name> . # example version: 11.0.15
```

## Contributing

We're happy if you want open and issue or a new feature :)
