# The arn of the task definition
output "aws_ecs_task_definition_arn" {
  value = try(aws_ecs_task_definition.app.0.arn,
    aws_ecs_task_definition.app_with_docker_volume.0.arn,
    "")
}

output "aws_ecs_task_definition_family" {
  value = try(aws_ecs_task_definition.app.0.family,
    aws_ecs_task_definition.app_with_docker_volume.0.family,
    "")
}

output "aws_ecs_task_definition_revision" {
  value = try(aws_ecs_task_definition.app.0.revision,
    aws_ecs_task_definition.app_with_docker_volume.0.revision,
    "")
}

