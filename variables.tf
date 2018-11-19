# To pretify the  use of this module externally we use maps. Downside of map-usage is that default variables are lost when only a part
# of the map is being defined. This is mitigated by using an extra set of default_* variables 

variable "create" {
  default = true
}

# ecs_cluster_id is the cluster to which the ECS Service will be added.
variable "ecs_cluster_id" {}

variable "allow_terraform_deploy" {
  description = "When true, forces task update from Terraform."
  default     = "true"
}

# Number of days for the cloudwatch logs for the containers to be retained
variable "log_retention_in_days" {
  default = "14"
}

# kms_key for the cloudwatch logs
variable "cloudwatch_kms_key" {
  default = ""
}

# Region of the ECS Cluster
variable "region" {}

# With fargate_enabled the launchtype of the service will be FARGATE, otherwise EC2 ( default is false)
variable "fargate_enabled" {
  default = false
}

# With awsvpc_enabled the network_mode for the ECS task definition will be awsvpc, defaults to bridge 
variable "awsvpc_enabled" {
  default = false
}

# scheduling_strategy defaults to REPLICA
variable "scheduling_strategy" {
  default = "REPLICA"
}

# Spread tasks over ECS Cluster based on AZ, Instance-id, memory
variable "with_placement_strategy" {
  default = false
}

# Extra hosts the ALB needs to make listener_rules for to the ECS target group
variable "custom_listen_hosts" {
  default = []
  type    = "list"
}

# load_balancing_enabled defines if we are using a load balancer for our ecs service
variable "load_balancing_enabled" {
  default = false
}

## load_balancing_properties map defines the map for services hooked to a load balancer
variable "load_balancing_properties" {
  type = "map"

  default = {
    /*
    Note that since Terraform doesn't support partial map defaults (see
    https://github.com/hashicorp/terraform/issues/16517), the default values here
    are set in the independent default_load_balancing_properties_* variables

    lb_listener_arn is the ALB listener arn for HTTP
    lb_listener_arn = ""

    lb_listener_arn_https is the ALB listener arn for HTTPS
    lb_listener_arn_https = ""

    lb_vpc_id is the vpc_id for the target_group to reside in
    lb_vpc_id = ""

    route53_zone_id is the zone to add a subdomain to
    route53_zone_id = ""

    health_uri is the health uri to be checked by the ALB 
    health_uri = "/ping"

    unhealthy_threshold is the health uri to be checked by the ALB 
    unhealthy_threshold = "3"

    Do we create listener rules for https
    https_enabled = true

    Do we want to create a subdomain for the service inside the Route53 zone
    create_route53_record = true
    */
  }
}

## load_balancing_properties map defines the map for services hooked to a load balancer

variable "default_load_balancing_properties_tg_port" {
  description = "This is the port that the container listens on"
  default     = "80"
}

variable "default_load_balancing_properties_tg_arn" {
  description = "This is the target group arn that the container uses"
  default     = ""
}

variable "default_load_balancing_properties_tg_protocol" {
  description = "This is the target group protocol that the container uses. The protocol to use for routing traffic to the targets. Should be one of TCP, HTTP, HTTPS or TLS."
  default     = "HTTP"
}

variable "default_load_balancing_properties_load_balancer_type" {
  description = "This can be application or network"
  default     = "application"
}

variable "default_load_balancing_properties_lb_listener_arn" {
  default = ""
}

variable "default_load_balancing_properties_lb_listener_arn_https" {
  default = ""
}

variable "default_load_balancing_properties_lb_vpc_id" {
  default = ""
}

variable "default_load_balancing_properties_route53_zone_id" {
  default = ""
}

variable "default_load_balancing_properties_health_uri" {
  default = "/ping"
}

variable "default_load_balancing_properties_unhealthy_threshold" {
  default = "3"
}

variable "default_load_balancing_properties_deregistration_delay" {
  default = 300
}

variable "default_load_balancing_properties_https_enabled" {
  default = true
}

variable "default_load_balancing_properties_lb_arn" {
  default = ""
}

variable "default_load_balancing_properties_route53_record_identifier" {
  default = "identifier"
}

# By default we create a NO record to the ALB, the moment terraform can handle CNAME to ALIAS A record changes
# Route53 Alias A will be the default.
# https://github.com/terraform-providers/terraform-provider-aws/issues/5280
variable "default_load_balancing_properties_route53_record_type" {
  default = "NONE"
}

## capacity_properties map defines the capacity properties of the service
variable "capacity_properties" {
  type = "map"

  default = {
    /*
    Note that since Terraform doesn't support partial map defaults (see
    https://github.com/hashicorp/terraform/issues/16517), the default values here
    are set in the independent default_capacity_properties_* variables

    desired_capacity is the desired amount of tasks for a service, when autoscaling is used desired_capacity is only used initially
    after that autoscaling determins the amount of tasks 
    desired_capacity = "2"

    desired_min_capacity is used when autoscaling is used, it sets the minimum of tasks to be available for this service
    desired_min_capacity = "2"

    desired_max_capacity is used when autoscaling is used, it sets the maximum of tasks to be available for this service
    desired_max_capacity = "5"

    deployment_maximum_percent sets the maximum deployment size of the current capacity, 200% means double the amount of current tasks
    will be active in case a deployment is happening
    deployment_maximum_percent = "200"

    deployment_minimum_healthy_percent sets the minimum deployment size of the current capacity, 0% means no tasks need to be running at the moment of
    a deployment switch
    deployment_minimum_healthy_percent = "0"
    */
  }
}

variable "default_capacity_properties_desired_capacity" {
  default = "2"
}

variable "default_capacity_properties_desired_min_capacity" {
  default = "2"
}

variable "default_capacity_properties_desired_max_capacity" {
  default = "2"
}

variable "default_capacity_properties_deployment_maximum_percent" {
  default = "200"
}

variable "default_capacity_properties_deployment_minimum_healthy_percent" {
  default = "100"
}

# image_url defines the docker image location
variable "container_image" {
  default = ""
}

# Container name 
variable "container_name" {
  default = "app"
}

# cpu defines the needed cpu for the container
variable "container_cpu" {}

# container_memory  defines the hard memory limit of the container
variable "container_memory" {}

# container_memory_reservation defines the ECS Memory reservation for this service and Soft/limit
variable "container_memory_reservation" {
  default = ""
}

variable "privileged" {
  description = "Bool. Run the container with elevated privilege."
  default     = false
}

# port defines the needed port of the container
variable "container_port" {
  default = ""
}

variable "host_port" {
  default = ""
}

# Scaling properties holds a map of multiple maps defining scaling policies and alarms
#
#
#  [{
#     # type is the metric the metric being used for the service
#     type               = "CPUUtilization"
#     
#     # direction defines the direction of the scaling, up means more tasks, down is less tasks
#     direction          = "up"
#
#     # evaluation_periods how many observation points are needed for a scaling decision
#     evaluation_periods = "2"
#
#     
#     # observation_period is the number of seconds one statistic is measured
#     observation_period = "300"
#
#     # statistic defines the type of statistic for measuring SampleCount, Average, Sum, Minimum, Maximum
#     statistic          = "Average"
#
#     # threshold defines the value which is needed to surpass, given the direction
#     threshold          = "89"
#
#     # Cooldown defines the amount of seconds in which another scaling is disabled after a succesful scaling action
#     cooldown           = "900"
#
#     # Adjustment_type defines the type of adjustment, can either be absolute or relative : ChangeInCapacity, ExactCapacity, and PercentChangeInCapacity.
#     adjustment_type    = "ChangeInCapacity"
# 
#     # scaling_adjustment defines the amount to scale, can be a postive or negative number or percentage
#     scaling_adjustment = "1"
#   },]

variable "scaling_properties" {
  default = []
}

# container_envvars defines extra container env vars, list of maps
# { key = val,key2= val2}

variable "container_envvars" {
  default = {}
}

####

variable "name" {
  description = "The name of the project, must be unique ."
}

# Whether to provide access to the supplied kms_keys. If no kms keys are
# passed, set this to false.
variable "kms_enabled" {
  default = true
}

# List of KMS keys the task has access to
variable "kms_keys" {
  default = []
}

# Whether to provide access to the supplied ssm_paths. If no ssm paths are
# passed, set this to false.
variable "ssm_enabled" {
  default = true
}

# List of SSM Paths the task has access to
variable "ssm_paths" {
  default = []
}

# AWSVPC ( FARGATE ) need subnets to reside in
variable "awsvpc_subnets" {
  default = []
}

# AWSVPC ( FARGATE ) need awsvpc_security_group_ids attached to the task
variable "awsvpc_security_group_ids" {
  default = []
}

# S3 Read-only paths the Task has access to
variable "s3_ro_paths" {
  default = []
}

# S3 Read-write paths the Task has access to
variable "s3_rw_paths" {
  default = []
}

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

variable "host_path_volume" {
  type    = "map"
  default = {}
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

variable "tags" {
  description = "A map of tags to apply to all taggable resources"
  type        = "map"
  default     = {}
}

locals {
  name_map = {
    "Name" = "${var.container_name}"
  }

  tags = "${merge(var.tags, local.name_map)}"
}
