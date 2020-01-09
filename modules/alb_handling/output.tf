output "lb_target_group_arn" {
  value = element(
    concat(
      aws_lb_target_group.service.*.arn,
      aws_lb_target_group.service_nlb.*.arn,
      [""],
    ),
    0,
  )
}

# This is an output the ecs_service depends on. This to make sure the target_group is attached to an alb before adding to a service. The actual content is useless
output "aws_lb_listener_rules" {
  value = concat(
    aws_lb_listener_rule.host_based_routing.*.arn,
    aws_lb_listener_rule.host_based_routing_custom_listen_host.*.arn,
    aws_lb_listener_rule.host_based_routing_ssl_custom_listen_host_cognito_auth.*.arn,
    [],
  )
}

