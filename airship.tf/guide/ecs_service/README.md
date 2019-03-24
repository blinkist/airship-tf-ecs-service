---
sidebarDepth: 2
---

# ECS Service

<mermaid/>

## Introduction

This module will create an ECS Service within an existing ECS Cluster and takes care of connecting it to a Load Balancer if configured to. It's highly configurable as there are many ways to operate an ECS Service. This Guide will go through most if not all of the configuration options the module supports. If you have questions, please join the #Airship channel on [Sweetops Slack](http://sweetops.slack.com) or create an issue [here](https://github.com/blinkist/terraform-aws-airship-ecs-service/issues)!

## Contributing

We are happy with contributions! If you see a bug or a lacking feature, feel free to submit a PR. Discussing your ideas first will of course help getting your PR through quicker! Please understand that the module should have as little breaking changes possible within this major release. With HCL2 ( Terraform 0.12 ) breaking changes seem to be inevitable and for this major release, refactoring with new ideas is of course much welcomed.

## Naming Matters

The name you choose for the ECS Service will be interpolated into different resources, for example the Application Load Balancer target groups. Certain AWS resources have a name limitation of 32 characters hence it's important to be economical with the amount of chars you allocate to the cluster name. Once a service has been created it's not possible to rename it, plan wisely.

## Architecture

ALB Connected ECS Service
<div class="mermaid">
graph LR
    subgraph Module Scope
    0
    end
    0[fa:fa-ban DNS Domain ecs_name.zone.tld]-->B[fa:fa-ban ALB]
    B-->C[fa:fa-ban ALB HTTP Listener]
    B-->D[fa:fa-ban ALB HTTPS Listener]
    C-->E[fa:fa-ban LB Listener Rule for ecs_name.zone.tld]
    D-->F[fa:fa-ban LB Listener Rule for ecs_name.zone.tld]
    C-->L[fa:fa-ban LB Listener Rule for custom_domains optional]
    D-->M[fa:fa-ban LB Listener Rule for custom_domains optional]
    subgraph Module Scope
    E-->G[fa:fa-ban Target Group]
    F-->G[fa:fa-ban Target Group]
    L-->G[fa:fa-ban Target Group]
    M-->G[fa:fa-ban Target Group]
    G-->H[fa:fa-ban ECS Service]
    G-->I[fa:fa-ban ECS Service]
    subgraph ECS Cluster
    subgraph ECS Service
    H[fa:fa-ban ECS Task N]
    I[fa:fa-ban ECS Task N+1]
    end
    end
    H-.->J[fa:fa-ban Task Definition:version]
    I-.->J[fa:fa-ban Task Definition:version]
    end
</div>

## Full Example

```json
module "demo_web" {
  source  = "blinkist/airship-ecs-service/aws"
  version = "0.9.1"

  name   = "demo-web"

  ecs_cluster_id = "${local.cluster_id}"

  region = "${local.region}"

  fargate_enabled = true

  # scheduling_strategy = "REPLICA"

  # AWSVPC Block, with awsvpc_subnets defined the network_mode for the ECS task definition will be awsvpc, defaults to bridge
  awsvpc_enabled = true
  awsvpc_subnets            = ["${module.vpc.private_subnets}"]
  awsvpc_security_group_ids = ["${module.demo_sg.this_security_group_id}"]

  # load_balancing_enabled sets if a load balancer will be attached to the ecs service / target group
  load_balancing_type = "application"

  # The ARN of the ALB, when left-out the service, will not be attached to a load-balance
  load_balancing_properties_lb_arn                = "${module.alb_shared_services_ext.load_balancer_id}"
  # https listener ARN
  load_balancing_properties_lb_listener_arn_https = "${element(module.alb_shared_services_ext.https_listener_arns,0)}"

  # http listener ARN
  load_balancing_properties_lb_listener_arn       = "${element(module.alb_shared_services_ext.http_tcp_listener_arns,0)}"

  # The VPC_ID the target_group is being created in
  load_balancing_properties_lb_vpc_id             = "${module.vpc.vpc_id}"

  # The route53 zone for which we create a subdomain
  load_balancing_properties_route53_zone_id       = "${aws_route53_zone.shared_ext_services_domain.zone_id}"

  # After which threshold in health check is the task marked as unhealthy, defaults to 3
  # load_balancing_properties_unhealthy_threshold   = "3"

  # load_balancing_properties_health_uri defines which health-check uri the target group needs to check on for health_check, defaults to /ping
  # load_balancing_properties_health_uri = "/ping"

  # The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused.
  # load_balancing_properties_deregistration_delay = "300"

  # Creates a listener rule which redirects to https
  # load_balancing_properties_redirect_http_to_https = false

  # custom_listen_hosts defines extra listener rules to route to the ALB Targetgroup
  custom_listen_hosts    = ["www.example.com"]

  container_cpu    = 256
  container_memory = 512
  container_port   = 80

  # force_bootstrap_container_image to true will force the deployment to use var.bootstrap_container_image as container_image
  # if container_image is already deployed, no actual service update will happen
  # force_bootstrap_container_image = false
  bootstrap_container_image = "nginx:stable"

  # Initial ENV Variables for the ECS Task definition
  container_envvars  {
       TASK_TYPE = "web"
  }

  # capacity_properties defines the size in task for the ECS Service.
  # Without scaling enabled, desired_capacity is the only necessary property, defaults to 2
  # With scaling enabled, desired_min_capacity and desired_max_capacity define the lower and upper boundary in task size
  capacity_properties_desired_capacity     = "2"
  capacity_properties_desired_min_capacity = "2"
  capacity_properties_desired_max_capacity = "2"

  # https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html
  scaling_properties = [
    {
      type               = "CPUUtilization"
      direction          = "up"
      evaluation_periods = "2"
      observation_period = "300"
      statistic          = "Average"
      threshold          = "89"
      cooldown           = "900"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = "1"
    },
    {
      type               = "CPUUtilization"
      direction          = "down"
      evaluation_periods = "4"
      observation_period = "300"
      statistic          = "Average"
      threshold          = "10"
      cooldown           = "300"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = "-1"
    },
  ]

  # ecs_cron_tasks holds a list of maps defining scheduled jobs
  # when ecs_cron_tasks holds at least one 'job' a lambda will be created which will
  # trigger jobs with the currently running task definition. The given command will be used
  # to override the CMD in the dockerfile. The lambda will prepend this command with ["/bin/sh", "-c" ]
  # ecs_cron_tasks = [{
  #   # name of the scheduled task
  #   job_name            = "vacuum_db"
  #   # expression defined in
  #   # http://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
  #   schedule_expression = "cron(0 12 * * ? *)"
  #
  #   # command defines the command which needs to run inside the docker container
  #   command             = "/usr/local/bin/vacuum_db"
  # }]


  # The KMS Keys which can be used for kms:decrypt
  kms_keys  = ["${module.global-kms.aws_kms_key_arn}", "${module.demo-kms.aws_kms_key_arn}"]

  # The SSM paths for which the service will be allowed to ssm:GetParameter and ssm:GetParametersByPath on
  #
  # https://medium.com/@tdi/ssm-parameter-store-for-keeping-secrets-in-a-structured-way-53a25d48166a
  # "arn:aws:ssm:region:123456:parameter/application/%s/*"
  #TODO
  ssm_paths = ["${module.global-kms.name}", "${module.demo-kms.name}"]

  # s3_ro_paths define which paths on S3 can be accessed from the ecs service in read-only fashion.
  s3_ro_paths = []

  # s3_ro_paths define which paths on S3 can be accessed from the ecs service in read-write fashion.
  s3_rw_paths = []
}
```
