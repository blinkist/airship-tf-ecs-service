# This is the terraform task definition
data "aws_ecs_container_definition" "current" {
  count           = var.create && var.aws_ecs_task_definition_family != "" ? 1 : 0
  task_definition = "${var.aws_ecs_task_definition_family}:${var.aws_ecs_task_definition_revision}"
  container_name  = var.ecs_container_name
}

locals {
  # Calculate if there is an actual change between the current terraform task definition in the state
  # and the current live one
  image = concat([], data.aws_ecs_container_definition.current.*.image, [""])

  cpu    = concat([], data.aws_ecs_container_definition.current.*.cpu, [""])
  memory = concat([], data.aws_ecs_container_definition.current.*.memory, [""])
  memory_reservation = concat(
    [],
    data.aws_ecs_container_definition.current.*.memory_reservation,
    [""],
  )
  docker_labels = concat(
    [],
    data.aws_ecs_container_definition.current.*.docker_labels,
    [{}],
  )
  environment = concat(
    data.aws_ecs_container_definition.current.*.environment,
    [{}],
  )

  has_changed = local.image[0] != var.live_aws_ecs_task_definition_image || local.cpu[0] != var.live_aws_ecs_task_definition_cpu || local.memory[0] != var.live_aws_ecs_task_definition_memory || local.memory_reservation[0] != (var.live_aws_ecs_task_definition_memory_reservation == "undefined" ? "0" : var.live_aws_ecs_task_definition_memory_reservation) || lookup(local.docker_labels[0], "_airship_dockerlabel_hash", "") != var.live_aws_ecs_task_definition_docker_label_hash || lookup(local.docker_labels[0], "_airship_secrets_hash", "") != var.live_aws_ecs_task_definition_secrets_hash || jsonencode(local.environment[0]) != var.live_aws_ecs_task_definition_environment_json

  # If there is a difference, between the ( newly created) terraform state task definition and the live task definition
  # select the current task definition for deployment
  # Otherwise, keep using the current live task definition

  revision        = local.has_changed ? var.aws_ecs_task_definition_revision : var.live_aws_ecs_task_definition_revision
  task_definition = "${var.aws_ecs_task_definition_family}:${local.revision}"
}

