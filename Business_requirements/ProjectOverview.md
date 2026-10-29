# CloudCart — End-to-End DevOps Learning Project

## 1. Project Overview

CloudCart is a simulated e-commerce platform used to learn the complete DevOps lifecycle through a realistic customer engagement. The project begins when a customer shares a business need and continues through requirements discovery, architecture, source control, infrastructure provisioning, CI/CD, security, production operations, monitoring, incident response, and continuous improvement.

The goal is not simply to use a collection of tools. The goal is to understand why each technical decision is made, how the components work together, what alternatives exist, and how to operate the resulting platform responsibly.

> **Project status:** Initial concept and planning. The architecture and targets in these documents are starting assumptions that must be validated during requirements discovery before they are treated as approved production requirements.

## 2. Simulated Customer

CloudCart Ltd. wants a secure, reliable online shopping platform. Customers should be able to browse products and place orders. The development team needs a repeatable way to test changes and release them safely.

We will act as the DevOps engineering team responsible for turning the customer's goals into a documented, deployable, and supportable platform.

## 3. What We Will Build

The learning project will progressively deliver:

- A sample e-commerce application with a frontend, backend API, and relational database.
- A documented three-tier architecture with clear network and security boundaries.
- Separate Development, Test, and Production environments.
- A Git workflow with branches, pull requests, code review, and release practices.
- Infrastructure as Code (IaC) using Terraform, including reusable modules and remote state.
- Container images built and tested through a CI pipeline and stored in a container registry.
- Automated deployment workflows with validation, environment approvals, smoke tests, and a rollback approach.
- Security controls for identity, permissions, secrets, network access, and container images.
- High-availability and recovery design appropriate to the agreed service objectives.
- Monitoring, dashboards, alerts, runbooks, incident response, and root-cause analysis.
- Documentation of architecture decisions, operational procedures, cost assumptions, and known limitations.

## 4. Proposed Technology Direction

The initial learning path is Azure-based and may use:

- GitHub for source control and project documentation.
- AzureDevops for CI/CD.
- Terraform for infrastructure provisioning.
- Azure networking and security services.
- Azure Kubernetes Service (AKS) for container orchestration.
- Azure Container Registry (ACR) for container images.
- Azure SQL for relational data.
- Azure Key Vault for secrets and certificates.
- Azure Monitor, Log Analytics, and Application Insights for observability.

These are proposed choices, not fixed requirements. During discovery and design, we will compare alternatives and confirm which services are justified by the customer's needs, budget, operational skills, and reliability targets.

## 5. End-to-End Project Journey

1. **Customer discovery:** clarify business goals, users, existing systems, constraints, risks, and success criteria.
2. **Requirements and planning:** document functional and non-functional requirements, service objectives, acceptance criteria, risks, and work items.
3. **Architecture and service selection:** design the application, network, security boundaries, availability, recovery, and cost model.
4. **Git and team workflow:** create the repository, agree on branch and pull-request practices, and organize work into issues.
5. **Application development:** build or adapt the frontend and backend, add tests, and define configuration and health checks.
6. **Terraform foundation:** provision infrastructure with reusable code, remote state, validation, and controlled changes.
7. **CI/CD implementation:** automate checks, builds, image publishing, infrastructure plans, deployments, and verification.
8. **Security and reliability:** implement least privilege, secret handling, network restrictions, redundancy, backups, and recovery procedures.
9. **Monitoring and operations:** define service indicators, dashboards, actionable alerts, runbooks, and incident procedures.
10. **Review and improvement:** test failure scenarios, review costs, document lessons learned, and refine the design.

## 6. Learning Method

Each phase follows this cycle:

**Understand → Design → Implement → Test → Document → Review**

For every important service or configuration, we will answer:

- What problem does it solve?
- Why is it appropriate for this requirement?
- What alternatives could we use?
- What are the security, reliability, operational, and cost trade-offs?
- How will we test it?
- How will we troubleshoot and maintain it in production?

We will progress in small, verifiable steps. Costly resources will be created only when needed for a lab and removed when they are no longer required, unless a test specifically needs them to remain available.

## 7. Expected Outcomes

By the end, the repository should demonstrate that we can explain and implement a practical DevOps workflow from customer requirements to production operations. It should also provide evidence for technical discussions and interviews, including architecture diagrams, Terraform code, pipelines, test results, monitoring examples, runbooks, and incident postmortems.

## 8. Scope and Important Limitations

This is a learning simulation, not a certified production service. A production deployment would require customer approval, a validated threat model, actual workload and cost estimates, security and compliance review, tested recovery procedures, and operational ownership. Availability targets cannot be guaranteed by architecture diagrams alone; they depend on the complete implementation and the relevant cloud service agreements.

## 9. Document Guide
- [`Business_Requirements.md`](Business_Requirements.md) — customer business requirements and initial targets.
- [`ProjectOverview.md`](ProjectOverview.md1.md) — project overview and learning journey.

- [`Proposed_Solution.md`](Proposed_Solution.md) — proposed architecture and service selection rationale.
