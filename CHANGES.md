# Required Changes to Run on Any AWS Account

This document outlines all the changes needed to adapt this Terraform module for use in your own AWS account.

## Overview

This module was originally built for a specific organization (Versatile Credit, Inc.) and contains several hardcoded values that need to be modified before use in a different AWS account.

---

## 🔴 CRITICAL CHANGES (Required)

### 1. WAF Web ACL IDs (`variables.tf`)

**Current State:**
```hcl
variable "waf_web_acl_id_public" {
  type        = string
  description = "(Optional) The ID of the WAF ACL to be used when alb_primary_public_access is set to true."
  default     = "13830874-18d3-4ac9-8ec4-73087fdc925f" # General Web
}

variable "waf_web_acl_id_trusted" {
  type        = string
  description = "(Optional) The ID of the WAF ACL to be used when trusted_access_only is set to true."
  default     = "1af64632-079a-425a-8297-5bee399b7029" # Versatile Only Access
}
```

**What to Change:**
- Replace these WAF ACL IDs with your own WAF ACL IDs from your AWS account
- Or remove the defaults and make them required inputs
- Or disable WAF entirely by setting `waf_enabled = false`

**How to Find Your WAF ACL ID:**
```bash
# For WAF Classic (v1)
aws waf-regional list-web-acls --region <your-region>

# For WAF v2
aws wafv2 list-web-acls --scope REGIONAL --region <your-region>
```

**Recommended Approach:**
```hcl
# Option 1: Remove defaults, make them required when WAF is enabled
variable "waf_web_acl_id_public" {
  type        = string
  description = "The ID of the WAF ACL to be used for public access."
  default     = null
}

variable "waf_web_acl_id_trusted" {
  type        = string
  description = "The ID of the WAF ACL to be used for trusted access."
  default     = null
}

# Then add validation in locals.tf or use when calling the module
```

---

### 2. S3 Log Bucket Name (`locals.tf`)

**Current State:**
```hcl
log_bucket_name = "vci-loadbalancer-logs-${var.region}"
```

**What to Change:**
Replace `vci` with your organization's prefix or use a different naming convention.

**Example:**
```hcl
log_bucket_name = "myorg-loadbalancer-logs-${var.region}"
# Or
log_bucket_name = "lb-logs-${var.project}-${var.region}"
```

**Important:** 
- Ensure this S3 bucket exists in your AWS account before deploying
- The bucket must have proper permissions for ALB to write logs
- Bucket policy example:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<elb-account-id>:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
```

**ELB Account IDs by Region:** [AWS Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html)

**Alternative:**
Allow users to specify the bucket name:
```hcl
variable "log_bucket_name" {
  type        = string
  description = "S3 bucket name for load balancer access logs"
  default     = ""
}

locals {
  log_bucket_name = var.log_bucket_name != "" ? var.log_bucket_name : "default-lb-logs-${var.region}"
  # ...
}
```

---

### 3. Default Region (`variables.tf`)

**Current State:**
```hcl
variable "region" {
  type        = string
  description = "(Optional) The region to perform the run against."
  default     = "us-east-2"
}
```

**What to Change:**
Set to your preferred default region or remove the default to make it required.

**Example:**
```hcl
variable "region" {
  type        = string
  description = "(Required) The AWS region to deploy resources."
  # No default - force users to specify
}
```

---

## 🟡 TEST FILE CHANGES (If Using Tests)

### 4. Test Configuration Files

The test files in `tests/public/terragrunt.hcl` and `tests/private/terragrunt.hcl` contain multiple hardcoded values:

#### 4.1 DNS Zone Name
```hcl
dns_zone_name = "vtile.io"  # Change to your domain
```

#### 4.2 Certificate ARNs
```hcl
certificate_arn = "arn:aws:acm:us-east-1:207742269540:certificate/e8d6e560-b017-4831-b9bd-758e62247b2a"
additional_certificate_arns = [
  "arn:aws:acm:us-east-1:207742269540:certificate/acb0f4fb-5780-4624-a650-ad9ed9f5d8f2",
]
```
Replace with your ACM certificate ARNs.

**How to Find Your Certificates:**
```bash
aws acm list-certificates --region <your-region>
```

#### 4.3 Security Group IDs
```hcl
referenced_security_group_id = "sg-0817fa0fec491a72c"  # Change to your SG
```

#### 4.4 EC2 Instance IDs
```hcl
target_id = "i-0de9bb9330dd043c2"  # Change to your instance ID
```

#### 4.5 CIDR Blocks
**Public Test:**
```hcl
cidr_ipv4 = "0.0.0.0/16"  # Should probably be "0.0.0.0/0" for public
```

**Private Test:**
```hcl
cidr_ipv4 = "10.69.0.0/16"  # Change to your VPC CIDR
```

#### 4.6 Parent Terragrunt Configuration
```hcl
include "module-testing" {
  path = "${get_repo_root()}/../terraform-config/terragrunt-module-testing.hcl"
}
```
This references an external Terragrunt configuration that likely doesn't exist in your environment.

---

## 🟢 RECOMMENDED IMPROVEMENTS

### 5. Make Access Logs Configurable

**Current Implementation:**
Access logs use a hardcoded bucket name pattern. Consider making this more flexible:

```hcl
variable "enable_access_logs" {
  type        = bool
  description = "Enable access logging to S3"
  default     = true
}

variable "access_logs_bucket" {
  type        = string
  description = "S3 bucket name for access logs (required if access logs enabled)"
  default     = ""
}

variable "access_logs_prefix" {
  type        = string
  description = "S3 prefix for access logs"
  default     = ""
}

# In locals.tf
locals {
  access_logs_default = var.enable_access_logs && var.access_logs_bucket != "" ? {
    enabled = true
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix != "" ? var.access_logs_prefix : local.name
  } : {
    enabled = false
    bucket  = ""
    prefix  = ""
  }
}
```

### 6. Remove Organization-Specific Tags

Review and remove any organization-specific references in comments and documentation.

### 7. Add Validation

Add input validation to ensure required resources exist:

```hcl
variable "waf_web_acl_id_public" {
  type        = string
  description = "WAF ACL ID for public access"
  default     = null
  
  validation {
    condition     = var.waf_enabled == false || var.waf_web_acl_id_public != null
    error_message = "waf_web_acl_id_public is required when waf_enabled is true"
  }
}
```

---

## 📋 STEP-BY-STEP SETUP CHECKLIST

Follow these steps to adapt the module for your AWS account:

### Step 1: Infrastructure Prerequisites
- [ ] Create VPC with subnets (tag them appropriately)
- [ ] Create S3 bucket for load balancer logs
- [ ] Configure S3 bucket policy for ALB access
- [ ] (Optional) Create/configure WAF ACLs
- [ ] (Optional) Request/import SSL certificates in ACM
- [ ] (Optional) Create Route53 hosted zones

### Step 2: Code Modifications

#### In `variables.tf`:
- [ ] Update default region or remove default
- [ ] Update WAF ACL ID defaults or set to `null`
- [ ] Review all variable defaults

#### In `locals.tf`:
- [ ] Change S3 bucket naming pattern
- [ ] Review tag values

#### In test files (if using):
- [ ] Update domain names
- [ ] Update certificate ARNs
- [ ] Update security group IDs
- [ ] Update instance IDs
- [ ] Update CIDR blocks
- [ ] Update or remove Terragrunt parent reference

### Step 3: Deployment Variables

Create a `terraform.tfvars` or pass variables when calling the module:

```hcl
# Required
region      = "us-east-1"          # Your region
vpc_id      = "vpc-xxxxx"          # Your VPC ID
project     = "my-project"          # Your project name
environment = "dev"                 # Your environment

# Subnets
subnet_tags = {
  tier        = "public"           # Or "private"
  environment = "dev"               # Match your subnet tags
}

# DNS
dns_records = [
  {
    name      = "myapp.example.com"
    zone_name = "example.com"
    type      = "A"
  }
]

# WAF - Disable or provide your ACL IDs
waf_enabled             = false    # Disable if you don't have WAF
# OR
waf_enabled             = true
waf_web_acl_id_public   = "your-acl-id"
waf_web_acl_id_trusted  = "your-acl-id"

# Access Logs - Provide your bucket
access_logs = {
  enabled = true
  bucket  = "your-log-bucket-name"
  prefix  = "my-app-lb"
}

# Security Groups
security_group_ingress_rules = {
  https = {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr_ipv4   = "0.0.0.0/0"      # Adjust as needed
  }
}

security_group_egress_rules = {
  all = {
    from_port   = 0
    to_port     = 0
    ip_protocol = "-1"
    cidr_ipv4   = "0.0.0.0/0"
  }
}

# Listeners
listeners = {
  https = {
    port            = 443
    protocol        = "HTTPS"
    certificate_arn = "arn:aws:acm:region:account:certificate/your-cert-id"
    
    fixed_response = {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = 200
    }
  }
}

# Target Groups
target_groups = {
  main = {
    name     = "my-targets"
    port     = 443
    protocol = "HTTPS"
    health_check = {
      path = "/health"
    }
  }
}

# For testing, allow deletion
enable_deletion_protection = false
```

### Step 4: Initialize and Plan
```bash
terraform init
terraform plan
```

### Step 5: Review and Apply
```bash
terraform apply
```

---

## 🔍 VERIFICATION CHECKLIST

After deployment, verify:

- [ ] Load balancer created successfully
- [ ] Load balancer is in correct subnets
- [ ] Security groups have correct rules
- [ ] DNS records created in Route53
- [ ] Target groups created and healthy
- [ ] Listeners configured correctly
- [ ] SSL certificates attached (if HTTPS)
- [ ] WAF associated (if enabled)
- [ ] Access logs appearing in S3 (if enabled)
- [ ] Health checks passing

---

## 🚨 SECURITY CONSIDERATIONS

1. **Deletion Protection**: Default is `true` - only disable for testing
2. **Security Groups**: Review ingress rules carefully - don't expose more than needed
3. **WAF**: Strongly recommended for public-facing load balancers
4. **SSL/TLS**: Use strong cipher policies (TLS 1.2+)
5. **Access Logs**: Enable for audit and compliance
6. **Subnet Placement**: Public subnets for internet-facing, private for internal
7. **CIDR Ranges**: Use least-privilege principle for security group rules

---

## 📞 SUPPORT

If you encounter issues:

1. Check Terraform output for specific error messages
2. Verify all prerequisites exist in your AWS account
3. Ensure IAM permissions are sufficient
4. Check AWS service quotas/limits
5. Review AWS CloudTrail logs for API errors

---

## Summary of Required Changes

**Minimum changes to make it work:**

1. ✅ Update or disable WAF ACL IDs in `variables.tf`
2. ✅ Update S3 bucket name pattern in `locals.tf`
3. ✅ Update or remove default region in `variables.tf`
4. ✅ Provide appropriate input variables when using the module
5. ✅ Create required AWS resources (VPC, subnets, S3 bucket, etc.)
6. ✅ Update or delete test files if not needed

**Optional but recommended:**

- Make module more flexible with additional input variables
- Add input validation
- Remove hardcoded organization-specific values
- Update documentation
- Add examples specific to your use case

