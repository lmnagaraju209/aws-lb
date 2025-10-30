locals {
  name = "${var.project}-${var.environment}"

  # Must explicitly bw in a public subnet to be a public load balancer
  internal = var.subnet_tags.tier != "public" ? true : false

  waf_enabled    = local.internal != true && var.waf_enabled
  waf_web_acl_id = var.waf_trusted_access_only ? var.waf_web_acl_id_trusted : var.waf_web_acl_id_public


  log_bucket_name = "vci-loadbalancer-logs-${var.region}"

  access_logs_default = {
    enabled = true
    bucket  = local.log_bucket_name
    prefix  = local.name
  }

  tags = merge({
    Name              = local.name
    terraform-managed = true
    environment       = var.environment
    project           = var.project
  }, var.tags)
}
