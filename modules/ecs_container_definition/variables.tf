#
# This code was adapted from the `terraform-aws-ecs-container-definition` module from Cloud Posse, LLC on 2018-09-18.
# Available here: https://github.com/cloudposse/terraform-aws-ecs-container-definition
#

variable "container_name" {
  description = "The name of the container. Up to 255 characters ([a-z], [A-Z], [0-9], -, _ allowed)."
}

variable "container_image" {
  description = "The image used to start the container. Images in the Docker Hub registry available by default."
}

variable "container_memory" {
  description = "The amount of memory (in MiB) to allow the container to use. This is a hard limit, if the container attempts to exceed the container_memory, the container is killed. This field is optional for Fargate launch type and the total amount of container_memory of all containers in a task will need to be lower than the task memory value."
  default     = 256
}

variable "container_memory_reservation" {
  description = "The amount of memory (in MiB) to reserve for the container. If container needs to exceed this threshold, it can do so up to the set container_memory hard limit."
  default     = 128
}

variable "container_port" {
  description = "The port number on the container bound to assigned host_port."
  default     = 80
}

variable "host_port" {
  description = "The port number on the container instance (host) to reserve for the container_port. If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort."
}

variable "protocol" {
  description = "The protocol used for the port mapping. Options: tcp or udp."
  default     = "tcp"
}

variable "privileged" {
  description = "Bool. Run the container with elevated privilege."
  default     = "false"
}

variable "healthcheck" {
  description = "A map containing command (string), interval (duration in seconds), retries (1-10, number of times to retry before marking container unhealthy, and startPeriod (0-300, optional grace period to wait, in seconds, before failed healthchecks count toward retries)"
  default     = {}
}

variable "container_cpu" {
  description = "The number of cpu units to reserve for the container. This is optional for tasks using Fargate launch type and the total amount of container_cpu of all containers in a task will need to be lower than the task-level cpu value."
  default     = 256
}

variable "essential" {
  description = "Determines whether all other containers in a task are stopped, if this container fails or stops for any reason. Due to how Terraform type casts booleans in json it is required to double quote this value."
  default     = "true"
}

variable "entrypoint" {
  description = "The entry point that is passed to the container."
  default     = [""]
}

variable "command" {
  description = "The command that is passed to the container."
  default     = [""]
}

variable "working_directory" {
  description = "The working directory to run commands inside the container."
  default     = ""
}

variable "container_envvars" {
  description = "The environment variables to pas to the container. This is a map"
  default     = {}
}

variable "readonly_root_filesystem" {
  description = "Determines whether a container is given read-only access to its root filesystem. Due to how Terraform type casts booleans in json it is required to double quote this value."
  default     = "false"
}

variable "log_driver" {
  description = "The log driver to use for the container. If using Fargate launch type, only supported value is awslogs."
  default     = "awslogs"
}

# list of mount points to add to every container in the task
variable "mountpoints" {
  type    = "list"
  default = []

  # {
  #   source_volume = "service-storage"
  #   container_path = "/foo"
  #   read_only = "false"
  # },
}

variable "hostname" {
  description = "The optional hostname for the container, not allowed to use with Fargate"
  default     = ""
}

variable "log_options" {
  description = "The configuration options to send to the log_driver."

  default = {
    "awslogs-region" = "us-west-2"

    "awslogs-group" = "default"

    "awslogs-stream-prefix" = "default"
  }
}

# container_docker_labels sets the DockerLabels, in case it''s set, an extra
# label '_airship_dockerlabel_hash' is set to keep track of changes.
variable "container_docker_labels" {
  type    = "map"
  default = {}
}

locals {
  # We need to inject a docker label of all the docker labels hashed for later compare
  # if the signummed length of the input map is 1 we add the _airship_dockerlabel_hash with the md5 sum of the map
  # if the signummed length of the input map is 0 we merge with an empty map, effectively doing nothing.
  docker_label_merge = {
    "0" = {}

    "1" = {
      _airship_dockerlabel_hash = "${md5(jsonencode(var.container_docker_labels))}"
    }
  }

  docker_labels = "${merge(
     var.container_docker_labels,
     local.docker_label_merge[signum(length(var.container_docker_labels))])}"
}

variable "tags" {
  description = "A map of tags to apply to all taggable resources"
  type        = "map"
  default     = {}
}
