# Techbleat Global Bank: Level 1 and Level 2 DevOps Progress

This document records the DevOps work completed before moving to Kubernetes. The goal was to first prove the application works locally, then prepare clean, versioned, configurable, and scanned container images that can be used in the Kubernetes phase.

## Level 1: Local App Validation

### Goal

Prove that the existing application works locally and understand how the services communicate before translating anything to Kubernetes.

### Why This Was Done

The assignment guidance says to start with a working local Docker Compose setup. This matters because Kubernetes deployment should not be attempted until the service dependencies and runtime behaviour are understood.

### What Was Validated

The backend stack was run with Docker Compose from:

```bash
cd techbleat-global-bank-backend
docker compose up --build
```

The Compose stack includes:

- PostgreSQL
- Redis
- Kafka
- user-service
- transaction-service
- activity-service

The frontend was also containerised and tested locally.

### Health Checks

The backend services expose health endpoints:

```bash
curl http://localhost:8000/health
curl http://localhost:8080/health
curl http://localhost:8001/health
```

Expected result:

```json
{"status":"ok"}
```

### Backend Smoke Test

The backend was tested programmatically with API calls before relying on the UI. The tested flow was:

- create two users
- deposit into the first user
- withdraw from the first user
- transfer from the first user to the second user
- check balances
- check transaction history
- check activity logs

This confirmed that PostgreSQL, Redis, Kafka, and the application services were communicating correctly.

### Service Dependency Map

- frontend calls user-service, transaction-service, and activity-service over HTTP
- user-service writes users and accounts to PostgreSQL
- transaction-service uses PostgreSQL for balances/transactions, Redis for balance caching, and Kafka for transaction events
- activity-service consumes Kafka transaction events and writes activity records to PostgreSQL

### Level 1 Result

Level 1 is complete. The app was proven to work locally before Kubernetes work began.

## Level 2A: Baseline Containerisation and Local Hygiene

### Goal

Create baseline app images, push them to Docker Hub, and clean up local build contexts.

### Initial Image Build and Push

The first pushed image set used tag `v1.1.0`:

```text
chigoldd/techbleat-frontend:v1.1.0
chigoldd/techbleat-user-service:v1.1.0
chigoldd/techbleat-transaction-service:v1.1.0
chigoldd/techbleat-activity-service:v1.1.0
```

This confirmed that all four application components could be built, tagged, and pushed to Docker Hub.

Infrastructure images such as PostgreSQL, Redis, and Kafka were not pushed because they already exist as upstream/vendor images:

- `postgres:15`
- `redis:7`
- `confluentinc/cp-kafka:8.1.1`

Only application-owned images were pushed.

### Docker Ignore Files

`.dockerignore` files were added so Docker builds do not send unnecessary or sensitive files into build contexts.

Examples of ignored content include:

- `node_modules`
- `dist`
- `.env`
- Python bytecode/cache files
- virtual environments
- Maven `target`
- logs and local cache artifacts

This improves build speed, reduces image risk, and keeps images cleaner.

### Environment Files

Environment handling was separated into templates and local runtime values:

- `.env.example` documents required variables and uses placeholders
- `.env` contains local values and should not be committed

This pattern was used because the final Kubernetes deployment will split runtime values into:

- ConfigMaps for non-sensitive configuration
- Secrets for passwords and credentials

### Git Ignore Hygiene

Git ignore rules were used so local files such as `.env`, `node_modules`, and build artifacts are not committed, while `.env.example` remains commit-safe documentation.

### Level 2A Result

Level 2A is complete. Baseline images were pushed and local container hygiene was added.

## Level 2B: Kubernetes-Ready Image Configuration

### Goal

Make the frontend image configurable for Kubernetes without relying only on hard-coded localhost API URLs.

### Problem Found

The frontend originally hard-coded backend URLs in `src/App.jsx`:

```js
const USER_API = "http://localhost:8000";
const TX_API = "http://localhost:8080";
const ACTIVITY_API = "http://localhost:8001";
```

This works locally, but it is not suitable for Kubernetes. In a browser, `localhost` means the user's own machine, not the Kubernetes cluster.

### Options Considered

Build-time Vite variables were considered:

```js
import.meta.env.VITE_USER_API_URL
```

This is better than hard-coding, but Vite values are baked into the static frontend at build time. That means a new image is needed for each environment.

The preferred approach was runtime config using:

```js
window.__APP_CONFIG__
```

This lets one frontend image be reused across environments. Kubernetes can later mount a ConfigMap over `config.js` without rebuilding the image.

### Final Frontend Config Approach

The frontend now supports a fallback chain:

1. runtime config from `window.__APP_CONFIG__`
2. Vite env values
3. localhost fallback for local development

This keeps developer/local behaviour working while enabling Kubernetes runtime configuration.

The runtime config file pattern is:

```js
window.__APP_CONFIG__ = {
  USER_API_URL: "http://localhost:8000",
  TX_API_URL: "http://localhost:8080",
  ACTIVITY_API_URL: "http://localhost:8001"
};
```

In Kubernetes, this file can be replaced by a ConfigMap mounted to:

```text
/usr/share/nginx/html/config.js
```

### Configurable Image Set

After this cleanup, images were rebuilt and pushed as `v1.2.0`:

```text
chigoldd/techbleat-frontend:v1.2.0
chigoldd/techbleat-user-service:v1.2.0
chigoldd/techbleat-transaction-service:v1.2.0
chigoldd/techbleat-activity-service:v1.2.0
```

### Level 2B Result

Level 2B is complete. The images became more Kubernetes-ready, especially the frontend image.

## Level 2C: CI Pipeline Image Security Scanning

### Goal

Move image vulnerability scanning into CI rather than relying only on manual local scans.

### Why This Was Done

A production-grade image workflow should scan images automatically. Manual scanning is useful for learning, but CI scanning is better because every pushed image can be checked consistently.

### GitHub Actions Workflow

A GitHub Actions workflow was added:

```text
.github/workflows/image-scan.yml
```

The workflow uses Trivy to scan the Docker Hub images.

It supports:

- manual runs through `workflow_dispatch`
- push-triggered runs
- image tag input/default
- matrix scanning for all four app images
- report uploads as GitHub Actions artifacts
- failing the workflow on Critical vulnerabilities

### Images Scanned

The pipeline scans:

```text
chigoldd/techbleat-frontend
chigoldd/techbleat-user-service
chigoldd/techbleat-transaction-service
chigoldd/techbleat-activity-service
```

### Evidence

The workflow uploads Trivy reports as artifacts. These reports can be downloaded from:

```text
GitHub Actions -> Image Security Scan -> workflow run -> Artifacts
```

This provides evidence for the assignment and for Level 2 documentation.

### Level 2C Result

Level 2C is complete. Trivy scanning is now automated through GitHub Actions.

## Level 2D: Vulnerability Remediation

### Goal

Fix or document image scan findings.

### Findings

Trivy found Critical vulnerabilities in:

- frontend image
- transaction-service image

The frontend issue was related to Alpine/OpenSSL packages:

- `libcrypto3`
- `libssl3`

The transaction-service issue was related to embedded Tomcat:

- `org.apache.tomcat.embed:tomcat-embed-core`

### Frontend Remediation

The frontend runtime image was updated to a newer NGINX Alpine image and Alpine packages were upgraded during the image build:

```dockerfile
FROM nginx:1.29-alpine

RUN apk upgrade --no-cache
```

This ensures vulnerable Alpine packages such as OpenSSL libraries are updated during the image build.

### Transaction-Service Remediation

The Spring Boot transaction service was updated to use a patched embedded Tomcat version by adding:

```xml
<tomcat.version>10.1.55</tomcat.version>
```

The transaction-service image was rebuilt with no cache to ensure the patched dependency was actually included in the image.

### Patched Image Set

The remediated image set uses tag `v1.2.1`:

```text
chigoldd/techbleat-frontend:v1.2.1
chigoldd/techbleat-user-service:v1.2.1
chigoldd/techbleat-transaction-service:v1.2.1
chigoldd/techbleat-activity-service:v1.2.1
```

The unchanged backend services were also tagged as `v1.2.1` so the pipeline could scan one consistent image set.

### Level 2D Result

Level 2D is complete. The images were scanned, findings were remediated, and the corrected `v1.2.1` image set was produced.

## Current Image URLs

Use these images for the next Kubernetes phase:

```text
docker.io/chigoldd/techbleat-frontend:v1.2.1
docker.io/chigoldd/techbleat-user-service:v1.2.1
docker.io/chigoldd/techbleat-transaction-service:v1.2.1
docker.io/chigoldd/techbleat-activity-service:v1.2.1
```

## Kubernetes Readiness Summary

The work completed in Levels 1 and 2 prepares the app for Kubernetes by ensuring:

- the app works locally before Kubernetes translation
- app images are pushed to Docker Hub with versioned tags
- build contexts are cleaner through `.dockerignore`
- local secrets/config are not baked into images
- required env vars are documented
- the frontend can use Kubernetes runtime config via `config.js`
- image security scanning is automated in GitHub Actions
- Critical vulnerabilities found during scanning were remediated

## Remaining Work

The next phase is Level 3:

- create Kubernetes manifests or a Helm chart
- deploy PostgreSQL, Redis, and Kafka first
- add ConfigMaps and Secrets
- deploy application services
- configure Ingress and CORS
- add probes, PVCs, labels, and HPA
- add Prometheus/Grafana observability
- add alerts, runbooks, screenshots, and final README/demo evidence
