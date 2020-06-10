terraform {
  required_version = ">= 0.12"
}

locals {
  ecs_cluster_name = basename(var.ecs_cluster_id)
  launch_type      = var.fargate_enabled ? "FARGATE" : "EC2"

  name_map = {
    "Name" = "${local.ecs_cluster_name}-${var.name}"
  }

  tags = merge(var.tags, local.name_map)
}

#
# The iam sub-module creates the IAM resources needed for the ECS Service.
#
locals {
  # ARNs for any Secrets Manager secrets used for container secrets
  config_secret_arns = flatten([for val in values(var.container_secrets):
                                regexall("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]+:secret:.+", val)])
  # above plus the credentials secret ARN, if any
  secret_arns = compact(flatten(concat(local.config_secret_arns, [var.repository_credentials_secret_arn])))
}

module "iam" {
  source = "./modules/iam/"

  # Name
  name = "${local.ecs_cluster_name}-${var.name}"

  # Create defines if any resources need to be created inside the module
  create = var.create

  # cluster_id
  ecs_cluster_id = var.ecs_cluster_id

  # Region ..
  region = var.region

  # kms_enabled sets whether this ecs_service should be able to access the given KMS keys.
  # Defaults to true; if no kms_paths are given, set this to false.
  kms_enabled = var.kms_enabled

  # kms_keys define which KMS keys this ecs_service can access.
  kms_keys = var.kms_keys

  # ssm_enabled sets whether this ecs_service should be able to access the given SSM paths.
  # Defaults to true; if no ssm_paths are given, set this to false.
  ssm_enabled = var.ssm_enabled

  # ssm_paths define which SSM paths the ecs_service can access
  ssm_paths = var.ssm_paths

  # The container uses Secrets Manager secrets and needs a task
  # execution role to get access to them
  secretsmanager_enabled = var.container_secrets_enabled

  # repository_credentials_secret_arn is the Secrets Manager secret
  # containing credentials for an external Docker repo
  secretsmanager_secret_arns = local.secret_arns

  # s3_ro_paths define which paths on S3 can be accessed from the ecs service in read-only fashion.
  s3_ro_paths = var.s3_ro_paths

  # s3_rw_paths define which paths on S3 can be accessed from the ecs service in read-write fashion.
  s3_rw_paths = var.s3_rw_paths

  # In case Fargate is enabled an extra role needs to be added
  fargate_enabled = var.fargate_enabled

  # If this is a scheduled task, cloudwatch needs permission to start the task
  is_scheduled_task = var.is_scheduled_task

  # If we're using the Lambda-based task scheduler, create a role and policy for it
  task_scheduler_enabled = length(var.ecs_cron_tasks) > 0

  # Propagate tags to IAM resources
  tags = local.tags
}

#
# The lb-handling sub-module creates everything regarding the connection of an ecs service to an Application Load Balancer# or or Network Load Balancer, it is called alb_handling for legacy reasons, TODO hcl2 refactor
module "alb_handling" {
  source = "./modules/alb_handling/"

  name         = var.name
  cluster_name = local.ecs_cluster_name

  # Create defines if we need to create resources inside this module
  create = var.create && var.load_balancing_type != "none" ? true : false

  # load_balancing_type sets the type, either "none", "application", or "network"
  load_balancing_type = var.load_balancing_type

  # lb_vpc_id sets the VPC ID of where the LB resides
  lb_vpc_id = var.load_balancing_properties_lb_vpc_id

  # lb_arn defines the arn of the LB
  lb_arn = var.load_balancing_properties_lb_arn

  # lb_listener_arn is the arn of the listener ( HTTP )
  lb_listener_arn = var.load_balancing_properties_lb_listener_arn

  # lb_listener_arn_https is the arn of the listener ( HTTPS )
  lb_listener_arn_https = var.load_balancing_properties_lb_listener_arn_https

  # nlb_listener_port sets the listener port of the nlb listener
  nlb_listener_port = var.load_balancing_properties_nlb_listener_port

  # target_group_port sets the port of the target group, by default 80 
  target_group_port = var.load_balancing_properties_target_group_port

  # unhealthy_threshold defines the threashold for the target_group after which a service is seen as unhealthy.
  unhealthy_threshold = var.load_balancing_properties_unhealthy_threshold

  healthy_threshold = var.load_balancing_properties_healthy_threshold

  # if http_enabled is true, listener rules are made for a non-HTTPS listener
  http_enabled = var.load_balancing_properties_http_enabled

  # if https_enabled is true, listener rules are made for the ssl listener
  https_enabled = var.load_balancing_properties_https_enabled

  # Sets the deregistration_delay for the targetgroup
  deregistration_delay = var.load_balancing_properties_deregistration_delay

  # route53_record_type sets the record type of the route53 record, can be ALIAS, CNAME or NONE,  defaults to ALIAS
  # In case of NONE no record will be made
  route53_record_type = var.is_scheduled_task ? "NONE" : var.load_balancing_properties_route53_record_type

  # Sets the zone in which the sub-domain will be added for this service
  route53_zone_id = var.load_balancing_properties_route53_zone_id

  # Sets name for the sub-domain, we default to *name
  route53_name = var.load_balancing_properties_route53_custom_name == "" ? var.name : var.load_balancing_properties_route53_custom_name

  # route53_a_record_identifier sets the identifier of the weighted Alias A record
  route53_record_identifier = var.load_balancing_properties_route53_record_identifier

  # custom_listen_hosts will be added as a host route rule as aws_lb_listener_rule to the given service e.g. www.domain.com -> Service
  custom_listen_hosts = var.load_balancing_properties_custom_listen_hosts

  custom_listen_hosts_count = var.load_balancing_properties_custom_listen_hosts_count

  # redirect_http_to_https creates lb listeners which redirect incoming http traffic to https
  redirect_http_to_https = var.load_balancing_properties_redirect_http_to_https

  # health_uri defines which health-check uri the target group needs to check on for health_check
  health_uri = var.load_balancing_properties_health_uri

  # health_port defines port of the health-check
  health_port = var.load_balancing_properties_health_port

  # The expected HTTP status for the health check to be marked healthy
  # You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299")
  health_matcher = var.load_balancing_properties_health_matcher

  # target_type is the alb_target_group target, in case of EC2 it's instance, in case of FARGATE it's IP
  target_type = var.awsvpc_enabled ? "ip" : "instance"

  # cognito_auth_enabled is set when cognito authentication is used for the https listener
  cognito_auth_enabled = var.load_balancing_properties_cognito_auth_enabled

  # cognito_user_pool_arn defines the cognito user pool arn for the added cognito authentication
  cognito_user_pool_arn = var.load_balancing_properties_cognito_user_pool_arn

  # cognito_user_pool_client_id defines the cognito_user_pool_client_id
  cognito_user_pool_client_id = var.load_balancing_properties_cognito_user_pool_client_id

  # cognito_user_pool_domain sets the domain of the cognito_user_pool
  cognito_user_pool_domain = var.load_balancing_properties_cognito_user_pool_domain

  # Propagate tags to ALB resources
  tags = local.tags
}

###### CloudWatch Logs
resource "aws_cloudwatch_log_group" "app" {
  count             = var.create ? 1 : 0
  name              = "${local.ecs_cluster_name}/${var.name}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.cloudwatch_kms_key
  tags              = local.tags
}

#
# This module is used to lookup the currently used ecs task definition
#
module "live_task_lookup" {
  source                       = "./modules/live_task_lookup/"
  create                       = var.create
  ecs_cluster_id               = var.ecs_cluster_id
  ecs_service_name             = var.name
  container_name               = var.container_name
  lambda_lookup_role_policy_id = module.iam.lambda_lookup_role_policy_id
  lambda_lookup_role_arn       = module.iam.lambda_lookup_role_arn
  lookup_type                  = var.live_task_lookup_type
  lambda_runtime               = var.live_task_lookup_lambda_runtime
  tags                         = local.tags
}

#
# Container_definition
#
module "container_definition" {
  source            = "./modules/ecs_container_definition/"
  container_name    = var.container_name
  container_command = var.container_command

  # if var.force_bootstrap_container_image is enabled, we always take the terraform param as container_image
  # otherwise we take the image from the datasource lookup
  # when the lookup has '<ECS_SERVICE_DOES_NOT_EXIST_YET>' as result, the bootstrap image is taken
  container_image = var.force_bootstrap_container_image ? var.bootstrap_container_image : module.live_task_lookup.image == "<ECS_SERVICE_DOES_NOT_EXIST_YET>" ? var.bootstrap_container_image : module.live_task_lookup.image

  container_cpu                = var.container_cpu
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation

  container_init_process_enabled = var.container_init_process_enabled

  ulimit_name       = var.container_ulimit_name
  ulimit_soft_limit = var.container_ulimit_soft_limit
  ulimit_hard_limit = var.container_ulimit_hard_limit

  container_port = var.container_port
  host_port      = var.awsvpc_enabled ? var.container_port : var.host_port
  extra_ports    = var.extra_ports

  hostname = var.awsvpc_enabled ? "" : var.name

  container_envvars = var.container_envvars
  container_secrets = var.container_secrets

  repository_credentials_secret_arn = var.repository_credentials_secret_arn

  container_docker_labels = var.container_docker_labels

  mountpoints = var.mountpoints

  healthcheck_cmd     = var.container_healthcheck_cmd
  healthcheck_timings = var.container_healthcheck_timings

  log_options = {
    "awslogs-region"        = var.region
    "awslogs-group"         = element(concat(aws_cloudwatch_log_group.app.*.name, [""]), 0)
    "awslogs-stream-prefix" = var.name
  }

  tags = local.tags
}

#
# The ecs_task_definition sub-module creates the ECS Task definition
# 
module "ecs_task_definition" {
  source = "./modules/ecs_task_definition/"

  create = var.create

  # The name of the task_definition (generally, a combination of the cluster name and the service name)
  name = "${local.ecs_cluster_name}-${var.name}"

  cluster_name = local.ecs_cluster_name

  container_definitions = module.container_definition.json

  # awsvpc_enabled sets if the ecs task definition is awsvpc 
  awsvpc_enabled = var.awsvpc_enabled

  # fargate_enabled sets if the ecs task definition has launch_type FARGATE
  fargate_enabled = var.fargate_enabled

  # Sets the task cpu needed for fargate when enabled
  cpu = var.fargate_enabled ? var.container_cpu : ""

  # Sets the task memory which is mandatory for Fargate, option for EC2
  memory = var.fargate_enabled ? var.container_memory : ""

  # ecs_taskrole_arn sets the IAM role of the task.
  ecs_taskrole_arn = module.iam.ecs_taskrole_arn

  # ecs_task_execution_role_arn sets the task-execution role needed for FARGATE. This role is also empty in case of EC2
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn

  # Launch type, either EC2 or FARGATE
  launch_type = local.launch_type

  # region, needed for Logging.. 
  region = var.region

  # a Docker volume to add to the task
  docker_volume = var.docker_volume

  # list of host paths to add as volumes to the task
  host_path_volumes = var.host_path_volumes

  # propagate tags to task definition
  tags = local.tags
}

#
# The ecs_task_definition_selector filters ... In most cases new task definitions get created which are
# a copy of the live task definitions. ecs_task_definition_selector checks if there is a difference
# if there isn't a difference then the current live one should be used to be deployed; this
# way no actual deployment will happen.
module "ecs_task_definition_selector" {
  source = "./modules/ecs_task_definition_selector/"

  # Create defines if we need to create resources inside this module
  create = var.create

  ecs_container_name = var.container_name

  # Terraform state task definition
  aws_ecs_task_definition_family   = module.ecs_task_definition.aws_ecs_task_definition_family
  aws_ecs_task_definition_revision = module.ecs_task_definition.aws_ecs_task_definition_revision

  # Live ecs task definition
  live_aws_ecs_task_definition_revision           = module.live_task_lookup.revision
  live_aws_ecs_task_definition_image              = module.live_task_lookup.image
  live_aws_ecs_task_definition_cpu                = module.live_task_lookup.cpu
  live_aws_ecs_task_definition_memory             = module.live_task_lookup.memory
  live_aws_ecs_task_definition_memory_reservation = module.live_task_lookup.memory_reservation
  live_aws_ecs_task_definition_environment_json   = module.live_task_lookup.environment_json
  live_aws_ecs_task_definition_docker_label_hash  = module.live_task_lookup.docker_label_hash
  live_aws_ecs_task_definition_secrets_hash       = module.live_task_lookup.secrets_hash
}

#
# The ecs_service sub-module creates the ECS Service
# 
module "ecs_service" {
  source = "./modules/ecs_service/"

  name = var.name

  # create defines if resources are being created inside this module
  create = var.create && !var.is_scheduled_task

  cluster_id = var.ecs_cluster_id

  awsvpc_enabled = var.awsvpc_enabled

  # launch_type either EC2 or FARGATE
  launch_type = local.launch_type

  selected_task_definition = module.ecs_task_definition_selector.selected_task_definition_for_deployment

  # deployment_controller_type sets the deployment type
  # ECS for Rolling update, and CODE_DEPLOY for Blue/Green deployment via CodeDeploy
  deployment_controller_type = var.deployment_controller_type

  # deployment_maximum_percent sets the maximum size of the deployment in % of the normal size.
  deployment_maximum_percent = var.capacity_properties_deployment_maximum_percent

  # deployment_minimum_healthy_percent sets the minimum % in capacity at deployment
  deployment_minimum_healthy_percent = var.capacity_properties_deployment_minimum_healthy_percent

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  # load_balancing_type sets the type, either "none", "application", or "network"
  load_balancing_type = var.load_balancing_type

  # awsvpc_subnets defines the subnets for an awsvpc ecs module
  awsvpc_subnets = var.awsvpc_subnets

  # awsvpc_security_group_ids defines the vpc_security_group_ids for an awsvpc module
  awsvpc_security_group_ids = var.awsvpc_security_group_ids

  # assign_public_ip is whether to assign a public IP address to an awsvpc service
  assign_public_ip = var.assign_public_ip

  # lb_target_group_arn sets the arn of the target_group the service needs to connect to
  lb_target_group_arn = module.alb_handling.lb_target_group_arn

  # desired_capacity sets the initial capacity in task of the ECS Service, ignored when scheduling_strategy is DAEMON
  desired_capacity = var.capacity_properties_desired_capacity

  # scheduling_strategy
  scheduling_strategy = var.scheduling_strategy

  # with_placement_strategy, if true spread tasks over ECS Cluster based on AZ, Instance-id, Memory
  with_placement_strategy = var.with_placement_strategy

  # container_name sets the name of the container, this is used for the load balancer section inside the ecs_service to connect to a container_name defined inside the 
  # task definition, container_port sets the port for the same container.
  container_name = var.container_name

  container_port = var.container_port

  # This way we force the aws_lb_listener_rule to have finished before creating the ecs_service
  aws_lb_listener_rules = module.alb_handling.aws_lb_listener_rules

  # https://aws.amazon.com/blogs/aws/amazon-ecs-service-discovery/
  # service_discovery_enabled defaults to false
  service_discovery_enabled = var.service_discovery_enabled

  # Should error when service_discovery_enabled is set and no namespace_id is given
  service_discovery_namespace_id = var.service_discovery_properties_namespace_id

  # ttl of the service discovery records, default 60
  service_discovery_dns_ttl = var.service_discovery_properties_dns_ttl

  # dns_type defaults to A (AWSVPC)
  service_discovery_dns_type = var.service_discovery_properties_dns_type

  # service_discovery_properties_routing_policy
  service_discovery_routing_policy = var.service_discovery_properties_routing_policy

  # healthcheck_custom_failure_threshold needed, set to 1 by default
  service_discovery_healthcheck_custom_failure_threshold = var.service_discovery_properties_healthcheck_custom_failure_threshold

  # tags
  tags = local.tags
}

#
# This modules sets the scaling properties of the ECS Service
#
module "ecs_autoscaling" {
  source = "./modules/ecs_autoscaling/"

  # create defines if resources inside this module are being created.
  create = var.create && false == var.is_scheduled_task && length(var.scaling_properties) > 0 ? true : false

  cluster_name = local.ecs_cluster_name

  # ecs_service_name is derived from the actual ecs_service, this to force dependency at creation.
  ecs_service_name = module.ecs_service.ecs_service_name

  # desired_min_capacity, in case of autoscaling, desired_min_capacity sets the minimum size in tasks
  desired_min_capacity = var.capacity_properties_desired_min_capacity

  # desired_max_capaity, in case of autoscaling, desired_max_capacity sets the maximum size in tasks
  desired_max_capacity = var.capacity_properties_desired_max_capacity

  # scaling_properties holds a list of maps with the scaling properties defined.
  scaling_properties = var.scaling_properties

  tags = local.tags
}

# This modules creates scheduled tasks for the ecs service. This is not the same as ECS scheduled tasks! 
# Instead it runs a command inside an existing task, similar to a cron job on that task.
module "lambda_ecs_task_scheduler" {
  source = "./modules/lambda_ecs_task_scheduler/"

  # create defines if resources inside this module are being created.
  create = var.create && false == var.is_scheduled_task && length(var.ecs_cron_tasks) > 0 ? true : false

  ecs_cluster_id = var.ecs_cluster_id

  container_name = var.container_name

  # ecs_service_name is derived from the actual ecs_service, this to force dependency at creation.
  ecs_service_name = module.ecs_service.ecs_service_name

  # var.ecs_scheduled_tasks holds a list with maps regarding the scheduled tasks
  ecs_cron_tasks = var.ecs_cron_tasks

  # lambda_ecs_task_scheduler_role_arn sets the role arn of the task scheduling lambda
  lambda_ecs_task_scheduler_role_arn = module.iam.lambda_ecs_task_scheduler_role_arn

  lambda_runtime = var.lambda_ecs_task_scheduler_runtime

  tags = local.tags
}

# ECS scheduled task configuration. This uses a CloudWatch rulle to start an ECS task at given intervals.
data "aws_ecs_cluster" "this" {
  cluster_name = var.ecs_cluster_id
}

resource "aws_cloudwatch_event_rule" "scheduled_task" {
  count               = var.is_scheduled_task ? 1 : 0
  name                = "${length(var.scheduled_task_name) == 0 ? var.name : var.scheduled_task_name}_scheduled_task"
  description         = "Run ${var.name} task at a scheduled time (${var.scheduled_task_expression})"
  schedule_expression = var.scheduled_task_expression
  tags                = local.tags
}

data "aws_caller_identity" "current" {
}

resource "aws_cloudwatch_event_target" "scheduled_task" {
  count    = var.is_scheduled_task ? 1 : 0
  rule     = aws_cloudwatch_event_rule.scheduled_task[0].name
  arn      = data.aws_ecs_cluster.this.arn
  role_arn = module.iam.scheduled_task_cloudwatch_role_arn

  ecs_target {
    group               = var.scheduled_task_group
    launch_type         = local.launch_type
    task_count          = var.scheduled_task_count
    task_definition_arn = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/${module.ecs_task_definition_selector.selected_task_definition_for_deployment}"

    network_configuration {
      subnets         = var.awsvpc_subnets
      security_groups = var.awsvpc_security_group_ids
    }
  }
}

