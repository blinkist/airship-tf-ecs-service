## This sub-module manages everything regarding the connection of an ecs service to an Application Load Balancer

# Create defines if we need to create resources inside this module
variable "create" {
  default = true
}

# The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. 
variable "deregistration_delay" {}

# unhealthy_threshold defines the threashold for the target_group after which a service is seen as unhealthy.
variable "unhealthy_threshold" {}

variable "cluster_name" {
  default = ""
}

variable "name" {
  default = ""
}

# lb_arn sets the arn of the ALB
variable "lb_arn" {
  default = ""
}

# lb_listener_arn is the arn of the lb_listener ( HTTP )
variable "lb_listener_arn" {
  default = ""
}

# lb_listener_arn is the arn of the lb_listener ( HTTPS )
variable "lb_listener_arn_https" {
  default = ""
}

# target_type is the alb_target_group target, in case of EC2 it's instance, in case of FARGATE it's IP
variable "target_type" {
  default = ""
}

# The VPC ID of the VPC where the ALB is residing
variable "lb_vpc_id" {
  default = ""
}

# health_uri defines sets which health-check uri the target group needs to check on for health_check
variable "health_uri" {
  default = ""
}

# Route53 Zone to add subdomain to. 
# Example:
# 
# zone-id domain = prod.example.com
# 
# Final created subdomain will be [route53_name].prod.example.com
# 
variable "route53_zone_id" {
  default = ""
}

variable "route53_name" {
  default = ""
}

# Small Lookup map to validate route53_record_type
variable "allowed_record_types" {
  default = {
    ALIAS = "ALIAS"
    CNAME = "CNAME"
    NONE  = "NONE"
  }
}

# route53_record_type, one of the allowed values of the map allowed_record_types
variable "route53_record_type" {}

# the custom_listen_hosts will be added as a host route rule as aws_lb_listener_rule to the given service e.g. www.domain.com -> Service
variable "custom_listen_hosts" {
  type    = "list"
  default = []
}

# When https is enabled we create https listener_rules
variable "https_enabled" {
  default = true
}

# route53_record_identifier, sets the identifier for the route53 record in case the record type is ALIAS 
variable "route53_record_identifier" {}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = "map"
  default     = {}
}

locals {
  name_map = {
    "Name" = "${var.name}"
  }

  tags = "${merge(var.tags, local.name_map)}"
}
