# Techbleat Global Bank - DevOps Deployment

Techbleat Global Bank is a microservices banking platform deployed on AWS EKS with Docker, Kubernetes, Helm, Prometheus, Grafana, Alertmanager, Loki, Tempo, and Slack notifications.

The application includes:

- Frontend: React/Vite served by Nginx
- User Service: FastAPI, PostgreSQL-backed user/account creation
- Transaction Service: Spring Boot, PostgreSQL/Redis/Kafka-backed transactions
- Activity Service: FastAPI Kafka consumer for activity logs
- Infrastructure: PostgreSQL, Redis, Kafka
- Observability: Prometheus, Grafana, Alertmanager, ServiceMonitors, exporters, PrometheusRules, Loki/Promtail, Tempo/OpenTelemetry

## Repository Deliverables

| Requirement | Location |
|---|---|
| Kubernetes manifests / Helm chart | `charts/techbleat-bank/` |
| Container images with versioned tags | Public ECR image URLs below |
| Grafana Operations dashboard JSON | `dashboards/operations-overview.json` |
| Grafana Business Metrics dashboard JSON | `dashboards/business-metrics.json` |
| Prometheus alert definitions | `alerts/critical-alerts.yaml`, `charts/techbleat-bank/templates/critical-alerts.yaml` |
| Critical alert runbooks | `runbooks/` |
| Screenshot/evidence | `screenshots/`, `evidence/` |
| Deployment documentation | This README |
| Demo video | Add link below |

Demo video:

```text
TODO: add 3-5 minute demo video link
```

## Container Images

Application images are published to Public ECR:

```text
public.ecr.aws/k6r5h9u0/techbleat-global-bank-frontend:v2.0.2
public.ecr.aws/k6r5h9u0/techbleat-global-bank-user-service:v2.0.2
public.ecr.aws/k6r5h9u0/techbleat-global-bank-transaction-service:v2.0.3
public.ecr.aws/k6r5h9u0/techbleat-global-bank-activity-service:v2.0.2
```

Infrastructure images are pulled from public registries:

```text
postgres:15
redis:7
confluentinc/cp-kafka:8.1.1
prometheuscommunity/postgres-exporter:v0.15.0
oliver006/redis_exporter:v1.62.0
danielqsj/kafka-exporter:v1.7.0
```

## Level 1 - Local Docker Compose Validation

The application was first validated locally with Docker Compose to understand service communication before Kubernetes translation.

Backend stack:

```bash
cd techbleat-global-bank-backend
docker compose up --build
```

Health checks:

```bash
curl http://localhost:8000/health
curl http://localhost:8080/health
curl http://localhost:8001/health
```

Validated flow:

- create users
- deposit
- withdraw
- transfer
- check balance
- check transaction history
- check activity logs

Service dependencies:

```text
frontend -> user-service, transaction-service, activity-service
user-service -> PostgreSQL
transaction-service -> PostgreSQL, Redis, Kafka
activity-service -> PostgreSQL, Kafka
```

## Level 2 - Containerisation And Image Hygiene

Initial images were built and pushed as `v1.1.0`. Cleaner Kubernetes-ready images were later built as `v1.2.1` and observability-enabled services as `v1.3.0`.

Hygiene work completed:

- `.dockerignore` files added for build contexts
- `.env.example` files used for documented configuration
- real `.env` files kept out of Git
- frontend runtime configuration added through `public/config.js`
- backend secrets/config externalised through Kubernetes Secrets and ConfigMaps
- Trivy image scanning added through GitHub Actions
- build-scan-push workflow added so CI builds images, scans them, and only pushes to Public ECR if the scan policy passes
- current scan evidence is stored under `security/trivy/`

## Level 3 - Kubernetes Deployment

The platform is deployed with Helm:

```text
charts/techbleat-bank/
```

Main chart contents:

```text
Chart.yaml
values.yaml
templates/
  frontend/
  user-service/
  transaction-service/
  activity-service/
  postgres/
  redis/
  kafka/
  critical-alerts.yaml
  prometheusrules.yaml
```

Install or upgrade:

```bash
helm upgrade --install techbleat-bank charts/techbleat-bank \
  --namespace banking \
  --create-namespace \
  --set namespace.create=false
```

Validate:

```bash
kubectl get pods -n banking
kubectl get svc -n banking
kubectl get hpa -n banking
kubectl get ingress -n banking
kubectl get servicemonitor,prometheusrule -n banking
```

Expected app state:

```text
frontend                 1/1 Running
user-service             1/1 Running
transaction-service      2/2 Running
activity-service         1/1 Running
postgres                 1/1 Running
redis                    1/1 Running
kafka                    1/1 Running
postgres-exporter        1/1 Running
redis-exporter           1/1 Running
kafka-exporter           1/1 Running
```

## Application Access

The EKS deployment has an NGINX Ingress Controller backed by an AWS load balancer.

Check the ingress address:

```bash
kubectl get ingress -n banking -o wide
```

Test through the load balancer with the expected host:

```bash
INGRESS=$(kubectl get ingress techbleat-bank -n banking -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -I -H "Host: bank.local" "http://$INGRESS/"
curl -H "Host: bank.local" "http://$INGRESS/api/users/health"
```

For browser testing without DNS, add a local hosts entry pointing `bank.local` to the ingress endpoint if your environment supports it, or keep using port-forward:

```bash
kubectl port-forward -n banking svc/frontend 3000:80
```

Open:

```text
http://localhost:3000
```

## Local Access

For local Minikube/WSL testing, port-forwarding was used:

```bash
kubectl port-forward -n banking svc/frontend 30080:80
kubectl port-forward -n banking svc/user-service 8000:8000
kubectl port-forward -n banking svc/transaction-service 8080:8080
kubectl port-forward -n banking svc/activity-service 8001:8001
```

Open:

```text
http://localhost:30080
```

For the default Ingress configuration:

```text
http://bank.local
```

In WSL/Minikube, direct Windows browser access to the Minikube Ingress IP may fail because of host networking. Port-forwarding was used for local UI evidence. The Ingress remains configured for Kubernetes environments where the host can route to the ingress controller.

## Observability

Prometheus/Grafana was installed with `kube-prometheus-stack`:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

Access Grafana:

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80
```

Open:

```text
http://localhost:3001
```

Get Grafana admin password:

```bash
kubectl --namespace monitoring get secret monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

## Metrics Instrumentation

Application metrics:

- User Service exposes `/metrics` using `prometheus-fastapi-instrumentator`
- Transaction Service exposes `/actuator/prometheus` using Spring Boot Actuator and Micrometer
- Transaction Service exposes custom business counter `banking_transactions_total{type=...}`

Exporter metrics:

- Redis exporter for cache metrics
- PostgreSQL exporter for database metrics
- Kafka exporter for consumer lag and broker metrics

Service discovery:

```bash
kubectl get servicemonitor -n banking
```

Custom recording rules:

```bash
kubectl get prometheusrule techbleat-bank-custom-rules -n banking
```

PromQL rules implemented:

- `techbleat:transaction_rate_per_second`
- `techbleat:http_5xx_rate_per_second`
- `techbleat:http_request_latency_p95_seconds`
- `techbleat:http_request_latency_p99_seconds`
- `techbleat:kafka_consumer_lag`
- `techbleat:redis_cache_hit_rate`
- `techbleat:postgres_active_connections`
- `techbleat:postgres_max_query_duration_seconds`

## Grafana Dashboards

Dashboard exports are stored in:

```text
dashboards/operations-overview.json
dashboards/business-metrics.json
```

Import in Grafana:

```text
Dashboards -> New -> Import -> Upload dashboard JSON file
```

Dashboards:

- `Techbleat Bank - Operations Overview`
- `Techbleat Bank - Business Metrics`

## Alerts

Critical alert definitions are stored in:

```text
alerts/critical-alerts.yaml
charts/techbleat-bank/templates/critical-alerts.yaml
```

Deployed rules:

```bash
kubectl get prometheusrule techbleat-bank-critical-alerts -n banking
```

Critical alerts:

- `BankingPodCrashLooping`
- `BankingDeploymentReplicasUnavailable`
- `TransactionServiceUnavailable`
- `BankingKafkaDown`
- `BankingPostgresDown`
- `BankingHighKafkaConsumerLag`
- `BankingHighHttp5xxRate`

## Slack Alert Notifications

Slack receiver config is stored in:

```text
alerts/slack-alertmanagerconfig.yaml
alerts/slack-notification-setup.md
```

The Slack webhook must be stored as a Kubernetes Secret and must not be committed to Git:

```bash
kubectl create secret generic alertmanager-slack-webhook \
  -n banking \
  --from-literal=url='<slack-webhook-url>'
```

Apply Slack routing:

```bash
kubectl apply -f alerts/slack-alertmanagerconfig.yaml
```

Controlled alert test used:

```bash
kubectl scale deploy/kafka-exporter -n banking --replicas=0
```

Resolution:

```bash
kubectl scale deploy/kafka-exporter -n banking --replicas=1
kubectl rollout status deploy/kafka-exporter -n banking
```

## Runbooks

Critical alert runbooks are stored under:

```text
runbooks/
```

Each runbook includes impact, checks, remediation, and verification steps.

## Screenshot Evidence

Screenshot checklist:

```text
screenshots/README.md
```

Command/API evidence collected from the live EKS cluster is stored in:

```text
evidence/
```

This includes Kubernetes pod/service/HPA state, ingress HTTP checks, Prometheus target/rule data, Loki query output, and Tempo trace search output. Browser screenshots and the demo video still need to be captured from a graphical browser/recorder.

## CI/CD And Security Gates

GitHub Actions workflows:

```text
.github/workflows/build-scan-push.yml
.github/workflows/image-scan.yml
.github/workflows/terraform-ci.yml
```

`build-scan-push.yml` is the enterprise promotion path:

```text
build image from source
scan local image with Trivy
push to Public ECR only if the Trivy policy passes
```

Required GitHub secret:

```text
AWS_GITHUB_ACTIONS_ROLE_ARN
```

That role must allow GitHub Actions OIDC to push to Public ECR.

`image-scan.yml` audits already deployed Public ECR images and uploads Trivy table/SARIF reports.

`terraform-ci.yml` runs:

```text
terraform fmt -check
terraform init -backend=false
terraform validate
checkov Terraform security scan
```

Expected screenshots:

- Kubernetes pods running
- Kubernetes services
- ServiceMonitors and PrometheusRules
- Grafana Operations dashboard
- Grafana Business Metrics dashboard
- alert firing
- alert resolved
- UI banking flow

## Security Notes

- Application config is externalised through ConfigMaps.
- Sensitive database values are stored in Kubernetes Secrets.
- Slack webhook is stored in a Kubernetes Secret and excluded from Git.
- Images use versioned tags.
- Trivy scanning is enforced through GitHub Actions before image push.
- PostgreSQL data uses a PVC in Kubernetes.

## Known Limitations

- DNS/TLS for a real production domain is not configured yet; current EKS ingress works over HTTP using the AWS load balancer and `Host: bank.local`.
- The in-cluster Kafka deployment is single-node and suitable for assignment/demo use, not production HA.
- In-cluster PostgreSQL is suitable for assignment/demo use; production AWS deployments should consider Amazon RDS.
- Slack webhook must be rotated if exposed.
- Current Trivy evidence includes findings that should be remediated before promoting new images through the build-scan-push gate.

## Useful Commands

```bash
helm lint charts/techbleat-bank
helm template techbleat-bank charts/techbleat-bank --namespace banking
kubectl get pods -n banking
kubectl get pods -n monitoring
kubectl get servicemonitor,prometheusrule -n banking
```

Prometheus port-forward:

```bash
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Alertmanager port-forward:

```bash
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093
```

Grafana port-forward:

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80
```
