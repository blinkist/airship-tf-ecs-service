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

# Do we have a load balancer attached
variable "lb_attached" {
  default = true
}

variable "nlb_attached" {
  default = false
}

# Spread tasks over ECS Cluster based on AZ, Instance-id, memory
variable "with_placement_strategy" {}

variable "enable_service_discovery" {
  default = "false"
}

# The service discovery namespace arn to register the services against
variable "service_discovery_namespace_arn" {
  default = ""
}

# (Optional) The container name value, already specified in the task definition, to be used for your service discovery service
variable "service_discovery_container_name" {
  default = ""
}

variable "health_check_grace_period_seconds" {
  default = "300"
}

variable "tags" {
  type    = "map"
  default = {}
}
