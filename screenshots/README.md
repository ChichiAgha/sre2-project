# Screenshot Evidence Checklist

Store final screenshots in this directory during a live demo run.

Required evidence:

- `01-kubectl-pods-banking.png`: `kubectl get pods -n banking`
- `02-kubectl-services-banking.png`: `kubectl get svc -n banking`
- `03-kubectl-monitoring-resources.png`: `kubectl get servicemonitor,prometheusrule -n banking`
- `04-grafana-operations-overview.png`: Techbleat Bank - Operations Overview dashboard with live data
- `05-grafana-business-metrics.png`: Techbleat Bank - Business Metrics dashboard with live data
- `06-alert-firing.png`: one critical alert firing during a controlled test
- `07-alert-resolved.png`: the same critical alert resolved after remediation
- `08-ui-banking-flow.png`: UI evidence for create user, deposit, withdraw, transfer, balance/history/activity logs

For the controlled alert test, use a reversible action such as temporarily scaling `transaction-service` to zero, then scaling it back:

```bash
kubectl scale deploy/transaction-service -n banking --replicas=0
kubectl scale deploy/transaction-service -n banking --replicas=2
```
