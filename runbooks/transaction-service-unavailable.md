# TransactionServiceUnavailable

## Impact

Deposits, withdrawals, transfers, balances, and transaction history may be unavailable.

## Checks

```bash
kubectl get pods -n banking -l app.kubernetes.io/component=transaction-service
kubectl logs -n banking deploy/transaction-service --tail=200
kubectl describe deploy -n banking transaction-service
kubectl get endpoints -n banking transaction-service
```

## Remediation

1. Confirm Postgres, Redis, and Kafka are running.
2. Check transaction-service environment values from ConfigMaps and Secrets.
3. Confirm `/health` and `/actuator/prometheus` respond through port-forwarding.

```bash
kubectl port-forward -n banking svc/transaction-service 8080:8080
curl http://localhost:8080/health
curl http://localhost:8080/actuator/prometheus
```

4. Roll back the image or Helm release if the new version is unhealthy.

## Verification

Run a deposit/withdraw/transfer smoke test and confirm `banking_transactions_total` increases in Prometheus.
