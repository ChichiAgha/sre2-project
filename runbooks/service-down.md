# ServiceDown

## Impact

Prometheus cannot scrape one or more banking targets. The application may still be serving traffic, but monitoring visibility is broken or the target service is down.

## Checks

```bash
kubectl get servicemonitor,prometheusrule -n banking
kubectl get pods,svc,endpoints -n banking
kubectl get pods -n monitoring
```

In Prometheus, identify the failed target:

```promql
up{namespace="banking"} == 0
```

## Remediation

1. If the pod is not running, check `kubectl describe pod` and container logs for image, probe, dependency, or scheduling errors.
2. If the pod is running but the target is down, confirm the Service selector matches the pod labels and the ServiceMonitor points to the correct port and path.
3. If all banking pods are healthy, check Prometheus Operator and Prometheus pods in the `monitoring` namespace.

## Verification

```promql
up{namespace="banking"}
```

All expected banking scrape targets should return `1`.
