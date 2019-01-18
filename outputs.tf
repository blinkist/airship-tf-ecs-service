output "ecs_taskrole_arn" {
  value = "${module.iam.ecs_taskrole_arn}"
}

output "ecs_taskrole_name" {
  value = "${module.iam.ecs_taskrole_name}"
}

output "lb_target_group_arn" {
  value = "${module.alb_handling.lb_target_group_arn}"
}

output "task execution role arn" {
  value = "${module.iam.ecs_task_execution_role_arn}"
}

output "aws_ecs_task_definition_arn" {
  value = "${module.ecs_task_definition.aws_ecs_task_definition_arn}"
}

output "aws_ecs_task_definition_family" {
  value = "${module.ecs_task_definition.aws_ecs_task_definition_family}"
}
