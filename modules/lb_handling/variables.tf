## This sub-module manages everything regarding the connection of an ecs service to an Application Load Balancer

# Create defines if we need to create resources inside this module
variable "create" {
  default = true
}

resource "null_resource" "lb_depend" {
  triggers {
    arn      = "${local.lb_arn}"
    listener = "${local.lb_listener_arn}"
    target   = "${local.tg_arn}"
    type     = "${local.load_balancer_type}"
  }
}

variable "load_balancing_properties" {
  type = "map"
}

variable "load_balancing_enabled" {
  default = "false"
}

###
locals {
  # lb_vpc_id sets the VPC ID of where the LB resides
  lb_vpc_id = "${lookup(var.load_balancing_properties,"lb_vpc_id")}"

  # lb_arn defines the arn of the ALB
  lb_arn = "${lookup(var.load_balancing_properties,"lb_arn")}"

  load_balancer_type = "${lookup(var.load_balancing_properties,"load_balancer_type")}"

  # lb_listener_arn is the arn of the listener ( HTTP )
  lb_listener_arn = "${lookup(var.load_balancing_properties,"lb_listener_arn")}"

  # lb_listener_arn_https is the arn of the listener ( HTTPS )
  lb_listener_arn_https = "${lookup(var.load_balancing_properties,"lb_listener_arn_https")}"

  # unhealthy_threshold defines the threashold for the target_group after which a service is seen as unhealthy.
  unhealthy_threshold = "${lookup(var.load_balancing_properties,"unhealthy_threshold")}"

  # if https_enabled is true, listener rules are made for the ssl listener
  https_enabled = "${lookup(var.load_balancing_properties,"https_enabled")}"

  # Sets the deregistration_delay for the targetgroup
  deregistration_delay = "${lookup(var.load_balancing_properties,"deregistration_delay")}"

  # route53_record_type sets the record type of the route53 record, can be ALIAS, CNAME or NONE,  defaults to CNAME
  # In case of NONE no record will be made
  route53_record_type = "${lookup(var.load_balancing_properties,"route53_record_type")}"

  # Sets the zone in which the sub-domain will be added for this service
  route53_zone_id = "${lookup(var.load_balancing_properties,"route53_zone_id", "")}"

  # route53_a_record_identifier sets the identifier of the weighted Alias A record
  route53_record_identifier = "${lookup(var.load_balancing_properties,"route53_record_identifier")}"
  route53_name              = "${lookup(var.load_balancing_properties,"route53_name", var.route53_name)}"
  local_tg_name             = "${lookup(var.load_balancing_properties,"tg_name", "")}"
  tg_name                   = "${substr(local.local_tg_name == "" ? format("%v-%v", var.cluster_name, var.name) : local.local_tg_name, 0, min(31, length(local.local_tg_name))) }"

  # health_uri defines which health-check uri the target group needs to check on for health_check
  health_uri = "${lookup(var.load_balancing_properties,"health_uri")}"

  tg_port     = "${lookup(var.load_balancing_properties,"tg_port")}"
  tg_arn      = "${lookup(var.load_balancing_properties,"tg_arn")}"
  tg_protocol = "${lookup(var.load_balancing_properties,"tg_protocol")}"
}

###

variable "cluster_name" {
  default = ""
}

variable "name" {
  default = ""
}

# target_type is the alb_target_group target, in case of EC2 it's instance, in case of FARGATE it's IP
variable "target_type" {
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

# the custom_listen_hosts will be added as a host route rule as aws_lb_listener_rule to the given service e.g. www.domain.com -> Service
variable "custom_listen_hosts" {
  type    = "list"
  default = []
}

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
