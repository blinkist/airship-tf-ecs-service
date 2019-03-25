---
sidebarDepth: 3
---

# Airship Modules

Now that you've setup everything needed for Airship, we need to add the use of the airship modules to get a docker service running. 


## Airship ECS Cluster

::: tip
It's important to have finished the preparation steps before you continue here. 
:::

The [ECS Cluster](https://github.com/blinkist/terraform-aws-airship-ecs-cluster) module will create the ECS Cluster in your region. The module can be used for both ECS Fargate and for running an ECS Cluster on top of EC2 instances. For this example we won't be needing EC2 instances so we configure the module to not use them.

```json
module "ecs" {
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "0.5.1"

  name = "ecs-demo"

  # create_roles defines if we create IAM Roles for EC2 instances
  create_roles = false

  # create_autoscalinggroup defines if we create an ASG for ECS
  create_autoscalinggroup = false
}
```

Apply your added terraform code, in the EC2 Panel on the AWS Console you will see your newly created ECS Cluster.


## Airship ECS Service

Now that we have an ECS Cluster, we need to add an actual service. For this demonstration, we will use a very standard `nginx:stable` docker image. A summary of the specifics of the service. Replace `<YOUR REGION>` with the active AWS region.

- [x] This ECS Service uses Fargate
- [x] The service is place inside a private subnet
- [x] HTTP is automatically redirected to https
- [x] Service is available through HTTPS
- [x] The ALB is polling / on the docker service and checks for a HTTP 200

```json
module "fargate_service" {
  source  = "blinkist/airship-ecs-service/aws"
  version = "0.9.2"

  name = "demo-web"

  ecs_cluster_id = "${module.ecs.cluster_id}"

  region = "<YOUR REGION>"


  fargate_enabled = true

  awsvpc_enabled            = true
  awsvpc_subnets            = ["${module.vpc.private_subnets}"]
  awsvpc_security_group_ids = ["${aws_security_group.ecs_service_sg.id}"]

  load_balancing_type = "application"
  load_balancing_properties {
    # The ARN of the ALB, when left-out the service, 
  load_balancing_properties_lb_arn = "${module.alb_shared_services_external.load_balancer_id}"

  # http listener ARN
  load_balancing_properties_lb_listener_arn = "${element(module.alb_shared_services_external.http_tcp_listener_arns,0)}"

  # The VPC_ID the target_group is being created in
  load_balancing_properties_lb_vpc_id = "${module.vpc.vpc_id}"

  # The route53 zone for which we create a subdomain
  load_balancing_properties_route53_zone_id = "${data.aws_route53_zone.zone.zone_id}"

  # health_uri defines which health-check uri the target 
  # group needs to check on for health_check, defaults to /ping
  load_balancing_properties_health_uri = "/"

  load_balancing_properties_https_enabled = false


  container_cpu = 256
  container_memory = 512
  container_port   = 80
  bootstrap_container_image = "nginx:stable"

  # force_bootstrap_container_image to true will 
  # force the deployment to use var.bootstrap_container_image as container_image
  # if container_image is already deployed, no actual service update will happen
  # force_bootstrap_container_image = false

  # Initial ENV Variables for the ECS Task definition
  container_envvars {
    ENV_VARIABLE = "SOMETHING"
  }
  # capacity_properties defines the size in task for the ECS Service.
  # Without scaling enabled, desired_capacity is the only necessary property
  # defaults to 2
  # With scaling enabled, desired_min_capacity and desired_max_capacity 
  # define the lower and upper boundary in task size
  capacity_properties_desired_capacity = "1"
}
```
