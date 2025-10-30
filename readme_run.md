*** Begin Patch
*** Add File: d:\shiva_devops\aws-lb-main\readme_run.md
+## Run Guide (Terragrunt)
+
+### 1) Set account and region
+
+```powershell
+setx AWS_PROFILE my-profile
+setx AWS_REGION us-east-2
+aws sts get-caller-identity
+```
+
+For AWS SSO:
+
+```powershell
+aws sso login --profile my-profile
+```
+
+### 2) Pick a stack and review inputs
+- Public: `tests/public/terragrunt.hcl`
+- Private: `tests/private/terragrunt.hcl`
+
+Update as needed:
+- `profile` (or remove and use `AWS_PROFILE`)
+- `region`, `vpc_id` (via parent include or locals -> inputs)
+- Certificates, `dns_zone_name`, security group rules, target groups
+
+### 3) Init and apply
+
+```powershell
+cd tests\public   # or tests\private
+terragrunt init
+terragrunt apply -auto-approve
+```
+
+### 4) Destroy safely
+
+```powershell
+terragrunt apply -auto-approve -var 'enable_deletion_protection=false'
+terragrunt destroy -auto-approve
+```
+
+### 5) Optional: WAFv2
+
+```hcl
+inputs = {
+  waf_enabled        = true
+  waf_version        = 2
+  waf_web_acl_arn_v2 = "arn:aws:wafv2:REGION:ACCOUNT_ID:regional/webacl/NAME/UUID"
+}
+```
+
+### Troubleshooting
+- No-op apply/destroy: confirm account/region and that parent include sets `region`/`vpc_id`
+- Cannot destroy ALB: disable deletion protection first (apply), then destroy
+- Check state/context: `terragrunt info`, `terraform state list`
+
*** End Patch