#
# This code was adapted from the `terraform-aws-ecs-container-definition` module from Cloud Posse, LLC on 2018-09-18.
# Available here: https://github.com/cloudposse/terraform-aws-ecs-container-definition
#

locals {
  # null_resource turns "true" into true, adding a temporary string will fix that problem
  safe_search_replace_string = "#keep_true_a_string_hack#"

  envvars_as_list_of_maps = flatten([
    for key in keys(var.container_envvars) : {
      name  = key
      value = var.container_envvars[key]
    }])

  secrets_as_list_of_maps = flatten([
    for key in keys(var.container_secrets) : {
      name      = key
      valueFrom = var.container_secrets[key]
    }])


  port_mappings = {
    with_port = concat([
      {
        containerPort = var.container_port
        hostPort      = var.host_port
        protocol      = var.protocol
      }],
      var.extra_ports)
    without_port = []
  }

  ulimits = {
    with_ulimits = [
      {
        softLimit = var.ulimit_soft_limit
        hardLimit = var.ulimit_hard_limit
        name      = var.ulimit_name
      },
    ]
    without_ulimits = []
  }

  repository_credentials = {
    with_credentials = {
      credentialsParameter = var.repository_credentials_secret_arn
    }
    without_credentials = null
  }

  use_port        = var.container_port == "" ? "without_port" : "with_port"
  use_credentials = var.repository_credentials_secret_arn == null ? "without_credentials" : "with_credentials"
  use_ulimits     = var.ulimit_soft_limit == "" && var.ulimit_hard_limit == "" ? "without_ulimits" : "with_ulimits"

  # var.healthcheck_cmd can be either a string (to be passed to a
  # shell) or a list of strings to be executed directly. Terraform
  # makes this a little tricky.
  healthcheck_sh   = (
    var.healthcheck_cmd != null
    ? try(concat(["CMD-SHELL"], [tostring(var.healthcheck_cmd)]), null)
    : null)
  healthcheck_list = (
    var.healthcheck_cmd != null
    ? try(concat(["CMD"], tolist(var.healthcheck_cmd)), null)
    : null)
  # If healthcheck_cmd is non-null, exactly one of healthcheck_sh and
  # healthcheck_list will also be.
  healthcheck_cmd_arg  = (
    var.healthcheck_cmd != null
    ? coalesce(tolist(local.healthcheck_sh), tolist(local.healthcheck_list))
    : null)

  healthcheck_opts = (
    local.healthcheck_cmd_arg != null
    ? {
      command     = local.healthcheck_cmd_arg,
      interval    = lookup(var.healthcheck_timings, "interval", null),
      retries     = lookup(var.healthcheck_timings, "retries", null),
      startPeriod = lookup(var.healthcheck_timings, "startPeriod", null),
      timeout     = lookup(var.healthcheck_timings, "timeout", null),
    }
    : null)

  container_definitions = [
    {
      name                   = var.container_name
      image                  = var.container_image
      memory                 = var.container_memory
      memoryReservation      = var.container_memory_reservation
      cpu                    = var.container_cpu
      essential              = var.essential
      entryPoint             = var.entrypoint
      command                = var.container_command
      workingDirectory       = var.working_directory
      readonlyRootFilesystem = var.readonly_root_filesystem
      dockerLabels           = local.docker_labels
      privileged             = var.privileged
      hostname               = var.hostname
      environment            = local.envvars_as_list_of_maps
      secrets                = local.secrets_as_list_of_maps
      mountPoints            = var.mountpoints
      portMappings           = local.port_mappings[local.use_port]
      healthCheck            = local.healthcheck_opts
      repositoryCredentials  = local.repository_credentials[local.use_credentials]
      linuxParameters = {
        initProcessEnabled = var.container_init_process_enabled ? true : false
      }
      ulimits = local.ulimits[local.use_ulimits]
      logConfiguration = {
        logDriver = var.log_driver
        options   = var.log_options
      }
    },
  ]
}

