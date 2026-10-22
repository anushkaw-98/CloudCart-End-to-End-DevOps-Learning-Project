# CloudCart — Terraform Infrastructure, State Management, and DevOps Pipeline Best Practices

## 1. Introduction

### 1.1 Purpose

This document explains how Terraform is used to provision and manage the CloudCart Azure infrastructure. It documents the infrastructure provisioning workflow, bootstrap resources, remote state configuration, development environment structure, Azure DevOps pipelines, security controls, and recommended Terraform practices.

The objective is to build an infrastructure workflow that is:

- Repeatable and version-controlled.
- Secure, with controlled access to infrastructure and state.
- Consistent across Dev, Test, and Production environments.
- Reviewable before infrastructure changes are applied.
- Automated through Azure DevOps Pipelines.
- Recoverable and maintainable as the platform grows.

### 1.2 Technology Stack

| Technology | Purpose |
|---|---|
| Microsoft Azure | Cloud infrastructure platform |
| Terraform | Infrastructure as Code (IaC) |
| Azure Storage Account | Remote Terraform state storage |
| Azure Blob Storage container | Stores Terraform state blobs |
| Azure DevOps Repos | Source control |
| Azure DevOps Pipelines | Infrastructure provisioning and application delivery |
| Azure Resource Manager (AzureRM) provider | Manages Azure resources through Terraform |
| Workload Identity Federation (WIF) | Enables pipeline authentication without long-lived client secrets |
| Azure Container Registry (ACR) | Stores application container images |
| Azure Kubernetes Service (AKS) | Hosts containerised workloads |

---

## 2. Terraform Architecture and Workflow

Terraform allows infrastructure to be defined declaratively in configuration files instead of being created manually through the Azure Portal.

The configuration describes the desired infrastructure. Terraform compares the configuration with its state and the actual resources to determine which changes are required.

### 2.1 Infrastructure provisioning workflow

The CloudCart infrastructure workflow follows these stages:

1. Define the required Azure resources using Terraform.
2. Validate and format the Terraform configuration.
3. Configure authentication to Azure.
4. Initialise the Terraform working directory.
5. Configure remote state storage.
6. Create the development environment configuration.
7. Generate and review a Terraform execution plan.
8. Apply approved infrastructure changes through Azure DevOps Pipelines.
9. Validate the deployed resources.
10. Commit reviewed configuration changes to Azure Repos.

### 2.2 Why Infrastructure as Code?

Terraform provides several advantages over manual infrastructure provisioning.

**Consistency:** The same reviewed configuration can be used to create equivalent environments.

**Version control:** Infrastructure changes can be reviewed through pull requests and tracked in Git history.

**Repeatability:** Infrastructure can be recreated from configuration, subject to the availability of dependencies and required configuration.

**Change visibility:** Terraform plans show proposed additions, modifications, and deletions before changes are applied.

**Automation:** Azure DevOps can validate and provision infrastructure using a controlled pipeline.

**Reduced configuration drift:** Regular review and planned Terraform runs help identify differences between the intended and actual infrastructure.

**Disaster recovery:** Infrastructure definitions can help rebuild resources in another region, although data, secrets, permissions, and external dependencies require separate recovery planning.

---

## 3. Bootstrap Terraform Infrastructure

### 3.1 What is Terraform bootstrap?

Bootstrap infrastructure contains the resources required to initialise and operate the main Terraform environments.

For CloudCart, the bootstrap layer creates the Azure Storage resources used to store Terraform state remotely.

The bootstrap layer must be created before the main Dev environment can use the remote state backend.

### 3.2 Why bootstrap is required

Terraform normally stores its state locally unless a remote backend is configured.

A local state file creates operational problems when multiple engineers or pipeline runs need to manage the same infrastructure.

Potential problems include:

- State files being lost with a developer's machine.
- State files being committed accidentally to Git.
- Engineers working with different copies of the state.
- Concurrent operations creating conflicting changes.
- Difficulties recovering state after a machine or workspace failure.

A remote Azure Blob Storage backend provides a shared state location and supports state locking and consistency mechanisms for safe Terraform operations.

### 3.3 Bootstrap resources

The CloudCart bootstrap layer uses the following resources:

| Resource | Purpose |
|---|---|
| Resource group: `rg-cloudcart-tfstate` | Groups the Terraform state storage resources |
| Azure Storage Account | Provides durable storage for Terraform state |
| Blob container: `tfstate` | Holds the Terraform state blobs |
| Azure RBAC assignments | Controls who and which identities can access the state |

The exact Storage Account name and resource configuration must be taken from the actual Azure environment and Terraform repository.

### 3.4 Example bootstrap directory

```text
infra/
└── bootstrap/
    ├── providers.tf
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tf
```

The precise filenames may differ in the existing repository. The important principle is to keep bootstrap configuration logically separate from the application infrastructure it supports.

### 3.5 Bootstrap provisioning sequence

1. Configure the AzureRM provider.
2. Define the bootstrap resource group.
3. Define the Storage Account.
4. Create the private `tfstate` blob container.
5. Apply the bootstrap configuration.
6. Verify that the Storage Account and container exist.
7. Configure the identities and RBAC permissions required to access the state.
8. Configure the main Terraform environment to use the remote backend.

The initial bootstrap operation can use a controlled local state file because the remote backend does not yet exist.

**Important:** Keep the initial bootstrap state safe. Do not commit it to Git. Store it in an approved secure location with restricted access. After the remote state backend is available, consider migrating the bootstrap state itself to a separate remote-state key. That migration must be planned carefully to avoid losing or duplicating state ownership.

### 3.6 Bootstrap security best practices

- Use a globally unique Storage Account name.
- Use an approved redundancy configuration based on recovery requirements and cost.
- Disable anonymous blob access.
- Require HTTPS for storage access.
- Use Microsoft Entra ID authentication rather than Storage Account keys where supported.
- Apply least-privilege RBAC.
- Restrict network access where practical without breaking the pipeline.
- Enable appropriate logging and monitoring.
- Protect the Storage Account and its state from accidental deletion.
- Do not store passwords, client secrets, access keys, or other credentials in Terraform outputs or source control.

Terraform state can contain sensitive information even when the corresponding variables are marked `sensitive`. Marking a value sensitive primarily controls how Terraform displays it; it does not automatically remove it from the state file.

---

## 4. Moving Terraform State to Azure Blob Storage

### 4.1 Why remote state is required

Terraform state maps the resources declared in Terraform configuration to real Azure resources.

For example, the state helps Terraform identify that a resource declared as `azurerm_virtual_network` corresponds to a particular Azure Virtual Network.

Without a shared state backend, engineers and pipelines could operate on inconsistent copies of this mapping.

CloudCart therefore uses Azure Blob Storage as its Terraform backend.

### 4.2 Backend configuration

The development environment uses a backend configuration conceptually similar to:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cloudcart-tfstate"
    storage_account_name = "<actual-storage-account-name>"
    container_name       = "tfstate"
    key                  = "cloudcart-dev.tfstate"
    use_azuread_auth     = true
  }
}
```

Replace the placeholder with the actual Storage Account name from the existing environment.

This example assumes the Terraform CLI and AzureRM backend versions support the specified authentication configuration.

The backend block does not create the Storage Account or container. Those resources must already exist.

### 4.3 Backend configuration explained

| Setting | Explanation |
|---|---|
| `resource_group_name` | Resource group containing the state Storage Account |
| `storage_account_name` | Existing Azure Storage Account name |
| `container_name` | Blob container that stores state |
| `key` | Name/path of the environment's state blob |
| `use_azuread_auth` | Uses Microsoft Entra ID authentication for backend access |

Backend configuration is processed during `terraform init`. Backend settings cannot be treated like ordinary Terraform input variables in the same way as resource configuration.

Avoid placing credentials directly inside backend configuration.

### 4.4 State migration

If a Terraform working directory already has local state, the migration workflow is:

1. Confirm that the current local state matches the infrastructure being managed.
2. Back up the local state securely.
3. Create the Storage Account and container.
4. Configure the AzureRM backend.
5. Run `terraform init -migrate-state`.
6. Review Terraform's migration prompts carefully.
7. Confirm that the state exists in the remote backend.
8. Run `terraform plan` and verify that Terraform does not unexpectedly propose recreating existing infrastructure.
9. Remove temporary local state copies only after confirming the migration and following the organisation's retention requirements.

Do not migrate state blindly or allow two independent state files to manage the same resources.

If the directory has never managed resources and has no state to migrate, initialise the remote backend normally.

### 4.5 State separation by environment

CloudCart uses a separate state key for each environment.

| Environment | Example state key |
|---|---|
| Dev | `cloudcart-dev.tfstate` |
| Test | `cloudcart-test.tfstate` |
| Production | `cloudcart-prod.tfstate` |
| Disaster recovery | `cloudcart-dr.tfstate` |

Separate state keys help isolate environment changes.

For stronger separation, use distinct Storage Accounts or containers and separate access permissions for sensitive environments when the operational and security requirements justify them.

**Never use one state key for multiple independently managed environments.**

### 4.6 State management best practices

- Treat state as sensitive infrastructure data.
- Use remote state instead of sharing local state files.
- Keep state access separate from ordinary application repository access.
- Use supported locking and consistency mechanisms.
- Avoid concurrent apply operations against the same state.
- Restrict who can read, modify, or delete state.
- Back up state according to the recovery policy.
- Test state recovery procedures.
- Avoid editing the state JSON manually.
- Use `terraform state` commands only when necessary and with a backup and reviewed procedure.
- Never delete a state blob simply to fix a failed pipeline.

---

## 5. Development Environment Terraform

### 5.1 Purpose

The Dev environment provides a controlled place to create and validate CloudCart infrastructure before changes are promoted to Test and Production.

The current Dev infrastructure was created using Terraform and includes the following resources.

| Resource | Current reported configuration |
|---|---|
| Resource group | `rg-cloudcart-dev` |
| Region | East US |
| Virtual Network | `vnet-cloudcart-dev` |
| VNet address range | `10.20.0.0/16` |
| AKS subnet | `snet-aks-dev`, `10.20.0.0/20` |
| Private endpoints subnet | `snet-private-endpoints-dev`, `10.20.16.0/24` |
| AKS cluster | `aks-cloudcart-dev` |
| Container Registry | ACR created through Terraform; verify its actual name and SKU |

These are the previously reported values. Confirm the current Azure resources and Terraform configuration before using them as authoritative deployment values.

### 5.2 Recommended environment directory

```text
infra/
├── bootstrap/
│   ├── providers.tf
│   ├── main.tf
│   └── outputs.tf
├── modules/
│   ├── network/
│   ├── acr/
│   └── aks/
└── environments/
    ├── dev/
    │   ├── backend.tf
    │   ├── providers.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars
    ├── test/
    ├── prod/
    └── dr/
```

This is a recommended logical structure. Reconcile it with the existing repository before moving files or changing Terraform state ownership.

### 5.3 What belongs in each file?

**`backend.tf`**

Defines the remote backend configuration for the environment.

**`providers.tf`**

Defines the required Terraform providers and AzureRM provider configuration.

**`main.tf`**

Connects reusable Terraform modules and defines environment-specific resource composition.

**`variables.tf`**

Declares input variables, their types, descriptions, validation rules, and safe defaults where appropriate.

**`outputs.tf`**

Exposes selected resource attributes needed by other workflows, operators, or deployment processes.

**`terraform.tfvars`**

Contains environment-specific non-secret input values, such as region, resource names, address ranges, and node-pool sizing.

Do not put credentials or secret values in `terraform.tfvars`.

### 5.4 Why use Terraform modules?

Modules allow common infrastructure patterns to be reused.

For example, the network module can define the Virtual Network and subnets, while the AKS module defines cluster configuration.

Benefits include:

- Less duplicated configuration.
- Consistent naming and tagging.
- Reusable security settings.
- Easier review and maintenance.
- A consistent foundation for Dev, Test, and Production.

Modules should expose meaningful inputs and outputs rather than hiding every setting behind complicated abstractions.

For a small learning project, a few clear modules are better than creating a module for every individual resource.

### 5.5 Environment-specific configuration

Dev, Test, and Production may share the same module definitions but use different values.

Examples include:

- Resource names and tags.
- Network address ranges.
- AKS node-pool size and scaling limits.
- SKU and redundancy settings.
- Monitoring and retention configuration.
- Data protection requirements.
- Access permissions.

Production should not simply inherit every Dev setting unchanged. Production requires deliberate availability, security, backup, capacity, and cost decisions.

---

## 6. Terraform Variables, Outputs, and Secrets

### 6.1 Variables

Use typed variables instead of hardcoding values throughout resource definitions.

Example:

```hcl
variable "location" {
  description = "Azure region for this environment"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod", "dr"], var.environment)
    error_message = "Environment must be dev, test, prod, or dr."
  }
}
```

Use variable validation for important constraints, and provide descriptions that explain the purpose of each variable.

### 6.2 Outputs

Outputs should expose only the attributes needed by users or downstream processes.

Example:

```hcl
output "resource_group_name" {
  description = "Name of the CloudCart environment resource group"
  value       = azurerm_resource_group.main.name
}
```

Avoid outputting passwords, access keys, connection strings containing credentials, or other secrets.

### 6.3 Secret handling strategy

CloudCart should avoid hardcoding secrets in:

- Terraform files.
- `.tfvars` files.
- Azure DevOps YAML.
- Application source code.
- Kubernetes manifests.
- Git commits.
- Container images.

Preferred options include:

1. **Workload Identity Federation:** Authenticate Azure DevOps to Azure without a long-lived client secret, where supported.
2. **Managed identities:** Allow Azure resources to authenticate to other supported Azure services without embedding credentials.
3. **Azure Key Vault:** Store and manage application secrets, certificates, and keys.
4. **Azure DevOps secret variables or variable groups:** Use only when a pipeline genuinely needs a secret that cannot be avoided. Restrict permissions and do not print secrets in logs.
5. **Kubernetes secret integration:** Use an appropriate Key Vault integration or supported secret provider for workloads that require secrets at runtime.

A Terraform variable marked `sensitive = true` does not guarantee that the value will be absent from state. Avoid passing long-lived secrets through Terraform if an identity-based alternative is available.

### 6.4 Azure DevOps Workload Identity Federation

CloudCart uses an Azure DevOps service connection named:

`sc-cloudcart-dev-wif`

The service connection was previously reported as configured, and the Terraform pipeline successfully initialised the remote backend.

The recommended authentication flow is:

1. An authorised pipeline starts.
2. Azure DevOps obtains a federated identity token.
3. Microsoft Entra ID validates the federation configuration.
4. Azure issues an access token for the configured identity.
5. Terraform uses the authorised identity to access Azure resources.
6. The backend identity accesses the Terraform state through its assigned permissions.

Keep federation configuration, service connection permissions, and Azure RBAC aligned. Do not grant broad subscription-level permissions unless they are genuinely required.

For larger environments, separate identities and service connections by environment or security boundary.

---

## 7. Why Provision Infrastructure Through a Pipeline?

Infrastructure can be provisioned from a developer terminal, but shared environments should use a controlled and auditable workflow.

### 7.1 Manual versus pipeline provisioning

| Area | Manual local provisioning | Azure DevOps pipeline |
|---|---|---|
| Repeatability | Depends on the engineer's local setup | Uses a defined workflow |
| Review | May happen outside the execution process | Plan and approval stages can be linked to code review |
| Auditability | Logs and records may be inconsistent | Pipeline runs provide a central execution history |
| Authentication | Depends on local credentials | Uses a controlled service connection |
| Concurrent changes | Requires careful coordination | Can be controlled with environment checks and pipeline design |
| Approval | Must be managed separately | Can use protected environments and approvals |
| Consistency | Different engineers may use different commands | Standardised commands and configuration |

A pipeline does not automatically make Terraform secure. Its service connections, permissions, state access, approvals, agent environment, and YAML must also be secured.

### 7.2 Recommended Terraform pipeline stages

1. **Checkout:** Retrieve the reviewed Terraform configuration.
2. **Tool setup:** Use an approved Terraform version.
3. **Formatting:** Run `terraform fmt -check -recursive` as appropriate for the repository.
4. **Initialisation:** Run `terraform init` against the intended remote backend.
5. **Validation:** Run `terraform validate`.
6. **Security checks:** Run selected IaC and policy checks.
7. **Plan:** Generate a Terraform plan for the selected environment.
8. **Review:** Inspect the plan for unexpected changes, especially deletions and replacements.
9. **Approval:** Require appropriate approval before applying sensitive changes.
10. **Apply:** Apply the reviewed plan using the authorised identity.
11. **Verification:** Confirm resource health and expected outputs.

The exact pipeline structure depends on the selected Azure DevOps agent, backend authentication, Terraform version, and approval requirements.

### 7.3 Plan and apply safely

For important environments, the pipeline should apply the exact plan that was reviewed rather than silently generating a different plan after approval.

A saved plan must be treated as sensitive because it may contain sensitive values. Protect its storage and access, and ensure the plan remains appropriate for the current infrastructure and state before applying it.

If the state or infrastructure changes between plan and apply, regenerate and review the plan rather than forcing an outdated plan through.

### 7.4 Avoid unsafe automation

Do not use `terraform apply -auto-approve` as a universal shortcut for every environment.

Automated approval may be appropriate for tightly controlled, low-risk development workflows, but Production should have a deliberate approval and change-control strategy.

Avoid destructive commands such as `terraform destroy` in ordinary CI/CD workflows unless a dedicated, explicitly authorised teardown process is intended.

---

## 8. Should CloudCart Use One Pipeline or Three?

There is no universal rule that every project needs exactly one or three pipelines. The design should separate responsibilities and security boundaries.

For CloudCart, a practical structure is **three pipeline definitions**.

### 8.1 Pipeline 1 — Pull Request Validation

Example filename:

`azure-pipelines-pr.yml`

Purpose:

- Validate changes before merge.
- Run application tests and code quality checks.
- Validate Terraform configuration.
- Validate Kubernetes manifests where appropriate.
- Run selected security checks.

This pipeline should not perform routine Production infrastructure changes.

Recommended checks:

- Application unit tests.
- Terraform formatting and validation.
- Container and dependency checks where configured.
- Kubernetes YAML validation.
- Code review and branch policies.

### 8.2 Pipeline 2 — Infrastructure Provisioning

Example filename:

`azure-pipelines-infra.yml`

Purpose:

- Provision and update Azure infrastructure using Terraform.
- Select the intended environment.
- Initialise the correct backend.
- Generate and review a plan.
- Apply approved infrastructure changes.
- Verify the resulting resources.

Recommended stage structure:

```text
Validate
   |
   v
Terraform Plan
   |
   v
Plan Review / Approval
   |
   v
Terraform Apply
   |
   v
Infrastructure Verification
```

For Dev, the approval policy can be lighter if the team accepts the risk. For Production, use stricter permissions and explicit approval.

Terraform state should remain separated by environment. Pipeline concurrency must be controlled so that two runs do not attempt conflicting operations against the same environment state.

### 8.3 Pipeline 3 — Application CI/CD

Example filename:

`azure-pipelines-ci-cd.yml`

Purpose:

- Build the CloudCart API image.
- Run tests and configured security checks.
- Push a versioned image to ACR.
- Deploy the image to AKS.
- Run smoke tests.
- Promote the same approved artifact through environments.

Recommended stage structure:

```text
Build and Test
      |
      v
Container Security Checks
      |
      v
Push Immutable Image to ACR
      |
      v
Deploy to Dev
      |
      v
Smoke Tests
      |
      v
Deploy to Test
      |
      v
Test Validation
      |
      v
Production Approval
      |
      v
Deploy to Production
      |
      v
Post-Deployment Verification
```

Configure production approvals using protected Azure DevOps Environments and checks where appropriate. Do not rely only on a YAML condition to provide a strong approval boundary.

### 8.4 Why not put everything in one pipeline?

Combining application delivery and all infrastructure provisioning into one large pipeline can create unnecessary coupling.

For example, a small application code change should not automatically trigger a full Terraform apply unless the workflow intentionally requires it.

Separate pipelines make it easier to:

- Control infrastructure permissions separately from application deployment.
- Review infrastructure changes independently.
- Avoid unnecessary Terraform operations.
- Apply different approval rules.
- Diagnose failures.
- Audit which process changed infrastructure or deployed an application.

However, the three pipelines should reuse common templates where useful. Three separate files do not mean duplicating every command or creating three completely independent systems.

---

## 9. CI/CD and Terraform Separation

Terraform provisions the platform. The application pipeline deploys application releases onto that platform.

These are related workflows, but they serve different purposes.

| Responsibility | Terraform infrastructure pipeline | Application CI/CD pipeline |
|---|---|---|
| Create or modify VNet and subnets | Yes | No |
| Create or modify AKS | Yes | No |
| Configure ACR infrastructure | Yes | No |
| Build application image | No | Yes |
| Push application image | Usually no; may manage registry infrastructure separately | Yes |
| Deploy application to AKS | Normally no | Yes |
| Change database infrastructure | Yes | No |
| Run application smoke tests | May run infrastructure health checks | Yes |
| Manage Terraform state | Yes | No |
| Approve Production infrastructure changes | Yes | Not applicable unless deployment changes infrastructure |

This separation reduces the risk of application releases unexpectedly modifying the underlying platform.

---

## 10. Terraform Best Practices

### 10.1 Source control

- Store Terraform configuration in Azure Repos.
- Use feature branches and pull requests.
- Require review for important infrastructure changes.
- Keep environment configuration clear and consistent.
- Do not commit local state files, plan files, credentials, or secrets.
- Use `.gitignore` to exclude generated Terraform files and sensitive local artifacts.

Common exclusions include:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
terraform.tfvars
```

If a non-secret example file is required, commit a clearly named example such as `terraform.tfvars.example`. Do not blindly exclude a file that the team intentionally versions as a non-sensitive environment configuration.

### 10.2 Version control for Terraform and providers

- Pin an approved Terraform CLI version in the execution environment.
- Declare provider requirements and sensible version constraints.
- Commit `.terraform.lock.hcl` so provider selections are reproducible.
- Upgrade providers deliberately and test changes before Production.
- Avoid allowing local machines and pipelines to use uncontrolled, different tool versions.

### 10.3 Naming and tagging

Use consistent resource naming and tags.

Recommended tags include:

- `application = "CloudCart"`
- `environment = "dev"`
- `managed_by = "terraform"`
- `owner = "<team-or-owner>"`
- `cost_centre = "<approved-cost-centre>"`

Adapt required tags to organisational policy. Do not put personal or confidential information in resource tags.

### 10.4 Plan review

Always inspect changes that could cause downtime or data loss.

Pay particular attention to:

- Resource replacements.
- Resource deletions.
- Network and address-space changes.
- AKS cluster and node-pool changes.
- Database changes.
- Identity and RBAC changes.
- Storage account or backend changes.

A successful Terraform plan means Terraform can construct a proposed plan; it does not prove that the proposed architecture is reliable, secure, or free from downtime.

### 10.5 Drift management

Changes made manually in the Azure Portal can cause configuration drift.

- Prefer Terraform for resources managed by Terraform.
- Use refresh and plan workflows to identify drift.
- Review the proposed reconciliation before applying it.
- Do not automatically overwrite every manual change without understanding why it occurred.
- If an emergency manual change is necessary, reconcile the Terraform configuration and state afterward.

### 10.6 Resource lifecycle and protection

Use resource lifecycle controls only when their effects are understood.

For example, `prevent_destroy` can help protect important resources from accidental destruction, but it may also block legitimate replacements or cleanup.

For critical state storage and data resources, combine appropriate Terraform controls with Azure RBAC, resource locks where suitable, backup, and tested recovery procedures.

A Terraform lifecycle setting alone is not a complete data protection strategy.

---

## 11. CloudCart Current Status and Next Steps

The following items were previously reported as completed in the learning environment:

- Azure DevOps project and Azure Repos repository created.
- Terraform and Azure CLI installed.
- Azure subscription access established.
- Bootstrap state resource group and Storage Account created.
- Remote state initialisation successful.
- Dev network created through Terraform.
- Azure DevOps workload identity federation service connection configured.
- Infrastructure plan and apply pipeline successfully applied infrastructure.
- ACR created and application image pushed.
- AKS created and application deployed.
- Application pipeline deployed the image to AKS.
- Initial monitoring features enabled.

These items should be verified against the actual repository, pipeline history, Terraform state, and Azure resources before being treated as the current authoritative status.

### Recommended next steps

1. Review the current repository and document the exact Terraform folder structure.
2. Verify the bootstrap configuration and remote backend settings.
3. Confirm the correct state key for every environment.
4. Review service connection permissions and backend RBAC.
5. Ensure secrets are not stored in Git, pipeline logs, or Terraform outputs.
6. Separate pull-request validation, infrastructure provisioning, and application delivery.
7. Add environment-specific Dev, Test, and Production configuration carefully.
8. Add production approvals, protected environments, and least-privilege service connections.
9. Review Terraform plans for destructive changes before applying them.
10. Add security scanning, deployment smoke tests, and operational verification.
11. Document backup, state recovery, infrastructure rollback, and disaster recovery procedures.
12. Validate the design in a safe environment before adopting Production settings.

---

## 12. Final Design Principles

CloudCart's Terraform and DevOps implementation should follow these principles:

1. **Bootstrap first:** Create the resources required for remote state before configuring the main environments to use them.
2. **Remote state:** Use Azure Blob Storage for shared Terraform state with controlled access.
3. **State isolation:** Maintain a separate state key for each independently managed environment.
4. **Secure authentication:** Prefer workload identity federation and managed identities over long-lived credentials.
5. **Infrastructure as Code:** Manage infrastructure changes through reviewed Terraform configuration.
6. **Pipeline-based provisioning:** Standardise infrastructure operations and retain an auditable execution history.
7. **Separate responsibilities:** Use dedicated validation, infrastructure, and application delivery workflows.
8. **Plan before apply:** Review infrastructure changes and use protected approvals for sensitive environments.
9. **Promote artifacts:** Build an application image once and promote the same approved image through environments.
10. **Protect sensitive data:** Treat Terraform state, saved plans, secrets, and pipeline logs as security-sensitive.
11. **Avoid unsafe changes:** Never destroy or replace existing resources without understanding state ownership, dependencies, and impact.
12. **Test recovery:** Verify that infrastructure and state can be recovered through documented procedures.

**Key principle:** Terraform configuration defines the intended infrastructure, Terraform state records the resource mapping, and Azure DevOps provides a controlled way to validate and apply changes. Reliable DevOps requires all three to be designed and operated securely.
