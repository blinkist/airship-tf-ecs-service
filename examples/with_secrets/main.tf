terraform {
  required_version = "~> 0.11.0"
}

locals {
  region = "eu-west-1"
}

provider "aws" {
  region                      = "${local.region}"
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  version                     = "~> 2.14"
}

locals {
  remote_account_id = "${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "selected" {
  default = true
}

resource "aws_ssm_parameter" "user" {
  name  = "/myapp/dev/db.user"
  type  = "String"
  value = "jdoe"
}

resource "aws_ssm_parameter" "password" {
  name  = "/myapp/dev/db.password"
  type  = "SecureString"
  value = "CorrectHorseBatteryStaple"
}

module "ecs-base" {
  source = "../with_nlb"     # Reuse the infrastructure defined in the "with_nlb" example :)
  region = "${local.region}"
}

module "secret_service" {
  source = "../../"

  name                                        = "${terraform.workspace}-secrets"
  ecs_cluster_id                              = "${module.ecs-base.cluster_id}"
  region                                      = "${local.region}"
  bootstrap_container_image                   = "nginx:stable"
  container_cpu                               = 256
  container_memory                            = 128
  container_port                              = 80
  load_balancing_type                         = "network"
  load_balancing_properties_route53_zone_id   = "${module.ecs-base.zone_id}"
  load_balancing_properties_lb_vpc_id         = "${data.aws_vpc.selected.id}"
  load_balancing_properties_nlb_listener_port = 80
  load_balancing_properties_lb_arn            = "${module.ecs-base.lb_arn}"

  # Enable container secrets and add two parameters. The first is stored in a "remote" account, the other is stored locally. 
  container_secrets_enabled = true

  container_secrets = {
    DB_USER     = "arn:aws:ssm:${local.region}:${local.remote_account_id}:parameter/myapp/dev/db.user"
    DB_PASSWORD = "/myapp/dev/db.password"
  }

  # Give the service access to SSM. Note that for remote accounts, you can't control access with ssm_paths
  ssm_enabled = true
  ssm_paths   = ["myapp/dev"]

  tags = {
    Environment = "${terraform.workspace}"
  }
}
