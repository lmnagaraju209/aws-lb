## AWS Load Balancer Module (Terragrunt-first)

This repository provisions an AWS ALB/NLB using `terraform-aws-modules/alb/aws` and manages Route53 records and optional WAF. All examples and commands below use Terragrunt.

### What it creates
- ALB/NLB and its security group
- Route53 public/private alias records
- Optional WAF (Classic or v2)

### Requirements
- Terragrunt and Terraform (Terraform >= 1.3.0)
- AWS credentials with permissions for ELBv2, SG, Route53, and optionally WAF

### Choose AWS account and region
Use an AWS profile (recommended):

```powershell
setx AWS_PROFILE my-profile
setx AWS_REGION us-east-2
aws sts get-caller-identity
```

If using AWS SSO:

```powershell
aws sso login --profile my-profile
```

### Terragrunt provider block (examples include this)
Adjust `profile` or remove it to rely on `AWS_PROFILE`:

```hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = var.region
  profile = "my-profile"
  # assume_role {
  #   role_arn     = "arn:aws:iam::123456789012:role/TerraformExecutionRole"
  #   session_name = "terragrunt"
  # }
}
EOF
}
```

### Inputs (via Terragrunt inputs = { ... })
- Required: `vpc_id`, `project`, `environment`, `dns_records`
- Common: `subnet_tags`, `listeners`, `target_groups`, `enable_deletion_protection`
- WAF options: `waf_enabled`, `waf_version` (1 or 2), `waf_trusted_access_only`, `waf_web_acl_arn_v2`

### Run with Terragrunt
Public LB example:

```powershell
cd tests\public
terragrunt init
terragrunt apply -auto-approve
```

Private LB example:

```powershell
cd tests\private
terragrunt init
terragrunt apply -auto-approve
```

Destroy (ensure deletion protection is disabled):

```powershell
terragrunt apply -auto-approve -var 'enable_deletion_protection=false'
terragrunt destroy -auto-approve
``;

### Enable WAFv2 (optional)

```hcl
inputs = {
  waf_enabled        = true
  waf_version        = 2
  waf_web_acl_arn_v2 = "arn:aws:wafv2:REGION:ACCOUNT_ID:regional/webacl/NAME/UUID"
}
```

### Troubleshooting (Terragrunt)
- No changes/no-op: verify account/region (`aws sts get-caller-identity`), parent include provides `region`/`vpc_id`, and required inputs exist
- Destroy blocked: first apply `enable_deletion_protection=false`, then destroy
- State/workspace confusion: run `terragrunt info` and ensure you’re in the intended stack folder

## AWS Load Balancer Terraform Module

This repository provisions an AWS Application/Network Load Balancer using the community `terraform-aws-modules/alb/aws` module and manages optional Route53 records and WAF association.

### What this module creates
- **ALB/NLB** via `module "alb"` in `main.tf`
- **Security group** for the LB with configurable ingress/egress rules
- **Route53 records** (public and/or private) in `dns.tf` pointing to the LB
- **Optional WAF association** (`aws_wafregional_web_acl_association`) if enabled

### Key files
- `versions.tf`: pins Terraform and AWS provider versions
- `variables.tf`: inputs (region, vpc_id, project, environment, DNS, listeners, target groups, WAF, etc.)
- `locals.tf`: derived values like `name`, `internal`, default access logs config, and common tags
- `main.tf`: ALB module, subnet discovery by tags, optional WAF v1 association, and WAF v2 via `web_acl_arn`
- `dns.tf`: Route53 public/private alias records to the ALB
- `outputs.tf`: useful outputs (ALB ARN/DNS, security group, listeners, target groups)
- `tests/private|public/terragrunt.hcl`: example Terragrunt inputs for private/public LBs (for reference/testing)

---

## Prerequisites
- Terraform >= 1.3.0 and AWS provider ~> 5.0
- AWS credentials configured for the target account (one of):
  - Environment variables: `AWS_PROFILE` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` (and optional `AWS_SESSION_TOKEN`)
  - Shared config/credentials files (`~/.aws/config`, `~/.aws/credentials`)
  - IAM Role via SSO or instance profile

> Account is selected by how you authenticate to AWS (profile/keys/role) — there is no hardcoded account ID in this module.

---

## Inputs you must provide
Required:
- `vpc_id`: VPC where the ALB/NLB is deployed
- `project`: project tag and naming prefix
- `environment`: environment tag and naming suffix
- `dns_records`: list of DNS records to create; each record has `name` and `zone_name` at minimum

Common optional inputs:
- `region` (default `us-east-2`)
- `subnet_tags`: tags that select the subnets for the LB (defaults to `{ tier = "private", environment = "test" }`)
- `listeners`: listener map per `terraform-aws-modules/alb/aws` expectations
- `target_groups`: target groups map keyed by your names
- `enable_deletion_protection` (default `true`)
- `waf_enabled`, `waf_version`, `waf_trusted_access_only`, `waf_web_acl_arn_v2`

See `variables.tf` for the full schema and defaults.

---

## How region and account are chosen
- **AWS Account**: determined by your AWS credentials (e.g., `AWS_PROFILE=my-prod`). There is no variable for account ID in this module.
- **AWS Region**: the module exposes a `region` variable (default `us-east-2`) used for naming/logs. The actual provider region is set outside this module via provider configuration or (when using Terragrunt) the parent `terragrunt.hcl`.

If you run plain Terraform in this folder, set the provider region using environment variables, for example:

```bash
setx AWS_PROFILE my-profile
setx AWS_REGION us-east-2
```

Or pass `-var "region=us-east-2"` as needed.

---

## Usage with plain Terraform
From `aws-lb-main/`:

```bash
terraform init
terraform apply \
  -var "vpc_id=vpc-0123456789abcdef0" \
  -var "project=myapp" \
  -var "environment=dev" \
  -var 'dns_records=[{"name":"myapp-dev","zone_name":"example.com"}]' \
  -var 'subnet_tags={"tier":"public","environment":"dev"}' \
  -var 'enable_deletion_protection=false'
```

Notes:
- Ensure your VPC and subnets exist; subnets are discovered by `var.subnet_tags`.
- Set `listeners` and `target_groups` as needed for your application.

Destroy:

```bash
terraform destroy
```

If deletion protection was enabled, first apply with `-var 'enable_deletion_protection=false'`, then destroy.

---

## Usage with Terragrunt (examples)
The `tests/private` and `tests/public` folders show example inputs only. They include a parent `terragrunt.hcl` outside this repo path to set `region`/`vpc_id`. Adapt these examples to your environment.

Key places to change when copying those examples:
- Certificates ARNs in `listeners.https` (ACM must be in the same region as the ALB)
- `dns_zone_name`, `project`, `environment`
- `security_group_*_rules`, `target_groups`
- The parent include that sets `region` and `vpc_id`

---

## Where to change AWS account details
- **Account**: switch your AWS credentials/profile (e.g., `AWS_PROFILE`, SSO, or keys). That’s how you point Terraform to a different AWS account.
- **Region**: set `AWS_REGION`/`AWS_DEFAULT_REGION` or your provider/Terragrunt parent; optionally also set the module `var.region` for names/logs consistency.

There is no account ID variable inside this module; credentials determine the target account.

---

## Why "no resource changes" may occur
If `terraform plan/apply` shows no changes:
1. You are running in a clean state with missing required variables — Terraform would normally error. If it doesn’t, verify you are in the right folder and state file.
2. The state already reflects the desired config — verify you are using the same state backend and workspace as the previous apply.
3. You ran inside `tests/*` without a valid parent `terragrunt.hcl` — Terragrunt may resolve to no inputs or a different root, resulting in no-op.
4. `count`/`for_each` are empty because inputs are empty — ensure `dns_records`, `listeners`, and `target_groups` are set appropriately.

Checklist:
- Run `terraform providers` and `terraform workspace show` to ensure you are in the expected context
- Run `terraform state list` to see what resources Terraform thinks exist
- Confirm required variables are passed (especially `vpc_id`, `project`, `environment`, `dns_records`)

---

## Why destroy might not work
Common blockers:
1. **Deletion protection enabled**: If the ALB was created with `enable_deletion_protection = true`, AWS will refuse deletion. Fix: run an apply to set `enable_deletion_protection=false`, then run `terraform destroy`.
2. **State drift or different workspace**: If your current state doesn’t contain the resources, `destroy` will do nothing. Check `terraform state list` and that you’re using the correct backend/workspace.
3. **Insufficient IAM permissions**: Ensure the AWS identity can delete ALB, security groups, and Route53 records.
4. **Dependent resources**: If other stacks reference the security group or target groups, detach them first.

---

## Minimal variable example

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

listeners = {
  http-https-redirect = {
    port     = 80
    protocol = "HTTP"
    redirect = { port = "443", protocol = "HTTPS", status_code = "HTTP_301" }
  }
}

target_groups = {
  app = {
    name         = "myapp-dev-app"
    target_type  = "instance"
    protocol     = "HTTP"
    port         = 80
    health_check = { path = "/" }
  }
}
```

---

## Support
If you continue to see no-ops or blocked destroys, share the outputs of:
- `terraform version`
- `terraform workspace show`
- `terraform state list`
- `terraform plan -out tfplan && terraform show -no-color tfplan`



