## Run Guide

This guide shows how to run this module with either plain Terraform or Terragrunt, choose the AWS account/region, and apply/destroy safely.

### Prerequisites
- Terraform >= 1.3.0, AWS provider ~> 5.0
- AWS CLI configured with a profile or SSO
- IAM permissions to create/update/delete: ELBv2, SG, Route53, and optionally WAF

---

## Select AWS account and region

Windows PowerShell (new terminal after setting):

```powershell
setx AWS_PROFILE my-profile
setx AWS_REGION us-east-2
aws sts get-caller-identity
```

If you use AWS SSO:

```powershell
aws sso login --profile my-profile
```

Alternative (access keys) – not recommended for long-term:

```powershell
setx AWS_ACCESS_KEY_ID <key>
setx AWS_SECRET_ACCESS_KEY <secret>
setx AWS_SESSION_TOKEN <token>   # if using temporary creds
setx AWS_REGION us-east-2
```

---

## Run with Terragrunt (recommended)

Two example stacks are provided:
- `tests/public/terragrunt.hcl` – Internet-facing LB
- `tests/private/terragrunt.hcl` – Internal LB

Both examples now generate a provider with a fixed profile; update `profile` or remove it to rely on `AWS_PROFILE`.

Example commands:

```powershell
cd tests\public
terragrunt init
terragrunt apply -auto-approve
```

Destroy:

```powershell
terragrunt apply -auto-approve -var 'enable_deletion_protection=false'
terragrunt destroy -auto-approve
```

Notes:
- Ensure your parent `terragrunt.hcl` (included by these examples) provides `region` and `vpc_id`. The examples reference a parent outside this repo; adapt to your environment.
- Update certificate ARNs, `dns_zone_name`, `security_group_*_rules`, `target_groups` to match your infra.

Optional WAFv2:

```hcl
inputs = {
  waf_enabled        = true
  waf_version        = 2
  waf_web_acl_arn_v2 = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/my-acl/uuid"
}
```

---

## Run with plain Terraform

From repo root (`aws-lb-main`):

```powershell
terraform init
terraform apply `
  -var "vpc_id=vpc-0123456789abcdef0" `
  -var "project=myapp" `
  -var "environment=dev" `
  -var 'dns_records=[{"name":"myapp-dev","zone_name":"example.com"}]' `
  -var 'subnet_tags={"tier":"public","environment":"dev"}' `
  -var 'enable_deletion_protection=false'
```

Destroy:

```powershell
terraform apply -var 'enable_deletion_protection=false'
terraform destroy
```

---

## Common issues and fixes

- Not applying or destroying (no-op):
  - Verify account/region: `aws sts get-caller-identity`, `echo $Env:AWS_REGION`
  - Check workspace/state: `terraform workspace show`, `terraform state list`
  - Ensure required vars set: `vpc_id`, `project`, `environment`, `dns_records`
  - Using Terragrunt: make sure the parent include exists and sets `region`/`vpc_id`

- ALB cannot be deleted:
  - Set `enable_deletion_protection=false` and apply, then destroy

- WAFv2 association not applied:
  - Set `waf_enabled=true`, `waf_version=2`, and provide `waf_web_acl_arn_v2`

---

## Minimal variables (example)

```hcl
vpc_id      = "vpc-0123456789abcdef0"
project     = "myapp"
environment = "dev"

subnet_tags = {
  tier        = "public"
  environment = "dev"
}

dns_records = [
  { name = "myapp-dev", zone_name = "example.com" }
]
```


