# AWS Load Balancer Terraform Module

## Overview

This is a **Terraform module** for deploying and managing AWS Application Load Balancers (ALB) or Network Load Balancers (NLB) with advanced features including DNS integration, WAF protection, and comprehensive security configurations.

## What Does This Code Do?

This Terraform module automates the creation and configuration of:

### 1. **Load Balancer (ALB/NLB)**
   - Creates either an Application Load Balancer or Network Load Balancer
   - Supports both **internal** (private) and **internet-facing** (public) configurations
   - Automatically determines load balancer type based on subnet tags
   - Configures idle timeout and XFF (X-Forwarded-For) headers

### 2. **Security Groups**
   - Creates and manages security groups for the load balancer
   - Configures custom ingress and egress rules
   - Supports both CIDR-based and security group reference-based rules

### 3. **DNS Records (Route53)**
   - Automatically creates Route53 DNS records pointing to the load balancer
   - Supports both **public** and **private** hosted zones
   - Supports multiple routing policies:
     - Weighted routing
     - Latency-based routing
     - Geolocation routing
     - Failover routing

### 4. **Target Groups**
   - Configures target groups for routing traffic to backend instances
   - Supports multiple target types (instance, IP, Lambda)
   - Configurable health checks
   - Supports both EC2 instances and Auto Scaling Groups

### 5. **Listeners**
   - Creates HTTPS and HTTP listeners
   - Supports SSL/TLS termination with ACM certificates
   - Configures listener rules for host-based or path-based routing
   - Supports HTTP to HTTPS redirects

### 6. **WAF Integration**
   - Optional AWS WAF (Web Application Firewall) integration
   - Supports both WAF Classic (v1) and WAFv2
   - Different WAF policies for public vs trusted-only access
   - Automatically disabled for internal load balancers

### 7. **Access Logging**
   - Configures S3 bucket logging for load balancer access logs
   - Default logging enabled to centralized log bucket

### 8. **Tagging & Organization**
   - Automatic tagging with project, environment, and terraform-managed tags
   - Consistent naming convention: `{project}-{environment}`

## Architecture

```
Internet/VPC
    ↓
[Load Balancer] ← [Route53 DNS Records]
    ↓
[Security Group Rules]
    ↓
[Listeners (HTTP/HTTPS)]
    ↓
[Target Groups]
    ↓
[EC2 Instances / Auto Scaling Groups]
```

## Can This Run on Any AWS Account?

### ⚠️ **NO - Not Without Modifications**

This module is **pre-configured for a specific organization** (Versatile Credit Inc.) and has hardcoded values that will **NOT** work on other AWS accounts:

### Issues That Prevent Universal Use:

1. **Hardcoded WAF ACL IDs** (`variables.tf` lines 143-153)
   - Default WAF ACL IDs are specific to the original account
   - You'll need to replace these with your own WAF ACLs or disable WAF

2. **Hardcoded S3 Log Bucket** (`locals.tf` line 11)
   - References: `vci-loadbalancer-logs-${region}`
   - This bucket must exist in your account, or you need to change the name

3. **Test Configuration Examples**
   - Certificate ARNs in test files are specific to the original account
   - Security Group IDs reference existing infrastructure
   - VPC and subnet configurations are account-specific

4. **Route53 Hosted Zones**
   - Requires existing Route53 hosted zones
   - Zone names in tests (`vtile.io`) won't exist in your account

### ✅ **To Make It Work on Your AWS Account:**

You need to:

1. **Modify or Remove WAF Configuration:**
   ```hcl
   # Option 1: Disable WAF
   waf_enabled = false
   
   # Option 2: Provide your own WAF ACL IDs
   waf_web_acl_id_public = "your-waf-acl-id"
   waf_web_acl_id_trusted = "your-waf-acl-id"
   ```

2. **Create or Specify Your S3 Log Bucket:**
   - Create an S3 bucket for ALB logs with proper permissions
   - Or modify `locals.tf` to use your bucket name

3. **Update Test Configurations:**
   - Replace certificate ARNs with your ACM certificates
   - Update VPC IDs, subnet tags, and security group references
   - Modify Route53 zone names to match your domains

4. **Ensure Prerequisites Exist:**
   - VPC with properly tagged subnets
   - Route53 hosted zones (if using DNS features)
   - ACM certificates (if using HTTPS)
   - IAM permissions for creating ALB resources

## Prerequisites

### AWS Resources Required:
- ✅ VPC with subnets tagged appropriately (`tier` and `environment` tags)
- ✅ Route53 Hosted Zones (for DNS record creation)
- ✅ ACM SSL/TLS Certificates (for HTTPS listeners)
- ✅ S3 bucket for access logs (with ALB write permissions)
- ✅ (Optional) WAF Web ACLs if WAF is enabled

### AWS Permissions Required:
- EC2 (VPC, Subnets, Security Groups)
- Elastic Load Balancing (ALB/NLB)
- Route53 (DNS records)
- ACM (Certificate access)
- S3 (Log bucket access)
- WAF/WAFv2 (if enabled)

### Tools Required:
- Terraform >= 0.14
- AWS Provider ~> 5.0
- AWS CLI configured with appropriate credentials

## Usage Example

```hcl
module "load_balancer" {
  source = "./aws-lb-main-latest"
  
  # Required Variables
  vpc_id      = "vpc-xxxxx"
  project     = "my-app"
  environment = "production"
  
  # Subnet Configuration
  subnet_tags = {
    tier        = "public"  # "public" for internet-facing, "private" for internal
    environment = "production"
  }
  
  # Security Group Rules
  security_group_ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS from Internet"
    }
  }
  
  security_group_egress_rules = {
    backend = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/16"
      description = "To backend instances"
    }
  }
  
  # DNS Records
  dns_records = [
    {
      name      = "app.example.com"
      zone_name = "example.com"
      type      = "A"
    }
  ]
  
  # Listeners
  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:us-east-2:xxxxx:certificate/xxxxx"
      
      forward = {
        target_group_key = "backend"
      }
    }
  }
  
  # Target Groups
  target_groups = {
    backend = {
      name         = "my-app-backend"
      protocol     = "HTTPS"
      port         = 443
      health_check = {
        path = "/health"
      }
    }
  }
  
  # Disable WAF if not configured
  waf_enabled = false
  
  # Access Logs (make sure bucket exists)
  access_logs = {
    enabled = true
    bucket  = "my-alb-logs-bucket"
    prefix  = "my-app-production"
  }
}
```

## Key Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `vpc_id` | VPC ID where ALB will be created | Yes | - |
| `project` | Project name for tagging | Yes | - |
| `environment` | Environment (dev/test/prod) | Yes | - |
| `subnet_tags` | Tags to identify subnets | No | `{tier="private", environment="test"}` |
| `load_balancer_type` | Type: "application" or "network" | No | "application" |
| `listeners` | Map of listener configurations | No | `{}` |
| `target_groups` | Map of target group configurations | No | `{}` |
| `dns_records` | List of Route53 DNS records | Yes | - |
| `waf_enabled` | Enable WAF protection | No | `true` |
| `enable_deletion_protection` | Prevent accidental deletion | No | `true` |

## Outputs

The module provides these outputs:
- `lb_arn` - ARN of the load balancer
- `lb_dns_name` - DNS name of the load balancer
- `security_group_id` - ID of the security group
- `target_groups` - Map of created target groups
- `listeners` - Map of created listeners
- `aws_route53_records_public` - Public DNS records created
- `aws_route53_records_private` - Private DNS records created

## How to Deploy

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Review the Plan
```bash
terraform plan
```

### 3. Apply the Configuration
```bash
terraform apply
```

### 4. Destroy Resources (when needed)
```bash
terraform destroy
```

## Important Notes

⚠️ **Security Considerations:**
- Deletion protection is enabled by default (`enable_deletion_protection = true`)
- Always review security group rules before deployment
- Use appropriate WAF rules for public-facing load balancers
- Ensure SSL/TLS certificates are valid and not expired

⚠️ **Cost Implications:**
- Load Balancers have hourly charges (~$16-22/month for ALB)
- Data transfer charges apply
- WAF has additional charges if enabled
- S3 storage costs for access logs

⚠️ **Account-Specific Configuration Required:**
- This module requires customization for your AWS account
- Review and update all hardcoded values
- Ensure all prerequisite resources exist

## Troubleshooting

### Common Issues:

1. **"Subnet not found" errors**
   - Verify subnets have correct tags matching `subnet_tags`
   
2. **"Certificate not found" errors**
   - Ensure ACM certificate ARN is correct and in the same region
   
3. **"S3 bucket access denied" errors**
   - Verify S3 bucket policy allows ALB to write logs
   - Check bucket exists in the correct region

4. **"WAF ACL not found" errors**
   - Either disable WAF or provide valid WAF ACL IDs for your account

## Version History

- **v1.1.0** (2023-10-31) - Updated to support v9.x of upstream ALB module
- **v1.0.1** (2023-10-23) - Fixed target groups mapping issue
- **v1.0.0** (2023-10-19) - Initial release

## License

This module appears to be proprietary to Versatile Credit Inc. Check with the original authors for licensing information.

## Support

For issues or questions:
1. Review the test examples in `tests/` directory
2. Check AWS ALB documentation
3. Verify all prerequisites are met
4. Ensure Terraform and AWS provider versions are correct

---

**Summary:** This is a powerful and feature-rich Terraform module for AWS Load Balancers, but it requires customization and proper AWS infrastructure before it can be used in your account. Make sure to review and modify all account-specific configurations before deploying.

