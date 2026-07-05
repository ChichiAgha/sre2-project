# BankingHighKafkaConsumerLag

## Impact

Activity logs may be delayed because the activity service is not consuming transaction events quickly enough.

## Checks

```bash
kubectl logs -n banking deploy/activity-service --tail=200
kubectl logs -n banking deploy/kafka-exporter --tail=100
kubectl get pods -n banking -l app.kubernetes.io/component=activity-service
```

## Remediation

1. Confirm activity-service is healthy.
2. Check whether the Kafka topic is receiving a sudden burst of traffic.
3. Confirm Postgres is healthy because activity-service writes consumed events to Postgres.
4. Scale activity-service if the consumer implementation supports safe parallel consumption.

## Verification

```promql
techbleat:kafka_consumer_lag
```

The value should return toward zero.
