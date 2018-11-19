data "aws_lb" "main" {
  count = "${var.create ? 1 : 0}"
  arn   = "${local.lb_arn}"
}

# locals {
#   # Validate the record type by looking up the map with valid record types
#   route53_record_type = "${lookup(var.allowed_record_types,local.route53_record_type, "NONE")}"
# }

## Route53 DNS Record
resource "aws_route53_record" "record" {
  count      = "${var.create && local.route53_record_type == "CNAME"  ? 1 : 0 }"
  zone_id    = "${var.route53_zone_id}"
  name       = "${var.route53_name}"
  type       = "CNAME"
  ttl        = "300"
  records    = ["${data.aws_lb.main.dns_name}"]
  depends_on = ["data.aws_lb.main", "null_resource.alb_depend"]
}

## Route53 DNS Record
resource "aws_route53_record" "record_alias_a" {
  count   = "${var.create && local.route53_record_type == "ALIAS" ? 1 : 0 }"
  zone_id = "${var.route53_zone_id}"
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

  set_identifier = "${var.route53_record_identifier}"
  depends_on     = ["data.aws_lb.main", "null_resource.alb_depend"]
}

##
## aws_lb_target_group inside the ECS Task will be created when the service is not the default forwarding service
## It will not be created when the service is not attached to a load balancer like a worker
resource "aws_lb_target_group" "service" {
  count                = "${var.create && var.lb_target_group_arn == "" ? 1 : 0 }"
  name                 = "${var.cluster_name}-${var.name}"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = "${var.lb_vpc_id}"
  target_type          = "${var.target_type}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    path                = "${var.health_uri}"
    unhealthy_threshold = "${var.unhealthy_threshold}"
  }

  tags       = "${local.tags}"
  depends_on = ["data.aws_lb.main", "null_resource.alb_depend"]
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing" {
  count = "${var.create && local.route53_record_type != "NONE" ? 1 : 0 }"

  listener_arn = "${var.lb_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${join("",concat(list(var.lb_target_group_arn),aws_lb_target_group.service.*.arn))}"
  }

  condition {
    field = "host-header"

    values = ["${local.route53_record_type == "CNAME" ? 
       join("",aws_route53_record.record.*.fqdn)
       :
       join("",aws_route53_record.record_alias_a.*.fqdn)
       }"]
  }

  depends_on = ["data.aws_lb.main", "null_resource.alb_depend"]
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_ssl" {
  count = "${var.create && local.route53_record_type != "NONE" ? 1 : 0 }"

  listener_arn = "${var.lb_listener_arn_https}"

  action {
    type             = "forward"
    target_group_arn = "${join("",concat(list(var.lb_target_group_arn),aws_lb_target_group.service.*.arn))}"
  }

  condition {
    field = "host-header"

    values = ["${local.route53_record_type == "CNAME" ? 
       join("",aws_route53_record.record.*.fqdn)
       :
       join("",aws_route53_record.record_alias_a.*.fqdn)
       }"]
  }

  depends_on = ["data.aws_lb.main", "null_resource.alb_depend"]
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
  count = "${var.create ? length(var.custom_listen_hosts) : 0 }"

  listener_arn = "${var.lb_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${join("",concat(list(var.lb_target_group_arn),aws_lb_target_group.service.*.arn))}"
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.custom_listen_host.*.rendered[count.index]}"]
  }

  depends_on = ["data.aws_lb.main", "null_resource.alb_depend"]
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_ssl_custom_listen_host" {
  count = "${var.create ? length(var.custom_listen_hosts) : 0 }"

  listener_arn = "${var.lb_listener_arn_https}"

  action {
    type             = "forward"
    target_group_arn = "${join("",concat(list(var.lb_target_group_arn),aws_lb_target_group.service.*.arn))}"
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.custom_listen_host.*.rendered[count.index]}"]
  }

  depends_on = ["data.aws_lb.main", "null_resource.alb_depend"]
}

# This is an output the ecs_service depends on. This to make sure the target_group is attached to an alb before adding to a service. The actual content is useless
output "aws_lb_listener_rules" {
  value = ["${concat(aws_lb_listener_rule.host_based_routing.*.arn,aws_lb_listener_rule.host_based_routing_custom_listen_host.*.arn, list())}"]
}
