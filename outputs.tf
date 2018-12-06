output "ecs_taskrole_arn" {
  value = "${module.iam.ecs_taskrole_arn}"
}

output "ecs_taskrole_name" {
  value = "${module.iam.ecs_taskrole_name}"
}

output "lb_target_group_arn" {
  value = "${module.lb_handling.lb_target_group_arn}"
}

output "lb_target_group_arn_suffix" {
  value = "${module.lb_handling.lb_target_group_arn_suffix}"
}

output "lb_arn_suffix" {
  value = "${module.lb_handling.lb_arn_suffix}"
}

output "public_dns_address" {
  value = "${module.lb_handling.public_dns_address}"
}

output "load_balancer_type" {
  value = "${module.lb_handling.load_balancer_type}"
}

output "service_discovery_container_name" {
  value = "${module.ecs_service.service_discovery_container_name}"
}

output "ecs_service_name" {
  value = "${module.ecs_service.ecs_service_name}"
}

output "ecs_task_name" {
  value = "${module.ecs_task_definition.aws_ecs_task_definition_family}"
}

output "ecs_cluster_name" {
  value = "${local.ecs_cluster_name}"
}

output "container_definition" {
  value = "${module.container_definition.json}"
}
