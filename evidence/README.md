# Evidence Index

This directory contains command/API evidence collected from the live EKS deployment.

Files:

- `01-banking-pods.txt`: application and dependency pods running in `banking`.
- `02-banking-services.txt`: ClusterIP services for internal communication.
- `03-banking-hpa.txt`: HPA state with live CPU metrics.
- `04-banking-ingress.txt`: `bank.local` Ingress with AWS load balancer address.
- `05-monitoring-pods.txt`: Prometheus, Grafana, Alertmanager, Loki, Promtail, Tempo, and exporters running in `monitoring`.
- `06-monitoring-crds.txt`: ServiceMonitor and PrometheusRule objects in `banking`.
- `07-prometheus-banking-up.json`: Prometheus `up{namespace="banking"}` query result.
- `08-prometheus-required-alerts.json`: required capstone alert rules loaded in Prometheus.
- `09-loki-banking-logs.json`: Loki query result for `banking` namespace logs.
- `10-tempo-transaction-traces.json`: Tempo search result for `transaction-service` traces.
- `11-ingress-hostname.txt`: AWS load balancer hostname for the banking Ingress.
- `12-ingress-frontend-http.txt`: HTTP `200` frontend response through the Ingress.
- `13-ingress-user-health.txt`: `/api/users/health` response through the Ingress.

Browser screenshots and demo video should still be captured separately from a graphical environment.
