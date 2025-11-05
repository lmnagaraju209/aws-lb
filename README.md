# AWS Load Balancer Terraform Module

## Overview

This is a **Terraform module** that creates and manages AWS Application Load Balancers (ALB) or Network Load Balancers (NLB) with integrated features including:

- **Load Balancer Creation**: Creates ALB or NLB based on configuration
- **DNS Management**: Automatically creates Route53 DNS records (both public and private)
- **Security Groups**: Configures security groups with custom ingress/egress rules
- **WAF Integration**: Optional AWS WAF (Web Application Firewall) association
- **Target Groups**: Manages target groups for routing traffic to EC2 instances or Auto Scaling Groups
- **Listeners**: Configures HTTP/HTTPS listeners with SSL/TLS support
- **Access Logs**: Optional logging to S3 buckets
- **Health Checks**: Configurable health check settings for target groups

## What Does This Code Do?

### Main Components:

1. **Load Balancer (`main.tf`)**
   - Uses the official AWS ALB Terraform module (v9.x)
   - Creates an Application or Network Load Balancer
   - Configures it based on subnet placement (public vs private/internal)
   - Associates with WAF if configured and public-facing

2. **DNS Records (`dns.tf`)**
   - Creates Route53 A records that point to the load balancer
   - Supports both public and private hosted zones
   - Supports advanced routing policies:
     - Weighted routing
     - Latency-based routing
     - Geolocation routing
     - Failover routing

3. **Security & Access Control**
   - Creates security groups with customizable rules
   - Integrates with AWS WAF for web application protection
   - Supports WAF Classic (v1) and WAF v2

4. **Infrastructure Components**
   - Target groups for routing traffic to backend instances
   - Listeners for handling incoming requests
   - Health checks to monitor backend instance health
   - Access logging for audit and troubleshooting

## Architecture

```
Internet/VPC
    |
    v
[Load Balancer] <-- [WAF (Optional)]
    |
    +-- [Security Group]
    +-- [Listeners: HTTP/HTTPS]
    +-- [Target Groups]
    |       |
    |       v
    |   [EC2 Instances / Auto Scaling Groups]
    |
    v
[Route53 DNS Records]
    +-- Public Records
    +-- Private Records
```

## Can This Run on Any AWS Account?

### Short Answer: **No, not without modifications**

### Why Not?

This module contains **hardcoded values** specific to a particular organization:

1. **WAF ACL IDs** - Hardcoded specific WAF ACL identifiers
2. **S3 Bucket Names** - Hardcoded log bucket names with specific naming convention
3. **Certificate ARNs** - Test configurations reference specific SSL certificates
4. **Security Group IDs** - Test files reference specific security groups
5. **Instance IDs** - Test files reference specific EC2 instances
6. **VPC/Subnet Dependencies** - Expects specific VPC and subnet configurations

### What Needs to Change?

See the `CHANGES.md` file for detailed instructions on adapting this module for your AWS account.

## Prerequisites

To use this module, you need:

1. **Terraform**: Version >= 0.14
2. **AWS Provider**: Version ~> 5.0
3. **AWS Account with**:
   - VPC with subnets (public and/or private)
   - Route53 hosted zones
   - (Optional) S3 bucket for access logs
   - (Optional) SSL/TLS certificates in AWS Certificate Manager
   - (Optional) WAF ACLs configured
4. **AWS Credentials**: Configured for Terraform to access your account

## Module Inputs

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `vpc_id` | string | ID of the VPC where resources will be deployed |
| `project` | string | Project name for tagging and naming resources |
| `environment` | string | Environment name (dev/test/prod/etc.) |
| `dns_records` | list(object) | List of DNS records to create pointing to the LB |

### Important Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | string | "us-east-2" | AWS region for deployment |
| `load_balancer_type` | string | "application" | Type of LB: "application" or "network" |
| `subnet_tags` | object | tier="private", environment="test" | Tags to identify subnets for LB |
| `waf_enabled` | bool | true | Enable WAF association |
| `waf_web_acl_id_public` | string | (hardcoded) | WAF ACL ID for public LBs |
| `waf_web_acl_id_trusted` | string | (hardcoded) | WAF ACL ID for trusted access |
| `enable_deletion_protection` | bool | true | Prevent accidental deletion |
| `listeners` | map | {} | Listener configurations (HTTP/HTTPS) |
| `target_groups` | map | {} | Target group configurations |
| `security_group_ingress_rules` | any | {} | Ingress rules for security group |
| `security_group_egress_rules` | any | {} | Egress rules for security group |
| `access_logs` | object | (uses defaults) | S3 bucket configuration for logs |
| `idle_timeout` | number | 120 | Connection idle timeout in seconds |

## Module Outputs

| Output | Description |
|--------|-------------|
| `lb_arn` | ARN of the load balancer |
| `lb_dns_name` | DNS name of the load balancer |
| `lb_internal` | Whether the LB is internal or internet-facing |
| `aws_route53_records_public` | Public DNS records created |
| `aws_route53_records_private` | Private DNS records created |
| `listeners` | Map of listener configurations |
| `target_groups` | Map of target group configurations |
| `security_group_id` | Security group ID |
| `security_group_arn` | Security group ARN |
| `waf_enabled` | Whether WAF is enabled |
| `waf_web_acl_id` | WAF ACL ID associated |

## Usage Example

```hcl
module "load_balancer" {
  source = "path/to/this/module"

  # Required
  vpc_id      = "vpc-12345678"
  project     = "my-app"
  environment = "production"

  # Subnet selection
  subnet_tags = {
    tier        = "public"
    environment = "prod"
  }

  # DNS records
  dns_records = [
    {
      name      = "myapp.example.com"
      zone_name = "example.com"
      type      = "A"
    }
  ]

  # Security rules
  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all_outbound = {
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
      certificate_arn = "arn:aws:acm:region:account:certificate/xyz"
      
      # Default action
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = 404
      }
    }
  }

  # Target groups
  target_groups = {
    web_servers = {
      name     = "my-web-servers"
      port     = 443
      protocol = "HTTPS"
      health_check = {
        path = "/health"
      }
    }
  }

  # Disable WAF or provide your own ACL ID
  waf_enabled = false
  
  # Optional: Allow deletion for testing
  enable_deletion_protection = false
}
```

## Key Features Explained

### 1. Internal vs Public Load Balancers
The module automatically determines if the LB should be internal or internet-facing based on subnet tags:
- If `subnet_tags.tier == "public"` → Internet-facing LB
- Otherwise → Internal LB

### 2. WAF Integration
- WAF is automatically enabled for public-facing load balancers
- Supports both WAF Classic (v1) and WAF v2
- Two modes: "public" and "trusted" access with different ACL IDs

### 3. DNS Management
- Creates both public and private Route53 records
- Public records only created for internet-facing LBs
- Private records always created
- Supports complex routing policies

### 4. Access Logging
- Default behavior: Logs to S3 bucket `vci-loadbalancer-logs-{region}`
- Can be disabled or customized via `access_logs` variable

## Important Notes

⚠️ **Before Using This Module:**

1. Review and update all hardcoded values (see `CHANGES.md`)
2. Ensure you have the required AWS resources (VPC, subnets, certificates, etc.)
3. Test in a non-production environment first
4. Be aware of costs associated with Load Balancers, data transfer, and WAF
5. Deletion protection is enabled by default - set to `false` for testing

## Testing

The module includes test configurations in the `tests/` directory:
- `tests/public/` - Configuration for public (internet-facing) load balancer
- `tests/private/` - Configuration for internal load balancer

These tests use Terragrunt and reference a parent configuration file.

## Version History

See `CHANGELOG.md` for version history and changes.

## Support & Troubleshooting

### Common Issues:

1. **"No subnets found"** - Check that your VPC has subnets with the correct tags
2. **WAF association fails** - Verify WAF ACL exists and is in the correct region
3. **Certificate errors** - Ensure ACM certificate is in the same region as the LB
4. **Access log errors** - Verify S3 bucket exists and has proper permissions

## License

This module is intended for internal use. Consult your organization's licensing policy.

## Credits

This module uses the official AWS ALB Terraform module:
- Source: `terraform-aws-modules/alb/aws`
- Version: ~> 9.0

## Contributing

When making changes:
1. Update version in `CHANGELOG.md`
2. Test both public and private configurations
3. Update documentation as needed
4. Follow semantic versioning

