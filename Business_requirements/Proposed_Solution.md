# CloudCart — Proposed Architecture and Service Selection

## 1. Purpose and Status

This document describes the initial architecture proposal for CloudCart. It explains what each major component does and why it may be suitable for the customer requirements.

**Status: Proposed, pending discovery and design review.** AKS and the other Azure services listed here are learning-project choices, not automatically the best or cheapest option for every customer. We will validate traffic, team skills, compliance, operational capacity, recovery targets, and budget before finalizing the design.

## 2. Architecture Principles

- Meet agreed business requirements rather than selecting tools for their own sake.
- Keep the database and internal services off direct public access where practical.
- Use identity-based access and least privilege.
- Manage infrastructure as reviewed, version-controlled code.
- Automate repeatable checks and deployments.
- Design for observable failure, recovery, and safe change.
- Prefer managed services when their operational benefits justify their cost.
- Make cost, complexity, and reliability trade-offs explicit.
- Keep development environments affordable while testing production characteristics deliberately.

## 3. High-Level Request and Delivery Flows

### Customer request flow

```text
Customer browser
    |
    | HTTPS
    v
Azure Front Door + WAF (proposed edge layer)
    |
    v
Application ingress / entry point
    |
    v
Frontend and backend services running on AKS
    |
    | Approved private network path
    v
Azure SQL (private data tier)
```

The exact ingress implementation and network path will be confirmed during detailed design. Front Door is an edge entry and routing service; Kubernetes ingress is responsible for routing traffic to services inside the cluster. They are not interchangeable.

### Delivery flow

```text
Developer
    |
    v
Git feature branch
    |
    v
Pull request + review
    |
    v
Automated CI checks and tests
    |
    v
Build and scan container image
    |
    v
Azure Container Registry (ACR)
    |
    v
Deploy to Development -> verify -> Test -> approve -> Production
```

Infrastructure changes use a controlled Terraform workflow: formatting and validation, security checks, a reviewed plan, approval where required, apply, and post-deployment verification. Application deployment and infrastructure provisioning are related but distinct workflows.

## 4. Proposed Azure Services and design
![alt text](<azure architecture diagram.png>)

| Component / service | Responsibility | Why it is proposed | Important considerations / alternatives |
|---|---|---|---|
| Azure Front Door + WAF | Public web entry, routing, edge protection | Can provide a global entry point and managed web application firewall controls. | Cost and configuration need review. A regional entry design may be enough for a smaller workload. |
| Azure Virtual Network (VNet) | Private network boundary | Provides network isolation and address space for cloud resources. | Plan address space, peering, DNS, and future growth carefully. |
| Subnets and Network Security Groups (NSGs) | Segment network traffic and enforce network rules | Limit which traffic can reach workloads and supporting resources. | NSGs are not a replacement for application identity, host controls, or a full security architecture. |
| Azure Kubernetes Service (AKS) | Run and orchestrate application containers | Supports deployments, service discovery, replicas, rolling updates, and workload scaling. | Adds cluster, networking, upgrades, and security responsibilities. Azure App Service or Container Apps may be simpler and cheaper for a small application. |
| Kubernetes ingress controller / gateway | Route incoming requests to the correct application service | Separates external routing from application workloads. | Select the controller or gateway based on supported requirements, security, operations, and cost. |
| Azure Container Registry (ACR) | Store versioned container images | Integrates with Azure identity and provides a private image registry. | Restrict access, scan images, use immutable/versioned release references, and manage retention. |
| Azure SQL Database | Managed relational data store | Provides a managed SQL platform with backups and availability options. | Select service tier and redundancy only after workload, RTO/RPO, and budget are known. Keep connectivity private where required. |
| Azure Key Vault | Store secrets, keys, and certificates | Centralizes sensitive configuration and access control. | Prefer managed identity or workload identity over long-lived credentials; define rotation and access policies. |
| Azure Storage | Terraform remote state and other approved storage needs | Can hold Terraform state in a controlled remote backend. | Enable appropriate access controls, versioning/recovery options, and state protection. State can contain sensitive information. |
| Microsoft Entra ID / Azure RBAC | Human and automation identity and permissions | Provides identity-based access and scope-specific authorization. | Use least privilege and separate human access from workload identities. |
| Azure Repo | Source control, pull requests, issues, and documentation | Provides a collaborative, reviewable engineering workflow. | Protect important branches, require reviews/checks, and control repository secrets and permissions. |
| Azure Repositery | CI/CD automation | Runs tests, builds, scans, and controlled deployment workflows. | Prefer OpenID Connect (OIDC) federation for Azure authentication rather than storing long-lived cloud credentials. Protect production environments. |
| Terraform | Infrastructure as Code | Makes infrastructure changes repeatable, reviewable, and version-controlled. | Use modules sensibly, pin versions, protect state, review plans, and handle drift and destructive changes carefully. |
| Azure Monitor + Log Analytics | Infrastructure metrics and centralized logs | Helps operators investigate resource health, capacity, and operational events. | Logging ingestion and retention cost money; define what to collect and for how long. |
| Application Insights | Application performance and request telemetry | Helps trace requests, identify failures, and understand latency. | Instrument the application and avoid logging secrets or unnecessary personal data. |
| Azure alerts and action groups | Notify operators about defined conditions | Converts selected signals into actionable notifications. | Tune thresholds to reduce alert fatigue and assign an owner and response procedure. |

## 5. Why Use a Three-Tier Architecture?

### Tier 1 — Presentation

The frontend provides the user interface and communicates with the backend over defined interfaces. It should not connect directly to the database.

### Tier 2 — Application

The backend validates requests, applies business rules, manages order workflows, and accesses the database using a controlled identity and network path. Health probes and sensible resource requests/limits help Kubernetes manage workloads safely.

### Tier 3 — Data

The database stores products, orders, and related records. Access should be limited to approved application components. Backups, retention, restore testing, encryption, and availability settings must match the agreed business requirements.

A three-tier logical architecture does not necessarily require three separate Kubernetes clusters or three independent compute products. We should choose boundaries that improve security and maintainability without adding unnecessary cost.

## 6. Initial Availability and Reliability Design

The initial customer target is 99.9% monthly availability, subject to approval and a precise measurement definition. Potential design measures include:

- Run multiple application replicas and distribute them appropriately.
- Use readiness, liveness, and startup probes where appropriate.
- Configure resource requests, limits, and autoscaling based on tested workload behavior.
- Consider availability zones for supported compute and data services.
- Check ingress and edge-layer resilience, cluster capacity, and dependency failure modes.
- Select a database availability and backup configuration that meets approved RTO/RPO.
- Use safe rolling deployments and verify releases before considering them successful.
- Test node, pod, dependency, and deployment failures.
- Document whether regional disaster recovery is in scope.

These controls reduce particular risks but do not by themselves guarantee a 99.9% end-to-end service level. Reliability must be tested and assessed across all critical dependencies.

## 7. Terraform Design and Best Practices

The planned Terraform structure will be developed incrementally. A possible starting layout is:


```
cloudcart/
├── app/
│  
├── infra/
│   ├── bootstrap/
│   ├── modules/
│   │   ├── network/
│   │   ├── aks/
│   │   ├── acr/
│   │   ├── api-management/
│   │   ├── application-gateway/
│   │   ├── sql/
│   │   ├── key-vault/
│   │   └── monitoring/
│   └── environments/
│       ├── dev/
│       ├── test/
│       ├── prod/
│       └── dr/
├── k8s/
│   ├── base/
│   └── overlays/
│       ├── dev/
│       ├── test/
│       └── prod/
├── pipelines/
│   └── templates/
├── azure-pipelines-pr.yml
├── azure-pipelines-ci-cd.yml
└── azure-pipelines-infra.yml

This is a starting proposal, not a mandate to create every module immediately. We will add modules when they create useful reuse and clear ownership.

Terraform practices to apply:

- Pin Terraform and provider versions and commit the dependency lock file.
- Keep environment configuration explicit and avoid unsafe production defaults.
- Store state in an appropriately secured remote backend; do not commit state files.
- Use state locking and recovery controls supported by the chosen backend.
- Keep credentials out of code and ordinary variable files.
- Use plan review, automated validation, and approval for sensitive changes.
- Understand resource replacement and deletion before applying a plan.
- Separate infrastructure deployment permissions from application runtime permissions.
- Detect drift and document how manual changes will be reconciled.
- Avoid sharing one state file across unrelated environments or teams without a deliberate reason.

## 8. CI/CD and Identity

A proposed Git workflow:

- `main` contains reviewed, releasable changes.
- Short-lived feature branches are created for individual tasks.
- Pull requests run required checks and receive code review.
- Merging triggers the appropriate build or deployment workflow.
- Dev deployment and verification happen before Test and Production promotion.
- Production deployment requires an explicit approval gate.
- Release artifacts and container image digests are promoted consistently where practical.

We will not assume that permanent `dev`, `test`, and `prod` branches are necessary. Environment promotion can be controlled through pipeline stages and protected environments, while keeping the source workflow simple.

For Azure authentication from GitHub Actions, prefer OIDC/workload federation when configured and supported. Avoid long-lived client secrets in GitHub. Scope federated identity permissions narrowly and protect production deployment environments.

## 9. Monitoring and Operations

We will progressively implement:

- Infrastructure metrics for node, pod, database, and network health.
- Application telemetry for request rate, errors, and latency.
- Centralized logs with suitable access controls and retention.
- Dashboards aligned with customer-facing service health.
- Alerts with thresholds, severity, owner, and response steps.
- Runbooks for common deployment, capacity, connectivity, and dependency incidents.
- Incident reviews recording impact, timeline, root cause, and preventive actions.

Alerts should be tied to meaningful symptoms and service objectives, not just every metric that can be collected.

## 10. Security Controls to Validate

- Use least-privilege Azure RBAC and separate identities for people and automation.
- Use federated authentication for pipelines where possible.
- Keep secrets in an approved secret manager and rotate them when required.
- Restrict database connectivity and validate network paths.
- Enforce TLS for application traffic.
- Scan application dependencies and container images.
- Protect branch and environment settings in GitHub.
- Review Kubernetes RBAC, workload identity, network policies, and pod security settings.
- Enable appropriate audit logs and avoid exposing sensitive values in logs.
- Define patching, incident response, and access-review procedures.

The exact controls depend on the application's threat model and any applicable legal or regulatory obligations.

## 11. Cost and Simpler Alternatives

AKS is useful for learning orchestration and for workloads that benefit from Kubernetes, but it introduces operational complexity and ongoing cost. Before committing to AKS for a real customer, compare it with:

- Azure App Service for a conventional web application.
- Azure Container Apps for managed container workloads with less cluster management.
- Other suitable managed application platforms based on runtime and operational needs.

For the learning project, we may use a reduced-cost setup and create high-availability features only during planned exercises. Review compute, database, edge/WAF, network egress, registry, backup, and monitoring costs. Delete lab resources when no longer needed and confirm that no retained resource continues to incur charges.

## 12. Decisions Still Open

The following need discovery or testing before production approval:

- Expected traffic, response-time objective, and workload profile.
- Existing application language, framework, and data model.
- Azure region, residency, and compliance requirements.
- Final choice of AKS versus a simpler managed compute option.
- Network address plan, ingress approach, and private connectivity.
- Availability zones and regional disaster recovery scope.
- Approved RTO, RPO, backup retention, and restore-test frequency.
- Monthly cloud budget and cost alerts.
- Log retention, alert routing, support coverage, and operational ownership.
- Production approval and rollback criteria.

## 13. Architecture Decision Rule

For each major design choice, record:

1. Requirement being addressed.
2. Selected service or pattern.
3. Alternatives considered.
4. Benefits and trade-offs.
5. Security and reliability implications.
6. Cost and operational impact.
7. Validation or test that will confirm the decision.

This ensures that the platform is designed around customer needs, rather than around the number of cloud services used.
