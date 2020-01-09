# The arn of the task definition
output "aws_ecs_task_definition_arn" {
  value = element(
    concat(
      aws_ecs_task_definition.app.*.arn,
      aws_ecs_task_definition.app_with_docker_volume.*.arn,
      [""],
    ),
    0,
  )
}

output "aws_ecs_task_definition_family" {
  value = element(
    concat(
      aws_ecs_task_definition.app.*.family,
      aws_ecs_task_definition.app_with_docker_volume.*.family,
      [""],
    ),
    0,
  )
}

output "aws_ecs_task_definition_revision" {
  value = element(
    concat(
      aws_ecs_task_definition.app.*.revision,
      aws_ecs_task_definition.app_with_docker_volume.*.revision,
      [""],
    ),
    0,
  )
}

