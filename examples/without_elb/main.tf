locals {
  region = "eu-west-1"
}

module "cluster" {
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "0.5.1"

  name                    = "${terraform.workspace}-cluster"
  create_roles            = false
  create_autoscalinggroup = false
}

module "service" {
  source = "../.."

  name                                          = "${terraform.workspace}-service"
  region                                        = "${local.region}"
  fargate_enabled                               = true
  ecs_cluster_id                                = "${module.cluster.cluster_id}"
  awsvpc_enabled                                = true
  awsvpc_subnets                                = ["${data.aws_subnet.selected.id}"]
  awsvpc_security_group_ids                     = ["${data.aws_security_group.selected.id}"]
  load_balancing_type                           = "none"
  load_balancing_properties_route53_record_type = "NONE"
  container_cpu                                 = 256
  container_memory                              = 512
  capacity_properties_desired_capacity          = 1
  capacity_properties_desired_min_capacity      = 1
  capacity_properties_desired_max_capacity      = 1
  bootstrap_container_image                     = "nginx:latest"                             # Obviously not a good candiate for a service without an ELB, but this is just a demo ;)

  # Without the ELB health check, you should provide either a health check in the Docker image or ECS. The one below is an example of the latter.
  container_healthcheck = {
    command     = ["CMD-SHELL", "curl http://localhost/"]
    interval    = 10
    startperiod = 120
    retries     = 3
    timeout     = 5
  }
}
