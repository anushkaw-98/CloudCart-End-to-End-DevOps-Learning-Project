# Azure DevOps setup checklist

## Repositories
- Protect `main`: PR required, reviewer required, build validation required, prohibit direct pushes, require resolved comments.
- Keep feature branches short-lived; use `feature/*`, `bugfix/*`, and `hotfix/*`.
- No secrets in repo or pipeline YAML.

## Pipelines
Create pipelines from:
1. `azure-pipelines-pr.yml` for PR validation.
2. `azure-pipelines-ci-cd.yml` for application CI/CD.
3. `azure-pipelines-infra.yml` for Terraform infrastructure.

Set `TF_VAR_acr_name` as a pipeline variable (not secret; ACR name is not a credential). Authorize each pipeline only for the service connections it requires.

## Environments
Create:
- `cloudcart-dev`
- `cloudcart-test`
- `cloudcart-prod`
- `cloudcart-infra-dev`
- `cloudcart-infra-test`
- `cloudcart-infra-prod`

On `cloudcart-prod` and `cloudcart-infra-prod`, add Approvals and Checks:
- Approval by a designated operator/release manager.
- Branch control: `refs/heads/main`, require protected branch.
- Optional exclusive lock to prevent overlapping prod releases.
- Restrict pipeline permissions to the intended release pipeline.

Consider approvals on Test or infra changes as required by your team. Never rely on a YAML `condition` alone as the production approval boundary.

## WIF and permissions
For each environment, create a separate Azure Resource Manager service connection using Workload Identity Federation. Scope permissions to the appropriate resource group/subscription. Assign only required roles:
- Terraform: resources it must manage; state storage `Storage Blob Data Contributor`.
- Build identity: `AcrPush` on ACR.
- Deploy identity: AKS cluster access with appropriate Azure RBAC/Kubernetes permissions.
- AKS kubelet identity: `AcrPull` on ACR.

Avoid broad Owner/Contributor at subscription scope unless explicitly justified. Exact roles depend on whether AKS Azure RBAC is enabled and how Terraform creates resources.
