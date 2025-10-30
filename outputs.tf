################################################################################
# DNS
################################################################################
output "aws_route53_records_public" {
  description = "The public Route53 records created for this load balancer."
  value       = [ for record in aws_route53_record.public : record.fqdn ]
}

output "aws_route53_records_private" {
  description = "The private Route53 records created for this load balancer."
  value       = [ for record in aws_route53_record.private : record.fqdn ]
}

################################################################################
# LB
################################################################################
output "lb_arn" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.alb.arn
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.alb.dns_name
}

output "lb_internal" {
  description = "Is this load balancer internal?  Internet-facing if false."
  value       = local.internal
}

################################################################################
# Listener(s)
################################################################################

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = module.alb.listeners
}

output "listener_rules" {
  description = "Map of listeners rules created and their attributes"
  value       = module.alb.listener_rules
}

################################################################################
# Target Group(s)
################################################################################

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.alb.target_groups
}

################################################################################
# Security Group
################################################################################
output "security_group_id" {
  description = "ID of the security group"
  value       = module.alb.security_group_id
}

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = module.alb.security_group_arn
}

################################################################################
# WAF
################################################################################
output "waf_enabled" {
  description = "Is the WAF enabled?"
  value       = local.waf_enabled
}

output "waf_web_acl_id" {
  description = "WAF ARN to associate this LB with."
  value       = local.waf_web_acl_id
}
