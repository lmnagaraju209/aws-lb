variable "region" {
  type        = string
  description = "(Optional) The region to perform the run against."
  default     = "us-east-2"
}

variable "vpc_id" {
  type        = string
  description = "(Required) ID of the VPC where this stack should be deployed."
}

variable "project" {
  type        = string
  description = "(Required) The project that these resources are associated with.  Will be used for tagging purposes."
}

variable "environment" {
  type        = string
  description = "(Required) The environment [test/dev/prod/etc.] to deploy to."
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Mapping of additional tags."
  default     = {}
}

####
#### Module Specific Variables
####
variable "load_balancer_type" {
  description = "The type of load balancer to create. Possible values are application or network."
  type        = string
  default     = "application"
}

variable "dns_records" {
  type = list(object({
    name                   = string
    zone_name              = string
    type                   = optional(string, "A")
    set_identifier         = optional(string, "default")
    evaluate_target_health = optional(bool, true)
    weighted_routing_policy = optional(map(string), {
      weight = 100
    })
    latency_routing_policy     = optional(map(string), {})
    geolocation_routing_policy = optional(map(string), {})
    failover_routing_policy    = optional(map(string), {})
  }))
  description = "(Required) A list of DNS record maps of the zone_id, name, and type that should target the primary load balancer."
}


variable "subnet_tags" {
  type = object({
    tier        = string
    environment = string
  })
  default = {
    tier        = "private"
    environment = "test"
  }
  description = "(Optional) A map containing tags identifying the ALB subnets.  Must include: tier - string, environment - string. "
}

variable "security_group_name" {
  description = "Name to use on security group created"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group created"
  type        = string
  default     = null
}

variable "security_group_ingress_rules" {
  description = "Security group ingress rules to add to the security group created"
  type        = any
  default     = {}
}

variable "security_group_egress_rules" {
  description = "Security group egress rules to add to the security group created"
  type        = any
  default     = {}
}

variable "security_group_tags" {
  description = "A map of additional tags to add to the security group created"
  type        = map(string)
  default     = {}
}

variable "access_logs" {
  type = object({
    enabled = bool
    bucket  = string
    prefix  = string
  })
  description = "(Optional) Controls if the ALB will log requests to S3."
  default     = null
}

variable "idle_timeout" {
  type        = number
  description = "(Optional) The time in seconds that the connection is allowed to be idle."
  default     = 120
}

variable "enable_xff_client_port" {
  description = "Indicates whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer in application load balancers."
  type        = bool
  default     = false
}

variable "waf_enabled" {
  type        = bool
  description = "(Optional) Enable the WAF for this ALB."
  default     = true
}

variable "enable_deletion_protection" {
  type        = bool
  description = "(Optional) If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to true."
  default     = true
}

variable "waf_trusted_access_only" {
  type        = bool
  description = "(Optional) If true, associate the lb with the WAF defined by waf_web_acl_id_trusted. Else, use waf_web_acl_id_private.  No effect if waf_enabled is false."
  default     = false
}

variable "waf_version" {
  type        = number
  description = "(Optional) The version of AWS WAF to use.  Classic/Regional = 1, v2 = 2.  This will eventually be deprecated when we're fully migrated to v2."
  default     = 1
}

variable "waf_web_acl_arn_v2" {
  type        = string
  description = "(Optional) WAFv2 Web ACL ARN to associate with the ALB when waf_version = 2 and waf_enabled = true."
  default     = null
}

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

variable "listeners" {
  description = "Map of listener configurations to create"
  type        = any
  default     = {}
}

variable "target_groups" {
  description = "A list of maps containing key/value pairs that define the target groups to be created. Order of these maps is important and the index of these are to be referenced in listener definitions. Required key/values: name, backend_protocol, backend_port"
  type = map(object({
    name                              = string
    create_attachment                 = optional(bool, true)
    target_type                       = optional(string, "instance")
    protocol                          = optional(string, "HTTPS")
    protocol_version                  = optional(string, "HTTP1")
    backend_port                      = optional(string, 443)
    deregistration_delay              = optional(number, 300)
    load_balancing_cross_zone_enabled = optional(bool, true)
    target_id                         = optional(string)
    port                              = optional(number, 443)
    availability_zone                 = optional(string, null)
    health_check = optional(object({
      enabled             = optional(bool, true)
      protocol            = optional(string, "HTTPS")
      port                = optional(string, "traffic-port")
      path                = optional(string, "/")
      matcher             = optional(string, "200")
      interval            = optional(number, 30)
      healthy_threshold   = optional(number, 5)
      unhealthy_threshold = optional(number, 2)
      timeout             = optional(number, 5)
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
}
