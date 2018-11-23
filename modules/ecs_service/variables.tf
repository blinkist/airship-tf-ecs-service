# hack 
variable "aws_lb_listener_rules" {
  default = []
}

# Name of the ECS Service
variable "name" {}

# Do we create resources
variable "create" {
  default = true
}

variable "awsvpc_enabled" {}

variable "selected_task_definition" {}

# The cluster ID
variable "cluster_id" {}

# The launch type, either FARGATE or EC2
variable "launch_type" {}

# The initial desired_capacity
variable "desired_capacity" {}

# The container name
variable "container_name" {}

# The container port
variable "container_port" {}

# scheduling_strategy defaults to Replica
variable "scheduling_strategy" {}

# deployment_maximum_percent sets the maximum size of the total capacity in tasks in % compared to the normal capacity at deployment
variable "deployment_maximum_percent" {}

# deployment_minimum_healthy_percent sets the minimum size of the total capacity in tasks in % compared to the normal capacity at deployment
variable "deployment_minimum_healthy_percent" {}

# awsvpc_subnets defines the subnets for the ECS Tasks to reside in case of AWSVPC
variable "awsvpc_subnets" {
  default = []
}

# awsvpc_security_group_ids defines the vpc_security_group_ids for ECS Tasks in case of AWSVPC
variable "awsvpc_security_group_ids" {
  default = []
}

# lb_target_group_arn sets the arn of the target_group the service needs to connect to
variable "lb_target_group_arn" {
  default = ""
}

# What kind of load balancing
variable "load_balancing_type" {}

# Spread tasks over ECS Cluster based on AZ, Instance-id, memory
variable "with_placement_strategy" {}
