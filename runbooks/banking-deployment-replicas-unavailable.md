# BankingDeploymentReplicasUnavailable

## Impact

A deployment has fewer available replicas than requested. The service may have reduced capacity or be unavailable.

## Checks

```bash
kubectl get deploy -n banking
kubectl describe deploy -n banking <deployment-name>
kubectl get pods -n banking -l app.kubernetes.io/component=<component>
```

## Remediation

1. Check pod status for image pull, readiness probe, or dependency failures.
2. Check service-specific logs:

```bash
kubectl logs -n banking deploy/<deployment-name> --tail=100
```

3. Confirm dependencies are ready:

```bash
kubectl get pods -n banking
kubectl get endpoints -n banking
```

4. Roll back if the issue started after a Helm upgrade:

```bash
helm history techbleat-bank -n banking
helm rollback techbleat-bank -n banking <revision>
```

## Verification

```bash
kubectl rollout status deployment/<deployment-name> -n banking
```
