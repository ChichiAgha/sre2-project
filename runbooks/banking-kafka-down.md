# BankingKafkaDown

## Impact

Transaction events may not be consumed by the activity service. Activity logs may lag or stop updating.

## Checks

```bash
kubectl get pods -n banking -l app.kubernetes.io/component=kafka
kubectl logs -n banking deploy/kafka --tail=200
kubectl get svc,endpoints -n banking kafka
kubectl logs -n banking deploy/kafka-exporter --tail=100
```

## Remediation

1. Confirm Kafka is `1/1 Running`.
2. Check listener and KRaft configuration in `kafka-config`.
3. Confirm exporter can reach `kafka:29092`.
4. Restart Kafka only if configuration is correct and the pod is stuck:

```bash
kubectl rollout restart deployment/kafka -n banking
```

## Verification

```promql
up{namespace="banking",service="kafka-exporter"}
techbleat:kafka_consumer_lag
```
