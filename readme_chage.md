## Code changes summary (Before vs Now)

### 1) Terraform and provider requirements
- Before: `required_version = ">= 0.14"`
- Now: `required_version = ">= 1.3.0"`
- Rationale: Align with modern Terraform versions and current AWS provider features.

### 2) WAF support
- Before:
  - Only WAF Classic/Regional via `aws_wafregional_web_acl_association` when `waf_enabled = true` and `waf_version = 1`.
  - Placeholder comment to add WAFv2 in the future.
- Now:
  - Added WAFv2 first-class support through ALB module input:
    - New variable: `waf_web_acl_arn_v2` (string, default null).
    - In `main.tf`, set `web_acl_arn = local.waf_enabled && var.waf_version == 2 ? var.waf_web_acl_arn_v2 : null`.
  - WAF Classic logic remains intact for `waf_version == 1`.
  - Backward compatible: default still uses WAF Classic unless you opt into v2.

### 3) README documentation
- Before: No dedicated run guide and no WAFv2 instructions.
- Now:
  - Updated `README.md` to reflect Terraform >= 1.3, mention WAFv2 variable, and clarify behavior.
  - Added `readme_run.md` with step-by-step instructions (Terraform/Terragrunt), account/region selection, apply/destroy, and troubleshooting.

### 4) Terragrunt examples
- Before: `tests/public` and `tests/private` did not generate a provider block; relied on a parent include outside this repo.
- Now: Added a `generate "provider"` block in both examples to make the AWS `profile`/region explicit and easier to control. You can change `profile` or remove it to rely on `AWS_PROFILE`, and optionally uncomment `assume_role`.

### 5) Behavioral impact
- Default behavior unchanged for existing stacks:
  - `waf_version` still defaults to 1 (WAF Classic).
  - Only when you set `waf_version = 2` and provide `waf_web_acl_arn_v2` will WAFv2 be associated.
- Deletion protection behavior unchanged; still controlled by `enable_deletion_protection`.

### 6) Files touched/created
- Updated: `versions.tf`, `main.tf`, `variables.tf`, `README.md`, `tests/public/terragrunt.hcl`, `tests/private/terragrunt.hcl`
- Added: `readme_run.md`, `readme_chage.md` (this file)

### 7) How to adopt WAFv2 (optional)
Set in your Terragrunt inputs (or Terraform vars):

```hcl
waf_enabled        = true
waf_version        = 2
waf_web_acl_arn_v2 = "arn:aws:wafv2:REGION:ACCOUNT_ID:regional/webacl/NAME/UUID"
```


