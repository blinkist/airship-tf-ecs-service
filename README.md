# AWS ECS Service Terraform Module [![Build Status](https://travis-ci.org/blinkist/terraform-aws-airship-ecs-service.svg?branch=master)](https://travis-ci.org/blinkist/terraform-aws-airship-ecs-service) [![Slack Community](https://slack.cloudposse.com/badge.svg)](https://slack.cloudposse.com)

![](https://raw.githubusercontent.com/blinkist/airship-tf-ecs-service/master/_readme_resources/airship.png)

## Introduction

ECS is AWS's original offering for Docker Orchestration. Although less feature rich than Kubernetes (EKS), it has proved to be an extremely stable platform for hosting stateless Docker services. This Terraform module is meant to be a one-size-fits-all ECS Service module. A module which makes it easy for any developer to create an ECS Service, have it attached to a load balancer, automatically grant it the necessary IAM permissions, and add extra scaling properties. By design it's not meant to update the ECS Services through Terraform once they have been created; rather, this is better handled by other open source projects like https://github.com/silinternational/ecs-deploy 

### Application Load Balancer (ALB) attachment

![](https://raw.githubusercontent.com/blinkist/airship-tf-ecs-service/master/_readme_resources/alb_public.png)

By using the rule-based forwarding features of ALB, this module uses one ALB for many different microservices. For each ECS Service connected to a Load Balancer, a _Listener Rule_ is made based on the host-header (domain-name) of the ECS Service. Traffic is forwarded to them by the module-created _TargetGroup_ of the ECS Service.

When the module has ALB properties defined it will be connected to an Application Load Balancer by creating:
1. a `lb_listener_rule` based on the name of the service.
* 1a. (optional) a `lb_listener_rule` based on the variable `custom_listen_hosts`
2.  a route53 record inside the Route 53 Zone pointing to the load balancer.

This works for both externally visible services and for internally visible services. In this example we have:


```
  Company domain: mycorp.com

  Terraform development external route53 domain:     dev.mycorp.com
  Terraform development internal route53 domain: dev-int.mycorp.com
  
  == Internet-Facing ALB  *.dev.mycorp.com == 

  api.dev.mycorp. => api ecs service
  web.dev.mycorp. => web ecs service
```


### "Service Discovery" ALB Based

![](https://raw.githubusercontent.com/blinkist/airship-tf-ecs-service/master/_readme_resources/alb_discovery.png)

Unlike Kubernetes-style service discovery based on DNS, which lacks connection draining, ALB discovery adds a service to a load balancer and takes care of draining connections the moment an update takes place. One ALB can have multiple microservices as a backend by creating Layer 4-7 rules for the HTTP Host Header. Based on the `Host:` header, traffic will be forwarded to an ECS Service.

```
  [ name ] . [ route53_zone domain ]
```

In case `dev-int.mycorp.com` is used as domain for the internal ALB, the route53 records are being created which can be used by other ECS Services to connect to.
```
  == Internal ALB  *.dev-int.mycorp.com == 
  books.dev-int.mycorp. => micro1 ecs service
  mail.dev-int.mycorp. => micro2 ecs service
  micro3.dev-int.mycorp. => micro3 ecs service
  micro4.dev-int.mycorp. => micro4 ecs service
```

### KMS and SSM Management

AWS Systems Manager (also known as SSM) is the preferred way to store application parameters securely instead of using environment variables. The ECS module provides a way to give access to certain paths inside the [SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html). The full path which is given access to is being interpolated as such: "arn:aws:ssm:region:123456:parameter/application/%s/*". Parameters encrypted with KMS
will be automatically decrypted by most of the AWS libraries as long as the ECS Service also has access to the KMS key.

https://github.com/remind101/ssm-env

https://medium.com/@tdi/ssm-parameter-store-for-keeping-secrets-in-a-structured-way-53a25d48166a

### S3 Access

The module also provide simple access to S3 by the variables s3_ro_paths, and s3_rw_paths. In case the list is populated with S3 bucket names and folders, e.g. ["bucketname1/path","bucketname1/path2","bucketname3"], the module will ensure the ECS Service will have access to these resources, in either read only or read-write fashion, depending on if s3_ro_paths or s3_rw_paths have been used. Again, if KMS is used for encrypting S3 storage, the module need to be provided with the that KMS Key id.

### Cloudwatch logging

The default logging driver configured for the ECS Service is AWS Logging.

### Extra permissions

The Role ARN of the ECS Service is exported, and can be used to add other permissions e.g. to allow a service to make a cloudfront invalidation.

## Features
* [x] Has an integrated workaround to cope with the state drift when deploying new Task definitions externally
* [x] Can be conditionally created
* [x] Creates all necessary IAM Roles for running an ECS Service
* [x] Integrated IAM Permissions for KMS
* [x] Integrated IAM Permissions for SSM
* [x] Integrated IAM Permissions for S3
* [x] Creation of an ECS service, with/without AWSVPC, with/without FARGATE
* [x] Creation of ECS Task definition for use with/without AWSVPC, with/without FARGATE 
* [x] Integrated Cloudwatch Logging
* [x] Integrated Service Scaling
* [x] Handling of Creating listener rules to one ALB
* [x] Exports role arn for adding permissions 
* [x] Deregistration delay parameter allows for fast deployments
* [x] The scheduling_strategy DAEMON/REPLICA can be set 
* [x] Adding of Volumes / Mountpoints in case Docker Volume Drivers are used.
* [x] HTTP to HTTP Redirect functionality
* [x] Cognito Auth for https endpoints
* [x] Scheduled 'jobs' (tasks) through AWS Lambda
* [x] Support for services connected to a Network Load Balancer
* [ ] ECS Service discovery
* [ ] Path based ALB Rules
* [ ] SSL SNI Adding for custom hostnames
* [ ] Integrated IAM Permissions for *

## Simple ECS Service on Fargate with ALB Attached, together with a simple non ALB attached worker

```hcl

module "demo_web" {
  source  = "blinkist/airship-ecs-service/aws"
  version = "0.8.3"

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
  load_balancing_properties {
    # The default route53 record type, can be CNAME, ALIAS or NONE
    # route53_record_type = "ALIAS"

    # Unique identifier for the weighted IN A Alias Record 
    # route53_a_record_identifier = "identifier"

    # The ARN of the ALB, when left-out the service, will not be attached to a load-balance
    lb_arn                = "${module.alb_shared_services_ext.load_balancer_id}"
    # https listener ARN
    lb_listener_arn_https = "${element(module.alb_shared_services_ext.https_listener_arns,0)}"

    # http listener ARN
    lb_listener_arn       = "${element(module.alb_shared_services_ext.http_tcp_listener_arns,0)}"

    # The VPC_ID the target_group is being created in
    lb_vpc_id             = "${module.vpc.vpc_id}"

    # The route53 zone for which we create a subdomain
    route53_zone_id       = "${aws_route53_zone.shared_ext_services_domain.zone_id}"

    # After which threshold in health check is the task marked as unhealthy, defaults to 3
    # unhealthy_threshold   = "3"

    # health_uri defines which health-check uri the target group needs to check on for health_check, defaults to /ping
    # health_uri = "/ping"

    # The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. 
    # deregistration_delay = "300"

    # Creates a listener rule which redirects to https
    # redirect_http_to_https = false

    # cognito_auth_enabled is set when cognito authentication is used for the https listener
    # Important to have redirect_http_to_https set to true as http authentication is only added to the https listener

    # cognito_auth_enabled = false
 
    # cognito_user_pool_arn defines the cognito user pool arn for the added cognito authentication
    # cognito_user_pool_arn = ""
 
    # cognito_user_pool_client_id defines the cognito_user_pool_client_id
    # cognito_user_pool_client_id = ""
 
    # cognito_user_pool_domain sets the domain of the cognito_user_pool
    # cognito_user_pool_domain = ""
  }

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
  capacity_properties {
    #desired_capacity     = "2"
    #desired_min_capacity = "2"
    #desired_max_capacity = "2"
  }

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

module "demo_web" {
  source  = "blinkist/airship-ecs-service/aws"

  version = "0.8.3"

  name   = "demo-worker"

  region         = "eu-central-1"

  ecs_cluster_id = "${module.ecs.cluster_id}"

  fargate_enabled = true
  awsvpc_enabled = true

  # scheduling_strategy = "REPLICA"

  # AWSVPC Block, with awsvpc_subnets defined the network_mode for the ECS task definition will be awsvpc, defaults to bridge 
  awsvpc_subnets            = ["${module.vpc.private_subnets}"]
  awsvpc_security_group_ids = ["${module.demo_sg.this_security_group_id}"]

  # load_balancing_type = "none"


  container_cpu    = 256
  container_memory = 512
  container_port   = 80
  bootstrap_container_image  = "nginx:latest"

  # Initial ENV Variables for the ECS Task definition
  container_envvars  {
       TASK_TYPE = "worker" 
  } 

  capacity_properties {
    desired_capacity     = "1"
  }

  kms_keys  = ["${module.global-kms.aws_kms_key_arn}", "${module.demo-kms.aws_kms_key_arn}"]
  ssm_paths = ["${module.global-kms.name}", "${module.demo-kms.name}"]
}


```

## Simple ECS Service on EC2-ECS with ALB Attached and no autoscaling

```hcl

module "demo_web" {
  source  = "blinkist/airship-ecs-service/aws"
  version = "0.8.3"

  name   = "demo5-web"

  ecs_cluster_id = "${local.cluster_id}"

  region         = "eu-central-1"

  # scheduling_strategy = "REPLICA"

  load_balancing_type = "application"
  load_balancing_properties {
    # The default route53 record type, currently CNAME to be backwards compatible
    route53_record_type = "ALIAS"
    # Unique identifier for the weighted IN A Alias Record 
    # route53_record_identifier = "identifier"
    lb_arn                = "${module.alb_shared_services_ext.load_balancer_id}"
    lb_listener_arn_https = "${element(module.alb_shared_services_ext.https_listener_arns,0)}"
    lb_listener_arn       = "${element(module.alb_shared_services_ext.http_tcp_listener_arns,0)}"
    lb_vpc_id             = "${module.vpc.vpc_id}"
    route53_zone_id       = "${aws_route53_zone.shared_ext_services_domain.zone_id}"
    unhealthy_threshold   = "3"
    health_uri = "/ping"
  }

  container_cpu    = 256
  container_memory = 512
  container_port   = 80
  bootstrap_container_image  = "nginx:latest"

  # Initial ENV Variables for the ECS Task definition
  container_envvars  {
       SSM_ENABLED = "true"
       TASK_TYPE = "web" 
  } 

  # capacity_properties defines the size in task for the ECS Service.
  # Without scaling enabled, desired_capacity is the only necessary property
  # With scaling enabled, desired_min_capacity and desired_max_capacity define the lower and upper boundary in task size
  capacity_properties {
    desired_capacity     = "2"
  }

  # The KMS Keys which can be used for kms:decrypt
  kms_keys  = ["${module.global-kms.aws_kms_key_arn}", "${module.demo-kms.aws_kms_key_arn}"]

  # The SSM paths for which the service will be allowed to ssm:GetParameter and ssm:GetParametersByPath on
  ssm_paths = ["${module.global-kms.name}", "${module.demo-kms.name}"]
}

```

## ECS Service on EC2-ECS with AWS-VPC and a Network Load Balancer Attached without autoscaling

```hcl

module "demo_nlb" {
  source  = "blinkist/airship-ecs-service/aws"
  version = "0.8.3"

  name   = "demo-nlb"

  ecs_cluster_id = "${local.cluster_id}"

  region         = "eu-central-1"

  awsvpc_enabled = true
  awsvpc_subnets            = ["${module.vpc.private_subnets}"]
  awsvpc_security_group_ids = ["${module.demo_sg.this_security_group_id}"]


  load_balancing_type = "network"
  load_balancing_properties {
    route53_record_type = "ALIAS"
    lb_arn                = "${module.nlb.load_balancer_id}"
    lb_vpc_id             = "${module.vpc.vpc_id}"
    route53_zone_id       = "${aws_route53_zone.shared_ext_services_domain.zone_id}"
    # unhealthy_threshold   = "3"
    # nlb_listener_port sets the port of the lb_listener
    # nlb_listener_port = 80
  }

  container_cpu    = 256
  container_memory = 512
  container_port   = 80
  bootstrap_container_image  = "nginx:latest"

  # Initial ENV Variables for the ECS Task definition
  container_envvars  {
       SSM_ENABLED = "true"
       TASK_TYPE = "web" 
  } 

  # capacity_properties defines the size in task for the ECS Service.
  # Without scaling enabled, desired_capacity is the only necessary property
  # With scaling enabled, desired_min_capacity and desired_max_capacity define the lower and upper boundary in task size
  capacity_properties {
    desired_capacity     = "1"
  }

  # The KMS Keys which can be used for kms:decrypt
  kms_keys  = ["${module.global-kms.aws_kms_key_arn}", "${module.demo-kms.aws_kms_key_arn}"]

  # The SSM paths for which the service will be allowed to ssm:GetParameter and ssm:GetParametersByPath on
  ssm_paths = ["${module.global-kms.name}", "${module.demo-kms.name}"]
}

```


## Outputs

| Name | Description |
|------|-------------|
| ecs_taskrole_arn | The ARN of the Task IAM Role |
| ecs_taskrole_name | The name of the ECS Task IAM Role |
| lb_target_group_arn | The arn of the Target Group |

## Help

**Got a question?**

File a GitHub [issue](https://github.com/blinkist/terraform-aws-airship-ecs-service/issues), [Slack Community](https://slack.cloudposse.com) in the #airship channel.
