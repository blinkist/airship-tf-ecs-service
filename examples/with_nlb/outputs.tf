output "ecs_taskrole_arn" {
  value = "${module.nlb_service.ecs_taskrole_arn}"
}

output "ecs_taskrole_name" {
  value = "${module.nlb_service.ecs_taskrole_name}"
}

output "lb_target_group_arn" {
  value = "${module.nlb_service.lb_target_group_arn}"
}

output "task_execution_role_arn" {
  value = "${module.nlb_service.task_execution_role_arn}"
}

output "aws_ecs_task_definition_arn" {
  value = "${module.nlb_service.aws_ecs_task_definition_arn}"
}

output "aws_ecs_task_definition_family" {
  value = "${module.nlb_service.aws_ecs_task_definition_family}"
}

output "lb_address" {
  value = "${aws_lb.this.dns_name}"
}

output "has_changed" {
  value = "${module.nlb_service.has_changed}"
}

output "cluster_id" {
  value = "${module.ecs_cluster.cluster_id}"
}

output "zone_id" {
  value = "${aws_route53_zone.this.zone_id}"
}

output "lb_arn" {
  value = "${aws_lb.this.arn}"
}
