data "aws_lb" "main" {
  count = "${var.create && var.load_balancing_enabled ? 1 : 0}"
  arn   = "${local.lb_arn}"
}

# locals {
#   # Validate the record type by looking up the map with valid record types
#   route53_record_type = "${lookup(var.allowed_record_types,local.route53_record_type, "NONE")}"
# }

## Route53 DNS Record
resource "aws_route53_record" "record" {
  count      = "${var.create && var.load_balancing_enabled && local.route53_record_type == "CNAME"  ? 1 : 0 }"
  zone_id    = "${local.route53_zone_id}"
  name       = "${var.route53_name}"
  type       = "CNAME"
  ttl        = "300"
  records    = ["${data.aws_lb.main.dns_name}"]
  depends_on = ["data.aws_lb.main", "null_resource.lb_depend"]
}

## Route53 DNS Record
resource "aws_route53_record" "record_alias_a" {
  count   = "${var.create && var.load_balancing_enabled && local.route53_record_type == "ALIAS" ? 1 : 0 }"
  zone_id = "${local.route53_zone_id}"
  name    = "${var.route53_name}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.main.dns_name}"
    zone_id                = "${data.aws_lb.main.zone_id}"
    evaluate_target_health = false
  }

  # When all records in a group have weight set to 0, traffic is routed to all resources with equal probability
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-weighted-alias.html#rrsets-values-weighted-alias-weight
  weighted_routing_policy {
    weight = 0
  }

  set_identifier = "${local.route53_record_identifier}"
  depends_on     = ["data.aws_lb.main", "null_resource.lb_depend"]
}

##
## aws_lb_target_group inside the ECS Task will be created when the service is not the default forwarding service
## It will not be created when the service is not attached to a load balancer like a worker
resource "aws_lb_target_group" "service_alb" {
  count                = "${var.create && var.load_balancing_enabled && local.tg_arn == ""&& local.load_balancer_type == "application"  ? 1 : 0 }"
  name                 = "${var.cluster_name}-${var.name}"
  port                 = "${local.tg_port}"
  protocol             = "${local.tg_protocol}"
  vpc_id               = "${local.lb_vpc_id}"
  target_type          = "${var.target_type}"
  deregistration_delay = "${local.deregistration_delay}"

  health_check {
    protocol            = "${local.tg_protocol}"
    path                = "${local.health_uri}"
    unhealthy_threshold = "${local.unhealthy_threshold}"
  }

  tags       = "${local.tags}"
  depends_on = ["data.aws_lb.main", "null_resource.lb_depend"]
}

# Network service load_balancer_type
##
## aws_lb_target_group inside the ECS Task will be created when the service is not the default forwarding service
## It will not be created when the service is not attached to a load balancer like a worker
resource "aws_lb_target_group" "service_nlb" {
  count                = "${var.create && var.load_balancing_enabled && local.tg_arn == "" && local.load_balancer_type == "network" ? 1 : 0 }"
  name                 = "${var.cluster_name}-${var.name}"
  port                 = "${local.tg_port}"
  protocol             = "${local.tg_protocol}"
  vpc_id               = "${local.lb_vpc_id}"
  target_type          = "${var.target_type}"
  deregistration_delay = "${local.deregistration_delay}"

  health_check {
    protocol            = "${local.tg_protocol}"
    unhealthy_threshold = "${local.unhealthy_threshold}"
  }

  tags       = "${local.tags}"
  depends_on = ["data.aws_lb.main", "null_resource.lb_depend"]
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
sdfsdf resource "aws_lb_listener_rule" "host_based_routing" {
  count = "${var.create && var.load_balancing_enabled && local.route53_record_type != "NONE"  && local.load_balancer_type == "application" ? 1 : 0 }"

  listener_arn = "${local.lb_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${join("",concat(list(local.tg_arn),aws_lb_target_group.service_alb.*.arn))}"
  }

  condition {
    field = "host-header"

    values = ["${local.route53_record_type == "CNAME" ? 
       join("",aws_route53_record.record.*.fqdn)
       :
       join("",aws_route53_record.record_alias_a.*.fqdn)
       }"]
  }

  depends_on = ["data.aws_lb.main", "null_resource.lb_depend", "aws_lb_target_group.service_alb"]
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_ssl" {
  count = "${var.create && var.load_balancing_enabled && local.route53_record_type != "NONE" && local.load_balancer_type == "application" ? 1 : 0 }"

  listener_arn = "${local.lb_listener_arn_https}"

  action {
    type             = "forward"
    target_group_arn = "${join("",concat(list(local.tg_arn),aws_lb_target_group.service_alb.*.arn))}"
  }

  condition {
    field = "host-header"

    values = ["${local.route53_record_type == "CNAME" ? 
       join("",aws_route53_record.record.*.fqdn)
       :
       join("",aws_route53_record.record_alias_a.*.fqdn)
       }"]
  }

  depends_on = ["data.aws_lb.main", "null_resource.lb_depend", "aws_lb_target_group.service_alb"]
}

data "template_file" "custom_listen_host" {
  count = "${length(var.custom_listen_hosts)}"

  template = "$${listen_host}"

  vars {
    listen_host = "${var.custom_listen_hosts[count.index]}"
  }
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_custom_listen_host" {
  count = "${var.create && var.load_balancing_enabled && local.load_balancer_type == "application" ? length(var.custom_listen_hosts) : 0 }"

  listener_arn = "${local.lb_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${join("",concat(list(local.tg_arn),aws_lb_target_group.service_alb.*.arn))}"
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.custom_listen_host.*.rendered[count.index]}"]
  }

  # depends_on = ["data.aws_lb.main", "null_resource.lb_depend"]
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_ssl_custom_listen_host" {
  count = "${var.create && var.load_balancing_enabled && local.load_balancer_type == "application" ? length(var.custom_listen_hosts) : 0 }"

  listener_arn = "${local.lb_listener_arn_https}"

  action {
    type             = "forward"
    target_group_arn = "${join("",concat(list(local.tg_arn),aws_lb_target_group.service_alb.*.arn))}"
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.custom_listen_host.*.rendered[count.index]}"]
  }

  depends_on = ["data.aws_lb.main", "null_resource.lb_depend"]
}
