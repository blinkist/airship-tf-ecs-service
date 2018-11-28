data "aws_lb" "main" {
  count = "${var.create ? 1 : 0}"
  arn   = "${var.lb_arn}"
}

locals {
  # Validate the load_balancing_type type by looking up the map with var.allowed_load_balancing_types
  validate_load_balancing_type = "${lookup(var.allowed_load_balancing_types,var.load_balancing_type)}"

  # Validate the record type by looking up the map with valid record types
  route53_record_type = "${lookup(var.allowed_record_types,var.route53_record_type)}"

  # We limit the target group name to a length of 32
  tg_name = "${format("%.32s",format("%v-%v", var.cluster_name, var.name))}"
}

## Route53 DNS Record
resource "aws_route53_record" "record" {
  count   = "${(var.create && local.route53_record_type == "CNAME" ) ? 1 : 0 }"
  zone_id = "${var.route53_zone_id}"
  name    = "${var.route53_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.aws_lb.main.dns_name}"]
}

## Route53 DNS Record
resource "aws_route53_record" "record_alias_a" {
  count   = "${(var.create && local.route53_record_type == "ALIAS") ? 1 : 0 }"
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
}

# Network service load_balancer_type
resource "aws_lb_target_group" "service_nlb" {
  count                = "${var.create && var.load_balancing_type == "NETWORK" ? 1 : 0 }"
  name                 = "${local.tg_name}"
  port                 = "${var.target_group_port}"
  protocol             = "TCP"
  vpc_id               = "${var.lb_vpc_id}"
  target_type          = "${var.target_type}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    protocol            = "${var.health_protocol}"
    path                = "${var.health_protocol == "HTTP" || var.health_protocol == "HTTPS" ? var.health_uri : ""}"
    unhealthy_threshold = "${var.unhealthy_threshold}"
  }

  tags = "${local.tags}"
}

resource "aws_lb_listener" "nlb_listener" {
  count             = "${var.create && var.load_balancing_type == "NETWORK" ? 1 : 0 }"
  load_balancer_arn = "${var.lb_arn}"
  port              = "${var.nlb_listener_port}"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.service_nlb.arn}"
    type             = "forward"
  }
}

##
## aws_lb_target_group inside the ECS Task will be created when the service is not the default forwarding service
## It will not be created when the service is not attached to a load balancer like a worker
resource "aws_lb_target_group" "service" {
  count                = "${var.create && var.load_balancing_type == "APPLICATION" ? 1 : 0 }"
  name                 = "${local.tg_name}"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = "${var.lb_vpc_id}"
  target_type          = "${var.target_type}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    path                = "${var.health_uri}"
    unhealthy_threshold = "${var.unhealthy_threshold}"
  }
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing" {
  count = "${var.create && var.load_balancing_type == "APPLICATION" && ! var.redirect_http_to_https && local.route53_record_type != "NONE" ? 1 : 0 }"

  listener_arn = "${var.lb_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service.arn}"
  }

  condition {
    field = "host-header"

    values = ["${local.route53_record_type == "CNAME" ? 
       join("",aws_route53_record.record.*.fqdn)
       :
       join("",aws_route53_record.record_alias_a.*.fqdn)
       }"]
  }
}

##
## aws_lb_listener_rule which redirects http to https
resource "aws_lb_listener_rule" "host_based_routing_redirect_to_https" {
  count = "${var.create && var.load_balancing_type == "APPLICATION" && var.redirect_http_to_https && local.route53_record_type != "NONE" ? 1 : 0 }"

  listener_arn = "${var.lb_listener_arn}"

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    field = "host-header"

    values = ["${local.route53_record_type == "CNAME" ?
       join("",aws_route53_record.record.*.fqdn)
       :
       join("",aws_route53_record.record_alias_a.*.fqdn)
       }"]
  }
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_ssl" {
  count = "${var.create && var.load_balancing_type == "APPLICATION" && ! var.cognito_auth_enabled && local.route53_record_type != "NONE" ? 1 : 0 }"

  listener_arn = "${var.lb_listener_arn_https}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service.arn}"
  }

  condition {
    field = "host-header"

    values = ["${local.route53_record_type == "CNAME" ?
       join("",aws_route53_record.record.*.fqdn)
       :
       join("",aws_route53_record.record_alias_a.*.fqdn)
       }"]
  }
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_ssl_cognito_auth" {
  count = "${var.create && var.load_balancing_type == "APPLICATION" && var.cognito_auth_enabled && local.route53_record_type != "NONE" ? 1 : 0 }"

  listener_arn = "${var.lb_listener_arn_https}"

  action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = "${var.cognito_user_pool_arn}"
      user_pool_client_id = "${var.cognito_user_pool_client_id}"
      user_pool_domain    = "${var.cognito_user_pool_domain}"
    }
  }

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service.arn}"
  }

  condition {
    field = "host-header"

    values = ["${local.route53_record_type == "CNAME" ?
       join("",aws_route53_record.record.*.fqdn)
       :
       join("",aws_route53_record.record_alias_a.*.fqdn)
       }"]
  }
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
  count = "${var.create && var.load_balancing_type == "APPLICATION" && ! var.redirect_http_to_https ? length(var.custom_listen_hosts) : 0 }"

  listener_arn = "${var.lb_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.custom_listen_host.*.rendered[count.index]}"]
  }
}

##
## aws_lb_listener_rule which redirects http to https for the custom listen hosts
resource "aws_lb_listener_rule" "host_based_routing_custom_listen_host_redirect_to_https" {
  count = "${var.create && var.load_balancing_type == "APPLICATION" && var.redirect_http_to_https ? length(var.custom_listen_hosts) : 0 }"

  listener_arn = "${var.lb_listener_arn}"

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.custom_listen_host.*.rendered[count.index]}"]
  }
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_ssl_custom_listen_host" {
  count = "${var.create && var.load_balancing_type == "APPLICATION" && ! var.cognito_auth_enabled ? length(var.custom_listen_hosts) : 0 }"

  listener_arn = "${var.lb_listener_arn_https}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.custom_listen_host.*.rendered[count.index]}"]
  }
}

##
## An aws_lb_listener_rule will only be created when a service has a load balancer attached
resource "aws_lb_listener_rule" "host_based_routing_ssl_custom_listen_host_cognito_auth" {
  count = "${var.create && var.load_balancing_type == "APPLICATION" && var.cognito_auth_enabled ? length(var.custom_listen_hosts) : 0 }"

  listener_arn = "${var.lb_listener_arn_https}"

  action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = "${var.cognito_user_pool_arn}"
      user_pool_client_id = "${var.cognito_user_pool_client_id}"
      user_pool_domain    = "${var.cognito_user_pool_domain}"
    }
  }

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.custom_listen_host.*.rendered[count.index]}"]
  }
}
