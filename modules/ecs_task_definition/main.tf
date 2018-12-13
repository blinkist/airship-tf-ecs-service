data "null_data_source" "docker" {
  inputs = {
    volume_name = "${lookup(var.docker_volumes[0], "name", "NONAME")}"
  }
}

resource "aws_ecs_task_definition" "app" {
  count = "${(var.create && ("${data.null_data_source.docker.outputs["volume_name"]}" == "NONAME")) ? 1 : 0 }"

  depends_on = ["data.null_data_source.docker"]

  family        = "${var.name}"
  task_role_arn = "${var.ecs_taskrole_arn}"

  # Execution role ARN can be needed inside FARGATE
  execution_role_arn = "${var.ecs_task_execution_role_arn}"

  # Used for Fargate
  cpu    = "${var.cpu}"
  memory = "${var.memory}"

  # This is a hack: https://github.com/hashicorp/terraform/issues/14037#issuecomment-361202716
  # Specifically, we are assigning a list of maps to the `volume` block to
  # mimic multiple `volume` statements
  # This WILL break in Terraform 0.12: https://github.com/hashicorp/terraform/issues/14037#issuecomment-361358928
  # but we need something that works before then
  # volume = ["${var.host_path_volumes}"]
  volume {
    name      = "${lookup(var.host_path_volume, "name", "novolume")}"
    host_path = "${lookup(var.host_path_volume, "host_path", "/var/tmp/novolume")}"
  }

  container_definitions = "${var.container_definitions}"
  network_mode          = "${var.awsvpc_enabled ? "awsvpc" : "bridge"}"

  # We need to ignore future container_definitions, and placement_constraints, as other tools take care of updating the task definition

  requires_compatibilities = ["${var.launch_type}"]
}

locals {
  base_opts_map = {
    "0" = {}
    "1" = {}
    "2" = {}
  }

  base_volume_map = {
    name          = ""
    autoprovision = ""
    scope         = ""
    driver        = ""
  }

  docker_volume_options = "${merge(local.base_opts_map,var.docker_volume_options)}"
  docker_volume_labels  = "${merge(local.base_opts_map, var.docker_volume_labels)}"
}

resource "aws_ecs_task_definition" "app_with_one_docker_volume" {
  count = "${(var.create && var.num_docker_volumes == 1 && ("${data.null_data_source.docker.outputs["volume_name"]}" != "NONAME") && ("${data.null_data_source.docker.outputs["volume_name"]}" != "")) ? 1 : 0 }"

  depends_on = ["data.null_data_source.docker"]

  family        = "${var.name}"
  task_role_arn = "${var.ecs_taskrole_arn}"

  # Execution role ARN can be needed inside FARGATE
  execution_role_arn = "${var.ecs_task_execution_role_arn}"

  # Used for Fargate
  cpu    = "${var.cpu}"
  memory = "${var.memory}"

  volume {
    name = "${lookup(var.docker_volumes[0], "name")}"

    docker_volume_configuration {
      autoprovision = "${lookup(var.docker_volumes[0], "autoprovision", false)}"
      scope         = "${lookup(var.docker_volumes[0], "scope", "shared")}"
      driver        = "${lookup(var.docker_volumes[0], "driver", "")}"
      driver_opts   = "${local.docker_volume_options["0"]}"
      labels        = "${local.docker_volume_labels["0"]}"
    }
  }

  # This is a hack: https://github.com/hashicorp/terraform/issues/14037#issuecomment-361202716
  # Specifically, we are assigning a list of maps to the `volume` block to
  # mimic multiple `volume` statements
  # This WILL break in Terraform 0.12: https://github.com/hashicorp/terraform/issues/14037#issuecomment-361358928
  # but we need something that works before then
  # 
  # volume = ["${var.host_path_volumes}"]
  container_definitions = "${var.container_definitions}"

  network_mode             = "${var.awsvpc_enabled ? "awsvpc" : "bridge"}"
  requires_compatibilities = ["${var.launch_type}"]
}

resource "aws_ecs_task_definition" "app_with_two_docker_volumes" {
  count = "${(var.create && var.num_docker_volumes == 2 && ("${data.null_data_source.docker.outputs["volume_name"]}" != "")) ? 1 : 0 }"

  depends_on = ["data.null_data_source.docker"]

  family        = "${var.name}"
  task_role_arn = "${var.ecs_taskrole_arn}"

  # Execution role ARN can be needed inside FARGATE
  execution_role_arn = "${var.ecs_task_execution_role_arn}"

  # Used for Fargate
  cpu    = "${var.cpu}"
  memory = "${var.memory}"

  # Unfortunately, the same hack doesn't work for a list of Docker volume
  # blocks because they include a nested map; therefore the only way to
  # currently sanely support Docker volume blocks is to only consider the
  # single volume case.
  volume {
    name = "${lookup(merge(local.base_volume_map,var.docker_volumes[0]), "name")}"

    docker_volume_configuration {
      autoprovision = "${lookup(var.docker_volumes[0], "autoprovision", false)}"
      scope         = "${lookup(var.docker_volumes[0], "scope", "shared")}"
      driver        = "${lookup(var.docker_volumes[0], "driver", "")}"
      driver_opts   = "${local.docker_volume_options["0"]}"
      labels        = "${local.docker_volume_labels["0"]}"
    }
  }

  volume {
    name = "${lookup(var.docker_volumes[1], "name")}"

    docker_volume_configuration {
      autoprovision = "${lookup(var.docker_volumes[1], "autoprovision", false)}"
      scope         = "${lookup(var.docker_volumes[1], "scope", "shared")}"
      driver        = "${lookup(var.docker_volumes[1], "driver", "")}"
      driver_opts   = "${local.docker_volume_options["1"]}"
      labels        = "${local.docker_volume_labels["1"]}"
    }
  }

  # This is a hack: https://github.com/hashicorp/terraform/issues/14037#issuecomment-361202716
  # Specifically, we are assigning a list of maps to the `volume` block to
  # mimic multiple `volume` statements
  # This WILL break in Terraform 0.12: https://github.com/hashicorp/terraform/issues/14037#issuecomment-361358928
  # but we need something that works before then
  # 
  # volume = ["${var.host_path_volumes}"]
  container_definitions = "${var.container_definitions}"

  network_mode             = "${var.awsvpc_enabled ? "awsvpc" : "bridge"}"
  requires_compatibilities = ["${var.launch_type}"]
}

resource "aws_ecs_task_definition" "app_with_three_docker_volumes" {
  count = "${(var.create && var.num_docker_volumes == 3 && ("${data.null_data_source.docker.outputs["volume_name"]}" != "")) ? 1 : 0 }"

  depends_on = ["data.null_data_source.docker"]

  family        = "${var.name}"
  task_role_arn = "${var.ecs_taskrole_arn}"

  # Execution role ARN can be needed inside FARGATE
  execution_role_arn = "${var.ecs_task_execution_role_arn}"

  # Used for Fargate
  cpu    = "${var.cpu}"
  memory = "${var.memory}"

  # Unfortunately, the same hack doesn't work for a list of Docker volume
  # blocks because they include a nested map; therefore the only way to
  # currently sanely support Docker volume blocks is to only consider the
  # single volume case.
  volume {
    name = "${lookup(var.docker_volumes[0], "name")}"

    docker_volume_configuration {
      autoprovision = "${lookup(var.docker_volumes[0], "autoprovision", false)}"
      scope         = "${lookup(var.docker_volumes[0], "scope", "shared")}"
      driver        = "${lookup(var.docker_volumes[0], "driver", "")}"
      driver_opts   = "${local.docker_volume_options["0"]}"
      labels        = "${local.docker_volume_labels["0"]}"
    }
  }

  volume {
    name = "${lookup(var.docker_volumes[1], "name")}"

    docker_volume_configuration {
      autoprovision = "${lookup(var.docker_volumes[1], "autoprovision", false)}"
      scope         = "${lookup(var.docker_volumes[1], "scope", "shared")}"
      driver        = "${lookup(var.docker_volumes[1], "driver", "")}"
      driver_opts   = "${local.docker_volume_options["1"]}"
      labels        = "${local.docker_volume_labels["1"]}"
    }
  }

  volume {
    name = "${lookup(var.docker_volumes[2], "name")}"

    docker_volume_configuration {
      autoprovision = "${lookup(var.docker_volumes[2], "autoprovision", false)}"
      scope         = "${lookup(var.docker_volumes[2], "scope", "shared")}"
      driver        = "${lookup(var.docker_volumes[2], "driver", "")}"
      driver_opts   = "${local.docker_volume_options["2"]}"
      labels        = "${local.docker_volume_labels["2"]}"
    }
  }

  # This is a hack: https://github.com/hashicorp/terraform/issues/14037#issuecomment-361202716
  # Specifically, we are assigning a list of maps to the `volume` block to
  # mimic multiple `volume` statements
  # This WILL break in Terraform 0.12: https://github.com/hashicorp/terraform/issues/14037#issuecomment-361358928
  # but we need something that works before then
  # 
  # volume = ["${var.host_path_volumes}"]
  container_definitions = "${var.container_definitions}"

  network_mode             = "${var.awsvpc_enabled ? "awsvpc" : "bridge"}"
  requires_compatibilities = ["${var.launch_type}"]
}
