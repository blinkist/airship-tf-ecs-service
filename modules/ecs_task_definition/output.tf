# The arn of the task definition
output "aws_ecs_task_definition_arn" {
  value = "${element(concat(
    aws_ecs_task_definition.app.*.arn, 
    aws_ecs_task_definition.app_with_one_docker_volume.*.arn, 
    aws_ecs_task_definition.app_with_two_docker_volumes.*.arn, 
    aws_ecs_task_definition.app_with_three_docker_volumes.*.arn, 
    list("")), 0)}"
}

output "aws_ecs_task_definition_family" {
  value = "${element(concat(
    aws_ecs_task_definition.app.*.family, 
    aws_ecs_task_definition.app_with_one_docker_volume.*.family, 
    aws_ecs_task_definition.app_with_two_docker_volumes.*.family, 
    aws_ecs_task_definition.app_with_three_docker_volumes.*.family, 
    list("")), 0)}"
}

output "aws_ecs_task_definition_revision" {
  value = "${element(concat(
    aws_ecs_task_definition.app.*.revision, 
    aws_ecs_task_definition.app_with_one_docker_volume.*.revision, 
    aws_ecs_task_definition.app_with_two_docker_volumes.*.revision, 
    aws_ecs_task_definition.app_with_three_docker_volumes.*.revision, 
    list("latest")), 0)}"
}
