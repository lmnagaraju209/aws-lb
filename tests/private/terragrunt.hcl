terraform {
  source = "../..///"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {}
EOF
}

## Removed external include; region and vpc_id are now set below in inputs.

locals {
  subnet_tier   = "private"
  project       = "aws-lb-${local.subnet_tier}"
  environment   = "tftest"
  dns_zone_name = "vtile.io"
}

inputs = {
  # Auto-read from environment (no file edits needed)
  region = get_env("AWS_REGION", "us-east-2")
  vpc_id = get_env("VPC_ID", "")

  project     = local.project
  environment = local.environment

  subnet_tags = {
    tier        = local.subnet_tier
    environment = "test"
  }

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP Internal Traffic"
      cidr_ipv4   = "10.69.0.0/16"
    },
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS Internal Traffic"
      cidr_ipv4   = "10.69.0.0/16"
    },
  }

  security_group_egress_rules = {
    autoscaling-test = {
      from_port                    = 443
      to_port                      = 443
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0df7444fe5ba5a3e8"
      description                  = "aws-ec2-autoscaling-tftest-asg-20231020175140140900000001"
    },
  }

  dns_records = [
    {
      name      = "${local.project}-${local.environment}"
      zone_name = local.dns_zone_name
      type      = "A"
    },
  ]

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
    https = {
      port                        = 443
      protocol                    = "HTTPS"
      ssl_policy                  = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      # *.versatilecredit.com
      certificate_arn             = "arn:aws:acm:us-east-1:207742269540:certificate/e8d6e560-b017-4831-b9bd-758e62247b2a"
      additional_certificate_arns = [
        # *.vtile.io
        "arn:aws:acm:us-east-1:207742269540:certificate/acb0f4fb-5780-4624-a650-ad9ed9f5d8f2",
      ]
      # Default Listener Action
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = 404
      }

      rules = {
        aws-ec2-autoscaling-tftest = {
          priority = 10
          conditions = [{
            host_header = {
              values = [
                "${local.project}-${local.environment}.${local.dns_zone_name}",
              ]
            },
          }]
          actions = [{
            type = "forward"
            target_group_key = "aws-ec2-autoscaling-tftest"
          },]
        }
      }
    }
  }

  target_groups = {
    ec2 = {
      name         = "${local.project}-${local.environment}-con"
      target_type  = "instance"
      protocol     = "HTTPS"
      port         = 443
      health_check = {
        path = "/internal/alive"
      }
      target_id = "i-0de9bb9330dd043c2"
      tags = {
        project     = local.project
        environment = local.environment
      }
    },
    aws-ec2-autoscaling-tftest = {
      name              = "${local.project}-${local.environment}-asg"
      create_attachment = false # Do not create a target group attachment for auto-scaling
      protocol          = "HTTPS"
      port              = 443
      health_check      = {
        path = "/internal/alive"
      }
      tags = {
        project     = local.project
        environment = local.environment
      }
    },
  }

  tags = {
    lead = "terraform"
  }

  enable_deletion_protection = false
}
