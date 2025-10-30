## Run Guide (Terragrunt)

### 1) Login with AWS SSO and set env

```powershell
aws sso login --profile my-profile
setx AWS_PROFILE my-profile
setx AWS_REGION us-east-2        # change if needed
setx VPC_ID vpc-xxxxxxxxxxxxxxxx # your VPC ID
aws sts get-caller-identity
```

Notes
- Provider is generated as `provider "aws" {}` and will use your environment (SSO/profile/region) automatically.
- `region` and `vpc_id` are read from `AWS_REGION` and `VPC_ID` respectively in the example stacks.

### 2) Choose a stack
- Public: `aws-lb/tests/public/terragrunt.hcl`
- Private: `aws-lb/tests/private/terragrunt.hcl`

### 3) Init and apply

```powershell
cd aws-lb\tests\public   # or aws-lb\tests\private
terragrunt init
terragrunt apply -auto-approve
```

### 4) Destroy safely

```powershell
terragrunt apply -auto-approve -var 'enable_deletion_protection=false'
terragrunt destroy -auto-approve
```

### 5) Optional: WAFv2

```hcl
inputs = {
  waf_enabled        = true
  waf_version        = 2
  waf_web_acl_arn_v2 = "arn:aws:wafv2:REGION:ACCOUNT_ID:regional/webacl/NAME/UUID"
}
```

### Troubleshooting
- No-op apply/destroy: verify account/region (`aws sts get-caller-identity`) and ensure `AWS_REGION`/`VPC_ID` are set
- Cannot destroy ALB: first apply `enable_deletion_protection=false`, then destroy
- Check context: `terragrunt info` and `terraform state list`