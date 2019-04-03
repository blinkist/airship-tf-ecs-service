# To pretify the  use of this module externally we use maps. Downside of map-usage is that default variables are lost when only a part
# of the map is being defined. This is mitigated by using an extra set of default_* variables 

variable "create" {
  default     = true
  description = "create is the variable used in all resources to conditionally create them"
}

variable "ecs_cluster_id" {
  description = "The cluster to which the ECS Service will be added"
}

variable "region" {
  description = "Region of the ECS Cluster"
}

variable "fargate_enabled" {
  description = "With fargate_enabled the launchtype of the service will be FARGATE, otherwise EC2 ( default is false)"
  default     = false
}

variable "awsvpc_enabled" {
  default     = false
  description = "With awsvpc_enabled the network_mode for the ECS task definition will be awsvpc, defaults to bridge"
}

variable "log_retention_in_days" {
  default     = "14"
  description = "Number of days for the cloudwatch logs for the containers to be retained"
}

variable "cloudwatch_kms_key" {
  default     = ""
  description = "kms_key for the cloudwatch logs"
}

variable "scheduling_strategy" {
  default     = "REPLICA"
  description = "scheduling_strategy defaults to REPLICA"
}

variable "with_placement_strategy" {
  default     = false
  description = "Spread tasks over ECS Cluster based on AZ, Instance-id, memory"
}

variable "deployment_controller_type" {
  description = <<EOF
deployment_controller_type sets the deployment type
ECS for Rolling update, and CODE_DEPLOY for Blue/Green deployment via CodeDeploy
EOF

  default = "ECS"
}

variable "load_balancing_properties_lb_arn" {
  description = "The arn of the ALB or NLB being used"
  default     = ""
}

variable "load_balancing_type" {
  default     = "none"
  description = "load_balancing_type is either \"none\", \"network\",\"application\""
}

variable "load_balancing_properties_route53_record_type" {
  description = "By default we create an ALIAS to the ALB, this can be set to CNAME, or NONE to not create any records"
  default     = "ALIAS"
}

variable "load_balancing_properties_route53_custom_name" {
  description = "By default we create a subdomain with using var.name, override with load_balancing_properties_route53_custom_name"
  default     = ""
}

variable "load_balancing_properties_custom_listen_hosts" {
  description = "Extra hosts the ALB needs to make listener_rules for to the ECS target group"
  default     = []
  type        = "list"
}

variable "load_balancing_properties_custom_listen_hosts_count" {
  description = "necessary count for the load_balancing_properties_custom_listen_hosts"
  default     = 0
}

variable "load_balancing_properties_redirect_http_to_https" {
  description = "Redirect http to https instead of serving http"
  default     = false
}

variable "load_balancing_properties_lb_listener_arn" {
  description = "lb_listener_arn is the ALB listener arn for HTTP"
  default     = ""
}

variable "load_balancing_properties_lb_listener_arn_https" {
  description = "lb_listener_arn_https is the ALB listener arn for HTTPS"
  default     = ""
}

variable "load_balancing_properties_nlb_listener_port" {
  description = "nlb_listener_port is the default port for the Network Load Balancer to listen on"
  default     = "80"
}

variable "load_balancing_properties_target_group_port" {
  description = "target_group_port sets the port for the alb or nlb target group, this generally can stay 80 regardless of the service port"
  default     = "80"
}

variable "load_balancing_properties_lb_vpc_id" {
  description = "lb_vpc_id is the vpc_id for the target_group to reside in"
  default     = ""
}

variable "load_balancing_properties_route53_zone_id" {
  description = "route53_zone_id is the zone to add a subdomain to"
  default     = ""
}

variable "load_balancing_properties_health_uri" {
  description = "health_uri is the health uri to be checked by the ALB"
  default     = "/ping"
}

variable "load_balancing_properties_health_matcher" {
  description = "health_matcher sets the expected HTTP status for the health check to be marked healthy"
  default     = "200"
}

variable "load_balancing_properties_unhealthy_threshold" {
  description = "The number of consecutive successful health checks required before considering an healthy target unhealthy"
  default     = "3"
}

variable "load_balancing_properties_healthy_threshold" {
  description = "The number of consecutive successful health checks required before considering an unhealthy target healthy"
  default     = "3"
}

variable "load_balancing_properties_https_enabled" {
  description = "load_balancing_properties_https_enabled enables listener rules creation for https"
  default     = true
}

variable "load_balancing_properties_deregistration_delay" {
  description = "load_balancing_properties_deregistration_delay sets the deregistration_delay for the targetgroup"
  default     = 300
}

variable "load_balancing_properties_route53_record_identifier" {
  description = "route53_record_identifier sets the A ALIAS record identifier"
  default     = "identifier"
}

variable "load_balancing_properties_cognito_auth_enabled" {
  description = "Set to true when cognito authentication is used for the https listener"
  default     = false
}

variable "load_balancing_properties_cognito_user_pool_arn" {
  description = "load_balancing_properties_cognito_user_pool_arn defines the cognito user pool arn for the added cognito authentication"
  default     = ""
}

variable "load_balancing_properties_cognito_user_pool_client_id" {
  description = "load_balancing_properties_cognito_user_pool_client_id defines the cognito_user_pool_client_id"
  default     = ""
}

variable "load_balancing_properties_cognito_user_pool_domain" {
  description = "load_balancing_properties_cognito_user_pool_domain defines the cognito_user_pool_domain"
  default     = ""
}

variable "capacity_properties_desired_capacity" {
  description = "capacity_properties_desired_capacity is the desired amount of tasks for a service, when autoscaling is used desired_capacity is only used initially"
  default     = "2"
}

variable "capacity_properties_desired_min_capacity" {
  description = "capacity_properties_desired_min_capacity is used when autoscaling is activated, it sets the minimum of tasks to be available for this service"
  default     = "2"
}

variable "capacity_properties_desired_max_capacity" {
  description = "capacity_properties_desired_max_capacity is used when autoscaling is activated, it sets the maximum of tasks to be available for this service"
  default     = "2"
}

variable "capacity_properties_deployment_maximum_percent" {
  description = "capacity_properties_deployment_maximum_percent sets the maximum deployment size of the current capacity, 200% means double the amount of current tasks"
  default     = "200"
}

variable "capacity_properties_deployment_minimum_healthy_percent" {
  description = "capacity_properties_deployment_maximum_percent sets the minimum deployment size of the current capacity, 0% means no tasks need to be running at the moment of"
  default     = "100"
}

variable "force_bootstrap_container_image" {
  default = "false"
}

variable "live_task_lookup_type" {
  description = <<EOF
This module is capable of working around the state drift when external CICD deploys to ECS.
By default a Lambda takes care of looking up the current container information, when the type is set to `lambda`.
When the type is set to `datasource` regular terraform datasources are used to look-up the current container.
Downside of datasource is that it cannot be used for bootstrapping.
EOF

  default = "lambda"
}

variable "bootstrap_container_image" {
  description = "The docker image location"
}

variable "container_name" {
  description = "Container name"
  default     = "app"
}

variable "container_cpu" {
  description = "cpu defines the needed cpu for the container"
}

variable "container_memory" {
  description = "container_memory  defines the hard memory limit of the container"
}

variable "container_docker_labels" {
  default = {}
}

variable "container_memory_reservation" {
  default     = ""
  description = "container_memory_reservation defines the ECS Memory reservation for this service and Soft/limit"
}

variable "container_port" {
  default     = ""
  description = "port defines the needed port of the container"
}

variable "container_healthcheck" {
  type        = "map"
  default     = {}
  description = "healthcheck, describes the extra HEALTHCHECK for the container"
}

variable "container_command" {
  type        = "list"
  default     = [""]
  description = "container_command, describes the command for the container a a list, leaving default should run docker defined CMD"
}

variable "host_port" {
  default     = ""
  description = "host_port, to be filled in to have a static host port mapping for non-awsvpc ecs, defaults to dynamic port mapping"
}

variable "scaling_properties" {
  description = <<EOF
Scaling properties holds a map of multiple maps defining scaling policies and alarms

 [{
    # type is the metric the metric being used for the service
    type               = "CPUUtilization"
    
    # direction defines the direction of the scaling, up means more tasks, down is less tasks
    direction          = "up"

    # evaluation_periods how many observation points are needed for a scaling decision
    evaluation_periods = "2"

    
    # observation_period is the number of seconds one statistic is measured
    observation_period = "300"

    # statistic defines the type of statistic for measuring SampleCount, Average, Sum, Minimum, Maximum
    statistic          = "Average"

    # threshold defines the value which is needed to surpass, given the direction
    threshold          = "89"

    # Cooldown defines the amount of seconds in which another scaling is disabled after a succesful scaling action
    cooldown           = "900"

    # Adjustment_type defines the type of adjustment, can either be absolute or relative : ChangeInCapacity, ExactCapacity, and PercentChangeInCapacity.
    adjustment_type    = "ChangeInCapacity"

    # scaling_adjustment defines the amount to scale, can be a postive or negative number or percentage
    scaling_adjustment = "1"
  },]
  EOF

  default = []
}

variable "container_envvars" {
  description = <<EOF
container_envvars defines extra container env vars, list of maps:
{ key = val,key2= val2}
  EOF

  default = {}
}

variable "name" {
  description = "The name of the project, must be unique"
}

variable "kms_enabled" {
  default     = false
  description = "Whether to provide access to the supplied kms_keys. If no kms keys are passed, set this to false."
}

variable "kms_keys" {
  default     = []
  description = "List of KMS keys the task has access to"
}

variable "ssm_enabled" {
  default     = false
  description = "Whether to provide access to the supplied ssm_paths. If no ssm paths are passed, set this to false"
}

variable "ssm_paths" {
  default     = []
  description = "List of SSM Paths the task has access to"
}

variable "awsvpc_subnets" {
  default     = []
  description = "AWSVPC ( FARGATE ) need subnets to reside in"
}

variable "awsvpc_security_group_ids" {
  default     = []
  description = "AWSVPC ( FARGATE ) need awsvpc_security_group_ids attached to the task"
}

variable "s3_ro_paths" {
  default     = []
  description = "S3 Read-only paths the Task has access to"
}

variable "s3_rw_paths" {
  default     = []
  description = "S3 Read-write paths the Task has access to"
}

variable "docker_volume" {
  type        = "map"
  default     = {}
  description = "A Docker volume to add to the task"

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

variable "host_path_volumes" {
  type        = "list"
  default     = []
  description = "list of host paths to add as volumes to the task"

  ## Example:
  # host_path_volumes = [{
  #   name = "foo",
  #   host_path = "/tmp/foo"
  # },
  # {
  #   name = "bar",
  #   host_path = "/tmp/bar"
  # },]
}

variable "mountpoints" {
  type        = "list"
  default     = []
  description = "list of mount points to add to every container in the task"

  ## Example 
  # mountpoints = [{
  #   sourceVolume = "foo",
  #   containerPath = "/foo",
  #   readOnly = "false"
  # },
  # {
  #   sourceVolume = "bar",
  #   containerPath = "/bar",
  #   readOnly = "false"
  # },]
}

variable "ecs_cron_tasks" {
  description = <<EOF
ecs_cron_tasks holds a list of maps defining the scheduled jobs which need to run

 [{
    # name of the scheduled task
    job_name  = "vacuum_db"
    
    # expression defined in 
    # http://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
    schedule_expression  = "cron(0 12 * * ? *)"

    # command defines the command which needs to run inside the docker container
    command = "python vacuum_db.py"

  },]
  EOF

  type    = "list"
  default = []

  ## ecs_cron_tasks holds a list of maps defining the scheduled jobs which need to run
  ## Example

  #  ecs_cron_tasks = [{
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
}

variable "service_discovery_enabled" {
  default     = "false"
  description = "service_discovery_enabled enables service discovery"
}

variable "service_discovery_properties_namespace_id" {
  default     = ""
  description = "service_discovery_properties_namespace_id sets the service discovery namespace"
}

variable "service_discovery_properties_dns_ttl" {
  default     = "60"
  description = "service_discovery_properties_dns_ttl sets the service discovery dns ttl"
}

variable "service_discovery_properties_dns_type" {
  default     = "A"
  description = "service_discovery_properties_dns_ttl sets the service discovery dns ttl"
}

variable "service_discovery_properties_routing_policy" {
  default     = "MULTIVALUE"
  description = "The routing policy that you want to apply to all records that Route 53 creates when you register an instance and specify the service. Valid Values: MULTIVALUE, WEIGHTED"
}

variable "service_discovery_properties_healthcheck_custom_failure_threshold" {
  default     = "1"
  description = "The number of 30-second intervals that you want service discovery to wait before it changes the health status of a service instance. Maximum value of 10."
}

variable "tags" {
  description = "A map of tags to apply to all taggable resources"
  type        = "map"
  default     = {}
}

variable "health_check_grace_period_seconds" {
  description = "The amount of seconds to wait before the first health check. Only relevant for load balanced apps. Default 5 minutes"
  default     = 300
}
