---
sidebarDepth: 2
---

# Preparation

## VPC

For ECS to work it needs a Virtual Private Cloud to run in, there are many proper pre-built Modules which create a VPC and everything related.
Good examples are [Cloudposse](https://github.com/cloudposse/terraform-aws-vpc) and [terraform-aws-modules](https://github.com/terraform-aws-modules/terraform-aws-vpc) . For this example we use the latter. It's good practice to create public and private subnets, load balancers will reside in the public subnet, the ECS services will be in the private subnets.

```json
# VPC Definition
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.46.0"

  name = "ecs-vpc"
  cidr = "10.50.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  public_subnets  = ["10.50.11.0/24", "10.50.12.0/24"]
  private_subnets = ["10.50.21.0/24", "10.50.22.0/24"]

  single_nat_gateway = true

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
  }
}
```

## Security Groups

ECS will have network components just like EC2, for this example we need a security group for the load balancer, and one for the ecs service. In this example the load balancer allows traffic to HTTP and HTTPS and is allowed all outgoing traffic.

```json
resource "aws_security_group" "lb_sg" {
  name        = "load-balancer-sg"
  description = "Allow all inbound traffic to http and https"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port    = 80
    to_port      = 80
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  ingress {
    from_port    = 443
    to_port      = 443
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "load-balancer-sg"
  }
}
```

The security group `fargate-ecs-service-sg` only allows incoming traffic on port 80 coming from the Load Balancer security group and has no restrictions outgoing.

```json
resource "aws_security_group" "ecs_service_sg" {
  name        = "fargate-ecs-service-sg"
  description = "Allow all inbound traffic to service port"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fargate-ecs-service-sg"
  }
}
```

## Route53 Zone

The ECS Service module by default creates a subdomain in the given zone by the following pattern [name].[domain]. This can be disabled but for this example we will use it. In the preparation step we use a datasource to make sure the zone is there.

```json
data "aws_route53_zone" "zone" {
  name  = "yourdomain_at_route53.com."
}
```

::: warning
This module will create a record inside your existing zone, make sure that there is no overlap with existing records. If you create the certificate, it is best to use DNS validation.
:::

## Application Load Balancer

The ECS Service module can add many ECS Services to the same Application Load Balancer (ALB) by creating hostname based listener rules. For this module to operate with an ALB we need to setup one. We setup a loggin bucket first to make sure the ALB can log to S3.


```json
module "lb_s3_bucket" {
  source        = "cloudposse/lb-s3-bucket/aws"
  version       = "0.1.4"
  namespace     = "dcr"
  stage         = "test"
  name          = "lb-s3-bucket"
  region        = "<YOUR REGION>"
  force_destroy = "true"
}

module "alb_shared_services_external" {
    source                    = "terraform-aws-modules/alb/aws"
    version                   = "3.4.0"
    load_balancer_name        = "ecs-external"
    security_groups           = ["${aws_security_group.lb_sg.id}"]
    load_balancer_is_internal = false
    log_bucket_name           = "${module.lb_s3_bucket.bucket_id}"
    log_location_prefix       = ""
    subnets                   = ["${module.vpc.public_subnets}"]
    tags                      = "${map("Environment", "ECS Test Setup")}"
    vpc_id                    = "${module.vpc.vpc_id}"
    https_listeners           = ""
    https_listeners_count     = "0"
    http_tcp_listeners        = "${list(map("port", "80", "protocol", "HTTP"))}"
    http_tcp_listeners_count  = "1"
    target_groups             = "${list(map("name", "default-ext", "backend_protocol", "HTTP", "backend_port", "80"))}"
    target_groups_count       = "1"
  }

```
