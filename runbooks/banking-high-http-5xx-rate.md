# BankingHighHttp5xxRate

## Impact

Users are receiving server errors from one or more backend services.

## Checks

```bash
kubectl logs -n banking deploy/user-service --tail=200
kubectl logs -n banking deploy/transaction-service --tail=200
kubectl logs -n banking deploy/activity-service --tail=200
kubectl get pods -n banking
```

## Remediation

1. Identify which service label is producing the 5xx rate.
2. Check that service logs for stack traces or dependency errors.
3. Confirm Postgres, Redis, and Kafka are healthy.
4. Roll back if errors began after a deployment.

## Verification

```promql
techbleat:http_5xx_rate_per_second
```

The affected service should return to zero.
