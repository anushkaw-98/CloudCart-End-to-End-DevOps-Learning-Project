# Architecture decisions

## Environment isolation
Each environment has its own resource group, VNet, AKS cluster and Terraform state key. CIDR ranges are non-overlapping. This is stronger isolation than namespaces in one shared cluster, but increases cost. For a learning budget, you may intentionally share Dev/Test cluster resources; document the trade-off and never treat namespaces as a hard security boundary.

## Image promotion
CI builds once and tags with the immutable Azure DevOps build ID. Deployments refer to that exact tag in each environment. For stronger supply-chain guarantees, capture and promote the image digest (`sha256:...`), sign images, generate SBOMs, and enforce admission policy.

## Terraform state
One state key per environment, protected by Azure Storage RBAC and backend locking. Keep state private; it can contain sensitive values. Bootstrap the storage account separately and protect it from routine destroy operations.

## Production changes
Production deployment is a deployment job targeting `cloudcart-prod`. Configure approvals and branch control in Azure DevOps Environment settings. Checks are managed outside YAML, so a code change cannot simply remove the production approval gate. Source: Microsoft Learn, Azure Pipelines environments and approvals.

## Identity
Use Workload Identity Federation rather than long-lived client secrets. Prefer separate service connections and least privilege for Dev/Test/Prod; production should not use a dev-scoped identity.
