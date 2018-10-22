#
# This code was adapted from the `terraform-aws-ecs-container-definition` module from Cloud Posse, LLC on 2018-09-18.
# Available here: https://github.com/cloudposse/terraform-aws-ecs-container-definition
#

locals {
  # null_resource turns "true" into true, adding a temporary string will fix that problem
  safe_search_replace_string = "#keep_true_a_string_hack#"
}

resource "null_resource" "envvars_as_list_of_maps" {
  count = "${length(keys(var.container_envvars))}"

  triggers = "${map(
    "name", "${local.safe_search_replace_string}${element(keys(var.container_envvars), count.index)}",
    "value", "${local.safe_search_replace_string}${element(values(var.container_envvars), count.index)}",
  )}"
}

locals {
  port_mappings = {
    with_port = [
      {
        containerPort = "${var.container_port}"
        hostPort      = "${var.host_port}"
        protocol      = "${var.protocol}"
      },
    ]

    without_port = []
  }

  use_port = "${var.container_port == "" ? "without_port" : "with_port" }"

  container_definitions = [{
    name                   = "${var.container_name}"
    image                  = "${var.container_image}"
    memory                 = "${var.container_memory}"
    memoryReservation      = "${var.container_memory_reservation}"
    cpu                    = "${var.container_cpu}"
    essential              = "${var.essential}"
    entryPoint             = "${var.entrypoint}"
    command                = "${var.command}"
    workingDirectory       = "${var.working_directory}"
    readonlyRootFilesystem = "${var.readonly_root_filesystem}"
    privileged             = "${var.privileged}"

    hostname = "${var.hostname}"

    environment = ["${null_resource.envvars_as_list_of_maps.*.triggers}"]

    mountPoints = ["${var.mountpoints}"]

    portMappings = "${local.port_mappings[local.use_port]}"

    healthCheck = "${var.healthcheck}"

    logConfiguration = {
      logDriver = "${var.log_driver}"
      options   = "${var.log_options}"
    }
  }]
}
