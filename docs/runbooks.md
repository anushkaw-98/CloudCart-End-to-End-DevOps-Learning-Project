# Operations runbooks

## Check rollout
```bash
kubectl rollout status deployment/cloudcart-api -n cloudcart
kubectl get pods -n cloudcart -o wide
kubectl describe deployment cloudcart-api -n cloudcart
kubectl logs deployment/cloudcart-api -n cloudcart --tail=100
```

## Roll back application deployment
```bash
kubectl rollout history deployment/cloudcart-api -n cloudcart
kubectl rollout undo deployment/cloudcart-api -n cloudcart
kubectl rollout status deployment/cloudcart-api -n cloudcart
```
Prefer redeploying the previously approved immutable image through the pipeline so the release remains traceable.

## Check resource pressure
```bash
kubectl top pods -n cloudcart
kubectl top nodes
kubectl get events -n cloudcart --sort-by=.metadata.creationTimestamp
```
`kubectl top` requires metrics-server; Azure Monitor managed Prometheus is a separate metrics path.

## Terraform drift/change
```bash
terraform plan
terraform show
```
Never delete a state file to resolve drift. Reconcile/import resources and inspect any proposed replacement before applying.
