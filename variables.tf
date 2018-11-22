# To pretify the  use of this module externally we use maps. Downside of map-usage is that default variables are lost when only a part
# of the map is being defined. This is mitigated by using an extra set of default_* variables 

variable "create" {
  default = true
}

# ecs_cluster_id is the cluster to which the ECS Service will be added.
variable "ecs_cluster_id" {}

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

    Redirect http to https instead of serving http
    redirect_http_to_https = false

    Do we want to create a subdomain for the service inside the Route53 zone
    create_route53_record = true

    deregistration_delay = "300"

    Creates a listener rule which redirects to https
    redirect_http_to_https = false

    cognito_auth_enabled is set when cognito authentication is used for the https listener
    Important to have redirect_http_to_https set to true as http authentication is only added to the https listener

    cognito_auth_enabled = false

    cognito_user_pool_arn defines the cognito user pool arn for the added cognito authentication
    cognito_user_pool_arn = ""

    cognito_user_pool_client_id defines the cognito_user_pool_client_id
    cognito_user_pool_client_id = ""

    cognito_user_pool_domain sets the domain of the cognito_user_pool
    cognito_user_pool_domain = ""
    */
  }
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

variable "default_load_balancing_properties_redirect_http_to_https" {
  default = false
}

variable "default_load_balancing_properties_cognito_auth_enabled" {
  default = false
}

variable "default_load_balancing_properties_cognito_user_pool_arn" {
  default = ""
}

variable "default_load_balancing_properties_cognito_user_pool_client_id" {
  default = ""
}

variable "default_load_balancing_properties_cognito_user_pool_domain" {
  default = ""
}

variable "default_load_balancing_properties_route53_record_identifier" {
  default = "identifier"
}

# By default we create a CNAME to the ALB, the moment terraform can handle CNAME to ALIAS A record changes
# Route53 Alias A will be the default.
# https://github.com/terraform-providers/terraform-provider-aws/issues/5280
variable "default_load_balancing_properties_route53_record_type" {
  default = "CNAME"
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

variable "force_bootstrap_container_image" {
  default = "false"
}

# live_task_lookup_type
# This module is capable of working around the state drift when external CICD deploys to ECS
# By default a Lambda takes care of looking up the current container information, when the type is set to `lambda`
# When the type is set to `datasource` regular terraform datasources are used to look-up the current container
# Downside of datasource is that it cannot be used for bootstrapping
variable "live_task_lookup_type" {
  default = "lambda"
}

# image_url defines the docker image location
variable "bootstrap_container_image" {}

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

# ecs_cron_tasks holds a list of maps defining the scheduled jobs which need to run
#
#
#  [{
#     # name of the scheduled task
#     job_name  = "vacuum_db"
#     
#     # expression defined in 
#     # http://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
#     schedule_expression  = "cron(0 12 * * ? *)"
#
#     # command defines the command which needs to run inside the docker container
#     command = "python vacuum_db.py"
#
#   },]

variable "ecs_cron_tasks" {
  type    = "list"
  default = []
}
