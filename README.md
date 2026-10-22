# CloudCart — Industry-style Azure DevOps platform

A production-oriented learning repository for a small containerized API on Azure. It demonstrates environment isolation, Terraform modules and remote state, pull-request validation, CI, immutable image promotion, environment deployment jobs, approvals, security checks, and operational runbooks.

> **Important:** This is a reference implementation, not a claim that every cloud resource is already deployed or that it has been independently tested in your subscription. Reconcile it with your existing `rg-cloudcart-dev`, `aks-cloudcart-dev`, ACR, VNet, and Terraform state before applying anything. Never apply a plan that proposes unexpected replacements or deletions.

## Architecture choices

- **Dev/Test/Prod are separate deployment environments** with separate resource groups, VNets, AKS clusters, namespaces, and Terraform state keys.
- One shared ACR stores immutable build IDs. For stricter production separation, use a separate production subscription/registry and replicate approved images.
- One image is built and scanned in CI, then the same tag/digest is promoted to Dev → Test → Prod.
- Terraform code is reused through modules; environment folders only supply settings.
- Azure DevOps Environments record deployment history and provide approval/check gates. Configure production approvals in the Azure DevOps UI; YAML alone is not a security boundary.
- Azure DevOps authenticates to Azure through Workload Identity Federation (no client secret).
- Key Vault integration, private AKS API, network policy, Front Door/WAF, database, and formal DR are later hardening tasks, not silently assumed to exist.

## Folder structure

```text
cloudcart/
├── app/                         # Flask API + unit tests
├── infra/
│   ├── bootstrap/               # Instructions for separately managed state storage
│   ├── modules/
│   │   ├── network/
│   │   ├── acr/
│   │   └── aks/
│   └── environments/
│       ├── dev/
│       ├── test/
│       └── prod/
├── k8s/base/                    # Namespace, Deployment, Service
├── pipelines/templates/         # Reusable pipeline steps
├── scripts/                     # Smoke test helper
├── azure-pipelines-pr.yml       # PR validation
├── azure-pipelines-ci-cd.yml    # Build once, promote across environments
├── azure-pipelines-infra.yml    # Terraform plan/apply per environment
├── Dockerfile
└── docs/                        # Architecture, security, runbooks
```

## Existing CloudCart resource mapping

| Environment | Resource group | AKS | Terraform state key |
|---|---|---|---|
| Dev | `rg-cloudcart-dev` | `aks-cloudcart-dev` | `cloudcart-dev.tfstate` |
| Test | `rg-cloudcart-test` | `aks-cloudcart-test` | `cloudcart-test.tfstate` |
| Prod | `rg-cloudcart-prod` | `aks-cloudcart-prod` | `cloudcart-prod.tfstate` |

The Dev values reflect the project progress described so far. Test and Prod are proposed names, not existing resources.

## Before using the pipelines

1. Set the real existing Terraform backend storage account name in each environment's `backend.tf`.
2. Set pipeline variable `TF_VAR_acr_name` to the existing globally unique ACR name (without `.azurecr.io`). Do not put secrets in YAML.
3. Confirm service connection `sc-cloudcart-dev-wif` is authorized. For real separation, create separate WIF service connections for dev, test, and prod, each with least-privilege scope.
4. Create Azure DevOps Environments: `cloudcart-dev`, `cloudcart-test`, `cloudcart-prod`, and `cloudcart-infra-dev`, `cloudcart-infra-test`, `cloudcart-infra-prod`.
5. Configure **Approvals and checks in the UI** on `cloudcart-prod` and `cloudcart-infra-prod`: designated approvers, branch control (`refs/heads/main`), and optionally an exclusive lock. Restrict pipeline permissions.
6. Create branch policies on `main`: require PR, at least one reviewer, build validation, no direct pushes, and resolve comments.
7. For each environment, configure the correct Azure service connection and AKS cluster access. Pipeline identity needs ACR push rights; AKS deploy permissions; Terraform identity needs resource permissions and `Storage Blob Data Contributor` on the state storage.
8. Ensure the agents can reach the AKS API. If using private AKS, use a self-hosted agent in the VNet or an approved network path.
9. Run `terraform init`, `validate`, and `plan` per environment. Import/reconcile existing Dev resources before applying. Never share a state key between environments.

## Local app test

```bash
python -m pip install -r app/requirements.txt
python -m pytest -q
python -m flask --app app.app run --host 127.0.0.1 --port 8080
```

## Terraform workflow

Example (PowerShell, Dev):

```powershell
cd infra/environments/dev
$env:ARM_USE_AZUREAD = "true"
terraform init -reconfigure
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform show tfplan
```

Do not apply until you understand every change. For an existing resource group, VNet, ACR, and AKS cluster, the state/configuration must be reconciled. Import is not a substitute for matching the actual configuration.

## Pipeline behavior

- `azure-pipelines-pr.yml`: runs tests, Docker build, Terraform formatting/validation.
- `azure-pipelines-ci-cd.yml`: builds once on `main`, pushes image tagged by `Build.BuildId`, then deploys that same tag to Dev and Test. Prod is a separate stage with a protected Azure DevOps Environment.
- `azure-pipelines-infra.yml`: plan and apply infrastructure by environment. Production approvals must be configured on the environment in the UI.
- `pipelines/templates/`: shared templates to keep behavior consistent.

## Cost notes

Three always-on AKS clusters can be expensive: worker node VMs, disks, load balancers, public IPs, monitoring ingestion, and Log Analytics retention can all cost money. For a learning portfolio, use a single shared dev/test cluster only if you deliberately choose lower isolation, and scale/delete non-production resources when not in use. Do not create Prod until the pipeline and security model are reviewed.
