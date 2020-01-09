locals {
  docker_volume_name = lookup(var.docker_volume, "name", "")
}

resource "aws_ecs_task_definition" "app" {
  count = var.create && local.docker_volume_name == "" ? 1 : 0

  family        = var.name
  task_role_arn = var.ecs_taskrole_arn

  # Execution role ARN can be needed inside FARGATE
  execution_role_arn = var.ecs_task_execution_role_arn

  # Used for Fargate
  cpu    = var.cpu
  memory = var.memory

  dynamic "volume" {
    for_each = var.host_path_volumes
    content {
      host_path = lookup(volume.value, "host_path", null)
      name      = volume.value.name

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
          scope         = lookup(docker_volume_configuration.value, "scope", null)
        }
      }
    }
  }

  container_definitions = var.container_definitions
  network_mode          = var.awsvpc_enabled ? "awsvpc" : "bridge"

  # We need to ignore future container_definitions, and placement_constraints, as other tools take care of updating the task definition

  requires_compatibilities = [var.launch_type]
}

resource "aws_ecs_task_definition" "app_with_docker_volume" {
  count = var.create && local.docker_volume_name != "" ? 1 : 0

  family        = var.name
  task_role_arn = var.ecs_taskrole_arn

  # Execution role ARN can be needed inside FARGATE
  execution_role_arn = var.ecs_task_execution_role_arn

  # Used for Fargate
  cpu    = var.cpu
  memory = var.memory

  dynamic "volume" {
    for_each = var.host_path_volumes
    content {
      host_path = lookup(volume.value, "host_path", null)
      name      = volume.value.name

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
          scope         = lookup(docker_volume_configuration.value, "scope", null)
        }
      }
    }
  }

  # Unfortunately, the same hack doesn't work for a list of Docker volume
  # blocks because they include a nested map; therefore the only way to
  # currently sanely support Docker volume blocks is to only consider the
  # single volume case.
  volume {
    name = local.docker_volume_name

    docker_volume_configuration {
      autoprovision = lookup(var.docker_volume, "autoprovision", false)
      scope         = lookup(var.docker_volume, "scope", "shared")
      driver        = lookup(var.docker_volume, "driver", "")
    }
  }

  container_definitions = var.container_definitions

  network_mode = var.awsvpc_enabled ? "awsvpc" : "bridge"

  requires_compatibilities = [var.launch_type]
}

