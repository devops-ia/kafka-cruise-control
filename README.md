# Cruise Control for Apache Kafka

## Introduction

Optimized multi-stage Docker images for Cruise Control and Cruise Control UI for Apache Kafka. Based on [linkedin/cruise-control](https://github.com/linkedin/cruise-control).

- **Cruise Control Server**: Java-based service for managing Kafka clusters
- **Cruise Control UI**: Nginx-based web interface with multi-cluster support
- **Multi-stage builds**: Optimized images with separate build and runtime stages
- **Security**: Non-root users and minimal attack surface
- **AWS MSK IAM Auth**: Built-in support for AWS MSK authentication

Default versions:

- Cruise Control: `3.0.3`
- Cruise Control UI: `0.4.0`
- AWS IAM Auth: `2.3.5`
- Java (Amazon Corretto): `17`
- Nginx: `1.25-alpine`

## Available images

The build process generates two separate images:

1. **cruise-control**: Server component (Java-based)
2. **cruise-control-ui**: Web interface (Nginx-based)

[**View all available tags**](https://hub.docker.com/r/devopsiaci/cruise-control/tags)

## Architecture

The Dockerfile uses a multi-stage build approach:

```text
┌─────────────────┐
│  Build Stage    │  Amazon Corretto + Git
│  (build)        │  - Clone Cruise Control
│                 │  - Download UI assets
│                 │  - Compile JAR files
│                 │  - Download AWS MSK IAM Auth
└────────┬────────┘
         │
         ├──────────────────────┬─────────────────────┐
         │                      │                     │
┌────────▼────────┐    ┌────────▼────────┐   ┌───────▼──────┐
│ cruise-control  │    │cruise-control-ui│   │  Artifacts   │
│                 │    │                 │   │   Discarded  │
│ Runtime: Java   │    │ Runtime: Nginx  │   └──────────────┘
│ User: nobody    │    │ User: nginx     │
│ Port: 9090      │    │ Port: 80        │
└─────────────────┘    └─────────────────┘
```

## Quick start

### `cruise-control`

Run the server component:

```bash
docker run --name cruise-control-server \
  -p 9090:9090 \
  -v $(pwd)/config:/cruise-control/config \
  devopsiaci/cruise-control:jdk17-cc3.0.3-iam2.3.5
```

### `cruise-control-ui`

Run the UI component with multi-cluster support:

```bash
docker run --name cruise-control-ui \
  -p 8080:80 \
  -v $(pwd)/config.csv:/usr/share/nginx/html/static/config.csv:ro \
  devopsiaci/cruise-control-ui:0.4.0
```

The `config.csv` file format for multi-cluster configuration:

```csv
<group>,<cluster-name>,<cruise-control-url>
develop,cluster-dev,/cluster-dev/kafkacruisecontrol/
staging,cluster-staging,/cluster-staging/kafkacruisecontrol/
cluster,cluster-prod,/cluster-prod/kafkacruisecontrol/
```

## Configuration

### Configure `cruise-control.properties`

You must customize the configuration file with your Kafka cluster details. Review the sample configuration:

- [Sample cruisecontrol.properties](./config/cruisecontrol.properties)
- [LinkedIn Cruise Control configs](https://github.com/linkedin/cruise-control/tree/3.0.3/config)

Required configuration values:

```properties
bootstrap.servers=<kafka-broker-1>:9092,<kafka-broker-2>:9092
zookeeper.connect=<zookeeper-1>:2181,<zookeeper-2>:2181

# Webserver configuration
webserver.http.port=9090
webserver.api.urlprefix=/kafkacruisecontrol
webserver.session.path=/

# Topic configuration
partition.metric.sample.store.topic=__CruiseControlMetrics
broker.metric.sample.store.topic=__CruiseControlModelTrainingSamples
metric.reporter.topic=__CruiseControlMetrics
```

### Multi-cluster UI configuration

Create a `config.csv` file to configure multiple Kafka clusters in the UI:

```csv
develop,dev-kafka,/dev/kafkacruisecontrol/
develop,dev-kafka-2,/dev-2/kafkacruisecontrol/
staging,staging-kafka,/staging/kafkacruisecontrol/
cluster,prod-kafka,/prod/kafkacruisecontrol/
cluster,prod-kafka-dr,/prod-dr/kafkacruisecontrol/
```

Format: `<group>,<cluster-name>,<path-to-cruise-control-api>`

The UI will group clusters by the first column, making it easier to manage multiple environments.

## Build custom images

### Build arguments

Available build arguments:

| Argument | Default | Description |
|----------|---------|-------------|
| `OPENJDK_VERSION` | `17` | Amazon Corretto Java version |
| `NGINX_VERSION` | `1.25-alpine` | Nginx version for UI |
| `CC_TAG` | `3.0.3` | Cruise Control version |
| `CC_UI_TAG` | `0.4.0` | Cruise Control UI version |
| `AWS_MSK_IAM_AUTH_VERSION` | `2.3.5` | AWS MSK IAM Auth library version |

### Build both Images

Build the `cruise-control` server:

```bash
docker build \
  --target cruise-control \
  --build-arg CC_TAG=3.0.3 \
  --build-arg OPENJDK_VERSION=17 \
  --build-arg AWS_MSK_IAM_AUTH_VERSION=2.3.5 \
  -t my-cruise-control:latest \
  .
```

Build the `cruise-control-ui`:

```bash
docker build \
  --target cruise-control-ui \
  --build-arg CC_UI_TAG=0.4.0 \
  --build-arg NGINX_VERSION=1.25-alpine \
  -t my-cruise-control-ui:latest \
  .
```

### Build with different `Java` version

IMPORTANT: Kafka and Cruise Control must use the same Java version.

```bash
docker build \
  --target cruise-control \
  --build-arg OPENJDK_VERSION=11 \
  -t cruise-control:jdk11 \
  .
```

Supported Java versions: [Amazon Corretto tags](https://hub.docker.com/_/amazoncorretto/tags)

### Build with different cruise-control version

Check compatibility before changing versions:

- [Environment Requirements](https://github.com/linkedin/cruise-control#environment-requirements)
- [Known Compatibility Issues](https://github.com/linkedin/cruise-control#known-compatibility-issues)

```bash
docker build \
  --target cruise-control \
  --build-arg CC_TAG=2.5.138 \
  -t cruise-control:2.5.138 \
  .
```

## `docker-compose` sample

Example `docker-compose.yml` for running both server and UI:

```yaml
version: '3.8'

services:
  cruise-control:
    image: devopsiaci/cruise-control:jdk17-cc3.0.3-iam2.3.5
    container_name: cruise-control-server
    ports:
      - "9090:9090"
    volumes:
      - ./config:/cruise-control/config:ro
    environment:
      JAVA_OPTS: "-Xms512m -Xmx2g -Djava.security.egd=file:/dev/./urandom"
    restart: unless-stopped

  cruise-control-ui:
    image: devopsiaci/cruise-control-ui:0.4.0
    container_name: cruise-control-ui
    ports:
      - "8080:80"
    volumes:
      - ./config.csv:/usr/share/nginx/html/static/config.csv:ro
    restart: unless-stopped
    depends_on:
      - cruise-control
```

## Nginx reverse proxy configuration

If you need to serve the UI under a specific path (e.g., `/cruise-control`), configure your reverse proxy:

### Nginx configuration

```nginx
location /cruise-control {
    # Rewrite path
    rewrite ^/cruise-control/(.*) /$1 break;

    # Proxy configuration
    proxy_pass http://cruise-control-ui:80;
    proxy_pass_request_headers on;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Rewrite static assets
    sub_filter /static/js          /cruise-control/static/js;
    sub_filter /static/css         /cruise-control/static/css;
    sub_filter /static/cc-logo.png /cruise-control/static/cc-logo.png;
    sub_filter /kafkacruisecontrol /cruise-control/kafkacruisecontrol;
    sub_filter_last_modified on;
    sub_filter_once off;
    sub_filter_types *;
}
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
