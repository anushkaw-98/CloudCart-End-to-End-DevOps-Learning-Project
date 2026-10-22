# Terraform backend bootstrap

Existing bootstrap (from CloudCart work so far):
- Resource group: `rg-cloudcart-tfstate`
- Storage account: name is subscription-specific; fill it into each environment backend file
- Container: `tfstate`

The backend must exist before `terraform init`. Grant the developer identity and pipeline identity `Storage Blob Data Contributor` on the state storage scope. Enable secure transfer, restrict network access as appropriate, and configure retention/soft delete. Protect the bootstrap separately from normal environment apply pipelines.
