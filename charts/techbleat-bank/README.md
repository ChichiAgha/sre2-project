# Techbleat Bank Helm Chart

This chart deploys the Techbleat Global Bank stack for the Kubernetes phase of the capstone.

## Components

- frontend
- user-service
- transaction-service
- activity-service
- PostgreSQL
- Redis
- Kafka

## Install

```bash
helm upgrade --install techbleat-bank ./charts/techbleat-bank \
  --namespace banking \
  --create-namespace
```

## Validate Rendered Manifests

```bash
helm lint ./charts/techbleat-bank
helm template techbleat-bank ./charts/techbleat-bank --namespace banking
```

## Default Image Set

```text
chigoldd/techbleat-frontend:v1.2.1
chigoldd/techbleat-user-service:v1.2.1
chigoldd/techbleat-transaction-service:v1.2.1
chigoldd/techbleat-activity-service:v1.2.1
```

## Runtime Config

Backend configuration is supplied with ConfigMaps and Secrets.

The frontend runtime API config is mounted as:

```text
/usr/share/nginx/html/config.js
```

This allows Kubernetes to change frontend API URLs without rebuilding the frontend image.

## Autoscaling

The chart enables conservative HPAs for the stateless services:

- frontend: 1-2 pods
- user-service: 1-2 pods
- transaction-service: 2-3 pods
- activity-service: 1-2 pods

Scale-up and scale-down are limited to one pod at a time to avoid cost spikes. PostgreSQL, Redis, and Kafka are intentionally not managed by HPA because stateful services need storage-aware and cluster-aware scaling.

## Local Ingress Host

The default host is:

```text
bank.local
```

For local clusters, add this to `/etc/hosts`:

```text
127.0.0.1 bank.local
```
