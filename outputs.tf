output "ecs_taskrole_arn" {
  value = "${module.iam.ecs_taskrole_arn}"
}

output "ecs_taskrole_name" {
  value = "${module.iam.ecs_taskrole_name}"
}

output "lb_target_group_arn" {
  value = "${module.alb_handling.lb_target_group_arn}"
}

output "service_discovery_container_name" {
  value = "${module.ecs_service.service_discovery_container_name}"
}

output "ecs_service_name" {
  value = "${module.ecs_service.ecs_service_name}"
}

output "ecs_task_name" {
  value = "${var.name}"
}

output "ecs_cluster_name" {
  value = "${local.ecs_cluster_name}"
}

output "container_definition" {
  value = "${module.container_definition.json}"
}
