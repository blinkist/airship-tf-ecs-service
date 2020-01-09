variable "create" {
  default = true
}

variable "ecs_container_name" {
}

# Reflecting the current state

variable "aws_ecs_task_definition_family" {
}

variable "aws_ecs_task_definition_revision" {
}

# Reflecting the live state independent of the Terraform state

variable "live_aws_ecs_task_definition_revision" {
}

variable "live_aws_ecs_task_definition_image" {
}

variable "live_aws_ecs_task_definition_cpu" {
}

variable "live_aws_ecs_task_definition_memory" {
}

variable "live_aws_ecs_task_definition_memory_reservation" {
}

variable "live_aws_ecs_task_definition_environment_json" {
}

variable "live_aws_ecs_task_definition_docker_label_hash" {
}

variable "live_aws_ecs_task_definition_secrets_hash" {
}

