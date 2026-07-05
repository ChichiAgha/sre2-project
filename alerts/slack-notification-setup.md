# Slack Alert Notification Setup

The Slack webhook is a secret and must not be committed to Git.

Because the first webhook was pasted into chat, revoke it in Slack and generate a new incoming webhook for `#techbleat-alerts`.

## Create The Secret

Run this locally, replacing the placeholder with the new webhook URL:

```bash
kubectl create secret generic alertmanager-slack-webhook \
  -n banking \
  --from-literal=url='<new-slack-webhook-url>'
```

If the Secret already exists:

```bash
kubectl delete secret alertmanager-slack-webhook -n banking
kubectl create secret generic alertmanager-slack-webhook \
  -n banking \
  --from-literal=url='<new-slack-webhook-url>'
```

## Apply The AlertmanagerConfig

```bash
kubectl apply -f alerts/slack-alertmanagerconfig.yaml
```

## Test Notification

Trigger a reversible critical alert:

```bash
kubectl scale deploy/transaction-service -n banking --replicas=0
```

Wait for the alert to fire and confirm a Slack message arrives.

Resolve it:

```bash
kubectl scale deploy/transaction-service -n banking --replicas=2
kubectl rollout status deploy/transaction-service -n banking
```

Confirm Slack receives the resolved notification.
