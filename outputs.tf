output "ecs_taskrole_arn" {
  value = module.iam.ecs_taskrole_arn
}

output "ecs_taskrole_name" {
  value = module.iam.ecs_taskrole_name
}

output "lb_target_group_arn" {
  value = module.alb_handling.lb_target_group_arn
}

output "task_execution_role_arn" {
  value = module.iam.ecs_task_execution_role_arn
}

output "task_execution_role_name" {
  value = module.iam.ecs_task_execution_role_name
}

output "aws_ecs_task_definition_arn" {
  value = module.ecs_task_definition_selector.selected_task_definition_for_deployment
}

output "aws_ecs_task_definition_family" {
  value = module.ecs_task_definition.aws_ecs_task_definition_family
}

output "has_changed" {
  value = module.ecs_task_definition_selector.has_changed
}

