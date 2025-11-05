data "aws_subnets" "alb" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = var.subnet_tags
}

#TODO: wafv2
# set var.web_acl_arn in alb module.

resource "aws_wafregional_web_acl_association" "alb" {
  count = local.waf_enabled && var.waf_version == 1 ? 1 : 0

  resource_arn = module.alb.id
  web_acl_id   = local.waf_web_acl_id
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  load_balancer_type = var.load_balancer_type
  internal           = local.internal

  vpc_id  = var.vpc_id
  subnets = data.aws_subnets.alb.ids

  security_group_name          = local.name
  security_group_description   = "Load balancer rules for ${local.name}"
  security_group_ingress_rules = var.security_group_ingress_rules
  security_group_egress_rules  = var.security_group_egress_rules
  security_group_tags          = {}

  listeners              = var.listeners
  target_groups          = var.target_groups
  idle_timeout           = var.idle_timeout
  enable_xff_client_port = var.enable_xff_client_port

  access_logs                = var.access_logs != null ? var.access_logs : local.access_logs_default
  enable_deletion_protection = var.enable_deletion_protection

  tags = local.tags
}
