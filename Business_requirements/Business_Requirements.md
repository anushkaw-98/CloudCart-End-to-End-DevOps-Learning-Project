# CloudCart — Customer Business Requirements and Initial Targets

## 1. Purpose

This document records the initial brief from the simulated customer, CloudCart Ltd. It is a working requirements baseline for discovery and design. Items described as assumptions or targets are not contractual commitments until they have been discussed, measured where appropriate, and approved by the customer.

## 2. Customer Statement

> We operate an online shopping business and need a secure, reliable cloud platform. Customers must be able to browse products and place orders. Our developers need a safe and repeatable way to deliver application changes. We want separate environments, infrastructure managed through code, monitoring and alerting, and a recovery plan for important data.

## 3. Business Goals

- Provide a dependable online shopping experience.
- Reduce manual and inconsistent deployment steps.
- Enable developers to deliver changes through a controlled workflow.
- Separate non-production environments from production.
- Improve visibility into application health and infrastructure performance.
- Protect customer and application data.
- Make infrastructure changes reviewable, repeatable, and traceable.
- Understand and control cloud costs.

## 4. Initial Functional Requirements

| ID | Requirement | Initial acceptance idea |
|---|---|---|
| FR-01 | Customers can browse available products . | A user can load the product list through the application UI. |
| FR-02 | Customers can place an order. | A valid order is accepted by the backend and persisted in the database. |
| FR-03 | The application has distinct frontend, backend, and data tiers. | Requests flow through defined application interfaces; the database is not directly exposed to the internet. |
| FR-04 | The team can deploy application changes using CI/CD. | A reviewed change can pass automated checks and be deployed using the approved workflow. |
| FR-05 | The team can deploy infrastructure through Terraform. | Infrastructure changes are reviewed using a Terraform plan before being applied. |
| FR-06 | Dev, Test, and Production are separated. | Each environment has explicit configuration, access boundaries, and deployment controls. |
| FR-07 | Operators can observe system health. | Relevant metrics and logs are available in dashboards, with actionable alerts for agreed conditions. |
| FR-08 | Data can be recovered after accidental loss or a service incident. | Backup and restore procedures are documented and restore tests are performed. |

## 5. Initial Non-Functional Requirements

### Availability and reliability

- **Initial availability target:** 99.9% per month for the agreed customer-facing service.
- Identify single points of failure and document how each critical component is made resilient.
- Define health checks, capacity limits, scaling behavior, and safe deployment procedures.
- Validate cloud service dependencies and their service-level agreements.
- Test failure scenarios rather than assuming that multiple replicas automatically guarantee availability.

A 99.9% monthly availability target corresponds to roughly 43.8 minutes of downtime in a 30.4-day month. The exact measurement window, exclusions, and service boundary must be agreed with the customer.

### Performance and scale

The expected user count, traffic pattern, response-time objectives, and peak order rate are **not yet known**. These must be discovered before sizing compute, database, networking, or autoscaling limits. Performance acceptance criteria should be based on representative load tests.

### Security

- Use least-privilege access for developers, automation, and runtime identities.
- Do not commit passwords, tokens, certificates, or other secrets to Git.
- Keep the database private and restrict access to approved application components.
- Encrypt data in transit and use supported encryption at rest.
- Review container images and dependencies for known vulnerabilities.
- Log security-relevant and administrative activity, while avoiding unnecessary sensitive data in logs.
- Define retention, access, and incident-response expectations.

### Deployments and change control

- Run automated tests and quality checks before release.
- Use pull requests and code review for shared branches.
- Separate infrastructure provisioning from application release responsibilities where appropriate.
- Require an explicit approval before production deployment.
- Verify a deployment with health checks or smoke tests.
- Document rollback or roll-forward procedures and how database changes will be handled safely.

### Monitoring and support

- Collect application and infrastructure metrics and logs.
- Define actionable alerts with severity, owner, response steps, and escalation path.
- Create runbooks for common failures.
- Capture incident timelines, root causes, and corrective actions.
- Agree on support hours and incident response expectations during discovery.

## 6. Initial Recovery Targets

The following are planning items, not approved customer commitments:

| Item | Initial status | Required follow-up |
|---|---|---|
| RTO — Recovery Time Objective | TBD | Agree the maximum acceptable time to restore the service after a defined disruption. |
| RPO — Recovery Point Objective | TBD | Agree the maximum acceptable amount of data loss measured in time. |
| Database backup frequency | TBD | Confirm data criticality, retention, cost, and recovery requirements. |
| Regional disaster recovery | TBD | Decide whether regional failover is required and affordable. |
| Restore testing | Required | Document and periodically test a recovery procedure. |

High availability within a region and disaster recovery across regions address different failure scenarios. The final design must state which scenarios are covered and which are outside scope.

## 7. Initial Environment Requirements

| Environment | Purpose | Initial controls |
|---|---|---|
| Development | Frequent engineering changes and early tests. | Low-cost resources, developer access, automated checks. |
| Test | Integration, acceptance, and release verification. | Controlled configuration, repeatable test data, deployment validation. |
| Production | Customer-facing service. | Restricted access, approved changes, monitoring, backups, and documented recovery. |

Environment isolation may use separate resource groups, networks, subscriptions, accounts, or a combination. The choice will be made during design based on security, governance, and cost requirements.

## 8. Budget and Constraints

- The customer has requested cost awareness, but no monetary budget has been supplied.
- We must estimate expected and peak usage before selecting production capacity.
- The learning lab should use the smallest practical footprint and avoid leaving expensive resources running unnecessarily.
- Costs for AKS, managed databases, WAF, network traffic, logging ingestion, backups, and multi-zone or multi-region redundancy must be considered.
- Production reliability choices should be justified against business impact, not made solely to use more services.

## 9. Open Questions for Customer Discovery

Before finalizing the design, ask the customer:

1. How many daily and concurrent users are expected? What are the peak traffic periods?
2. Is there an existing application, repository, database, or deployment process?
3. Which application language, framework, and database are required?
4. What data is collected, and are there privacy, regulatory, or residency constraints?
5. What response-time and throughput objectives are required?
6. Is 99.9% availability measured across the entire service? What counts as downtime?
7. What RTO and RPO are acceptable? Is cross-region recovery required?
8. What is the monthly cloud budget and expected growth?
9. Who can approve production changes, and what support coverage is expected?
10. Which identity provider, security policies, and audit requirements must be followed?
11. What data-retention and log-retention periods are needed?
12. How will acceptance testing and go-live approval be performed?

## 10. Initial Definition of Done

The initial project can be considered ready for a controlled demonstration when:

- The requirements and design decisions are documented and reviewed.
- The sample application works through its frontend and backend and persists data.
- Terraform can validate and provision the agreed environment repeatably.
- CI checks and deployment workflows operate successfully.
- Secrets are not stored in source control and permissions follow least privilege.
- The database is not publicly exposed.
- Health checks, dashboards, and actionable alerts are demonstrated.
- Backup restoration and deployment recovery are tested and documented.
- Costs, known limitations, runbooks, and operational ownership are documented.

These criteria will be refined after customer discovery.
