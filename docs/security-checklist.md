# Security and release checklist

- [ ] PR branch policies enforced.
- [ ] Python unit tests and container build pass.
- [ ] Add SAST, dependency scanning, image scanning and SBOM generation; set agreed severity thresholds.
- [ ] Image tags are immutable; production deploys the same tested artifact.
- [ ] WIF; no client secrets in YAML or variable groups.
- [ ] Separate WIF identities and least privilege for production.
- [ ] Production environment approvals and branch control configured in UI.
- [ ] Terraform state uses private Azure Storage access and RBAC.
- [ ] Kubernetes runs as non-root, drops Linux capabilities, sets requests/limits and probes.
- [ ] Add network policy and restrict outbound traffic where appropriate.
- [ ] Put application secrets in Key Vault; do not use plaintext Kubernetes Secret manifests in Git.
- [ ] Use TLS ingress / Front Door + WAF for public production access.
- [ ] Enable alert rules, dashboards, log retention policy, and test an alert end-to-end.
- [ ] Define backup, restore, incident response and rollback runbooks.
- [ ] Review actual Azure cost before creating Test/Prod clusters.
