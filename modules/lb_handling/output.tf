output "lb_target_group_arn" {
  value = "" // "${format("%v", local.load_balancer_type == "application" ? local.alb_target_group_arn : local.nlb_target_group_arn)}"
}

output "lb_target_group_arn_suffix" {
  value = "" //"${format("%v",local.load_balancer_type == "application" ? local.alb_target_group_arn_suffix : local.nlb_target_group_arn_suffix)}"
}

output "lb_arn_suffix" {
  value = "${join("", data.aws_lb.main.*.arn_suffix)}"
}

# This is an output the ecs_service depends on. This to make sure the target_group is attached to an alb before adding to a service. The actual content is useless
output "aws_lb_listener_rules" {
  value = ["${concat(aws_lb_listener_rule.host_based_routing.*.arn,aws_lb_listener_rule.host_based_routing_custom_listen_host.*.arn, list())}"]
}

output "load_balancer_type" {
  value = "${local.load_balancer_type}"
}
