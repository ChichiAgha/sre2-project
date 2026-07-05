# BankingPostgresDown

## Impact

User creation, account balance, transaction history, and activity queries may fail.

## Checks

```bash
kubectl get pods -n banking -l app.kubernetes.io/component=postgres
kubectl logs -n banking statefulset/postgres --tail=200
kubectl get pvc -n banking
kubectl logs -n banking deploy/postgres-exporter --tail=100
```

## Remediation

1. Confirm the Postgres pod is running and the PVC is bound.
2. Check credentials in `postgres-secret`.
3. Check database readiness:

```bash
kubectl exec -n banking postgres-0 -- pg_isready
```

4. If storage is full or corrupted, preserve evidence before deleting or recreating PVCs.

## Verification

```promql
pg_up{namespace="banking"}
techbleat:postgres_active_connections
```
