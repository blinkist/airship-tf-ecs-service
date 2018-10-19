# name of the ecs_service
variable "name" {}

# create
variable "create" {
  default = true
}

# cluster name
variable "cluster_name" {}

# is awsvpc enabled ?
variable "awsvpc_enabled" {
  default = false
}

# is fargate enabled ?
variable "fargate_enabled" {
  default = false
}

# container_definitions set the json with the container definitions
variable "container_definitions" {}

# cpu is set in case Fargate is used
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
variable "cpu" {}

# memory is set in case Fargate is used
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
variable "memory" {}

# ecs_taskrole_arn sets the arn of the ECS Task role
variable "ecs_taskrole_arn" {}

# ecs_task_execution_role_arn sets the execution role arn, needed for FARGATE
variable "ecs_task_execution_role_arn" {}

# AWS Region
variable "region" {}

# launch_type sets the launch_type, either EC2 or FARGATE
variable "launch_type" {}

# A Docker volume to add to the task
variable "docker_volume" {
  type    = "map"
  default = {}

  # {
  # # these properties are supported as a 'flattened' version of the docker volume configuration:
  # # https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#docker_volume_configuration
  #     name = "bla",
  #     scope == "shared",
  #     autoprovision = true,
  #     driver = "foo"
  # # these properties are NOT supported, as they are nested maps in the resource's configuration
  # #   driver_opts = NA
  # #   labels = NA
  # }
}

# list of host paths to add as volumes to the task
variable "host_path_volumes" {
  type    = "list"
  default = []

  # {
  #     name = "service-storage",
  #     host_path = "/foo"
  # },
}

# list of mount points to add to every container in the task
variable "mountpoints" {
  type    = "list"
  default = []

  # {
  #     source_volume = "service-storage",
  #     container_path = "/foo",
  #     read_only = "false"
  # },
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = "map"
  default     = {}
}

locals {
  name_map = {
    "Name" = "${var.name}"
  }

  tags = "${merge(var.tags, local.name_map)}"
}
