# BankingPodCrashLooping

## Impact

A banking platform container is repeatedly restarting. Users may see partial or complete service failure depending on the pod.

## Checks

```bash
kubectl get pods -n banking
kubectl describe pod -n banking <pod-name>
kubectl logs -n banking <pod-name> --previous
kubectl get events -n banking --sort-by=.lastTimestamp
```

## Remediation

1. Identify the failing pod and container.
2. Check the previous logs for startup errors, missing environment variables, database errors, Kafka errors, or image pull problems.
3. Confirm required dependencies are healthy:

```bash
kubectl get pods -n banking
kubectl get svc -n banking
kubectl logs -n banking deploy/kafka --tail=100
kubectl logs -n banking statefulset/postgres --tail=100
```

4. If a bad rollout caused the issue, roll back:

```bash
helm rollback techbleat-bank -n banking
```

## Verification

```bash
kubectl get pods -n banking
kubectl rollout status deployment/<deployment-name> -n banking
```
