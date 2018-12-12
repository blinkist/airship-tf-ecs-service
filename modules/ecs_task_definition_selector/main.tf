resource "null_resource" "task_depend" {
  triggers {
    task_definition = "${var.aws_ecs_task_definition_family}"
    revision        = "${var.aws_ecs_task_definition_revision}"
    container_name  = "${var.ecs_container_name}"
  }
}

# This is the terraform task definition
data "aws_ecs_container_definition" "current" {
  count           = "${var.create ? 1 : 0}"
  depends_on      = ["null_resource.task_depend"]
  task_definition = "${var.aws_ecs_task_definition_family}:${var.aws_ecs_task_definition_revision}"
  container_name  = "${var.ecs_container_name}"
}

locals {
  # Calculate if there is an actual change between the current terraform task definition in the state
  # and the current live one
  has_changed = "${ var.allow_terraform_deploy || "${join("",data.aws_ecs_container_definition.current.*.image)}" != var.live_aws_ecs_task_definition_image ||
                   join("",data.aws_ecs_container_definition.current.*.cpu) != var.live_aws_ecs_task_definition_cpu ||
                   join("",data.aws_ecs_container_definition.current.*.memory) != var.live_aws_ecs_task_definition_memory ||
                   join("",data.aws_ecs_container_definition.current.*.memory_reservation) != var.live_aws_ecs_task_definition_memory_reservation ||
                   jsonencode(data.aws_ecs_container_definition.current.*.environment) != var.live_aws_ecs_task_definition_environment_json ? true : false}"

  # If there is a difference, between the ( newly created) terraform state task definition and the live task definition
  # select the current task definition for deployment
  # Otherwise, keep using the current live task definition

  revision        = "${local.has_changed ? var.aws_ecs_task_definition_revision : var.live_aws_ecs_task_definition_revision}"
  task_definition = "${var.aws_ecs_task_definition_family}:${local.revision}"
}
