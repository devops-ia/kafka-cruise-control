# Cruise Control for Apache Kafka

## Introduction

Optimized multi-stage Docker image for Cruise Control for Apache Kafka. Based on [cruise-control-for-kafka/cruise-control](https://github.com/cruise-control-for-kafka/cruise-control).

- **Cruise Control Server**: Java-based service for managing Kafka clusters
- **Multi-stage builds**: Optimized images with separate build and runtime stages
- **Security**: Non-root users and minimal attack surface
- **AWS MSK IAM Auth**: Built-in support for AWS MSK authentication

Default versions:

- Cruise Control: `3.1.0`
- AWS IAM Auth: `2.3.9`
- Java (Amazon Corretto): `17`

## Supported versions and migration from 2.x

These images only support Cruise Control **3.x** (`3.1.0` or newer). Cruise Control 3.1.0 requires Java 17 and builds against Kafka `4.3.1`.

- **Cruise Control 2.x**: not built anymore. The `jdk17-cc2.5.146-*` images already published keep working; keep using them if you need 2.x.
- **Metrics reporter**: update `cruise-control-metrics-reporter` on every Kafka broker to the 3.1.0 version, together with the server. The jar is shipped in the image at `/cruise-control/cruise-control/build/dependant-libs/cruise-control-metrics-reporter.jar`.
- **Configuration**: the logging file is now `log4j2.properties` (`log4j.properties` is not read anymore), and `cluster.configs.file` points to `config/clusterConfigs.json`. If you mount `config/` over `/cruise-control/config`, it must contain every file referenced by `cruisecontrol.properties` (see [config](./config)).
- **ZooKeeper**: `zookeeper.connect` is not needed; the server starts against a Kafka KRaft cluster without it.

Java versions:

| Java | Status | Reason |
|------|--------|--------|
| 17 | Supported (default) | Required by Cruise Control 3.1.0 |
| 21 | Supported | Image builds and runs against Kafka KRaft without reflection or Jetty errors |
| 25 | Not supported | The Cruise Control 3.1.0 build uses Gradle 8.5, which cannot run on JDK 25 |
| 11 | Not supported | Cruise Control 3.x requires Java 17 |

Compatible Kafka versions: `2.5` to `4.3`, see the [environment requirements](https://github.com/cruise-control-for-kafka/cruise-control/tree/3.1.0#environment-requirements).

## Available images

The build process generates one image, **cruise-control**: the server component (Java-based).

The web UI is not part of this repository anymore. It lives in [devops-ia/kafka-cruise-control-ui](https://github.com/devops-ia/kafka-cruise-control-ui), which publishes its own image. That repository can also build the previous LinkedIn UI locally with `--target legacy`.

[**View all available tags**](https://hub.docker.com/r/devopsiaci/cruise-control/tags)

## Architecture

The Dockerfile uses a multi-stage build approach:

```text
┌─────────────────┐
│  Build Stage    │  Amazon Corretto + Git
│  (build)        │  - Clone Cruise Control
│                 │  - Compile JAR files
│                 │  - Download AWS MSK IAM Auth
└────────┬────────┘
         │
┌────────▼────────┐
│ cruise-control  │
│                 │
│ Runtime: Java   │
│ User: nobody    │
│ Port: 9090      │
└─────────────────┘
```

## Quick start

### `cruise-control`

Run the server component:

```bash
docker run --name cruise-control-server \
  -p 9090:9090 \
  -v $(pwd)/config:/cruise-control/config \
  devopsiaci/cruise-control:jdk17-cc3.1.0-iam2.3.9
```

## Configuration

### Configure `cruise-control.properties`

You must customize the configuration file with your Kafka cluster details. Review the sample configuration:

- [Sample cruisecontrol.properties](./config/cruisecontrol.properties)
- [Cruise Control configs](https://github.com/cruise-control-for-kafka/cruise-control/tree/3.1.0/config)

Required configuration values:

```properties
bootstrap.servers=<kafka-broker-1>:9092,<kafka-broker-2>:9092

# Webserver configuration
webserver.http.port=9090
webserver.api.urlprefix=/kafkacruisecontrol
webserver.session.path=/

# Topic configuration
partition.metric.sample.store.topic=__CruiseControlMetrics
broker.metric.sample.store.topic=__CruiseControlModelTrainingSamples
metric.reporter.topic=__CruiseControlMetrics
```

## Build custom images

### Build arguments

Available build arguments:

| Argument | Default | Description |
|----------|---------|-------------|
| `OPENJDK_VERSION` | `17` | Amazon Corretto Java version |
| `CC_TAG` | `3.1.0` | Cruise Control version |
| `AWS_MSK_IAM_AUTH_VERSION` | `2.3.9` | AWS MSK IAM Auth library version |

### Build the image

Build the `cruise-control` server:

```bash
docker build \
  --target cruise-control \
  --build-arg CC_TAG=3.1.0 \
  --build-arg OPENJDK_VERSION=17 \
  --build-arg AWS_MSK_IAM_AUTH_VERSION=2.3.9 \
  -t my-cruise-control:latest \
  .
```

### Build with different `Java` version

IMPORTANT: Kafka and Cruise Control must use the same Java version.

```bash
docker build \
  --target cruise-control \
  --build-arg OPENJDK_VERSION=21 \
  -t cruise-control:jdk21 \
  .
```

Supported Java versions: `17` and `21` (see [Supported versions](#supported-versions-and-migration-from-2x)). Image tags are published as `jdk<N>-cc<CC_TAG>-iam<AWS_MSK_IAM_AUTH_VERSION>`.

### Build with different cruise-control version

Check compatibility before changing versions:

- [Environment Requirements](https://github.com/cruise-control-for-kafka/cruise-control#environment-requirements)
- [Known Compatibility Issues](https://github.com/cruise-control-for-kafka/cruise-control#known-compatibility-issues)

```bash
docker build \
  --target cruise-control \
  --build-arg CC_TAG=<3.x-tag> \
  -t cruise-control:<3.x-tag> \
  .
```

## `docker-compose` sample

Example `docker-compose.yml` for running the server:

```yaml
version: '3.8'

services:
  cruise-control:
    image: devopsiaci/cruise-control:jdk17-cc3.1.0-iam2.3.9
    container_name: cruise-control-server
    ports:
      - "9090:9090"
    volumes:
      - ./config:/cruise-control/config:ro
    environment:
      JAVA_OPTS: "-Xms512m -Xmx2g -Djava.security.egd=file:/dev/./urandom"
    restart: unless-stopped
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
