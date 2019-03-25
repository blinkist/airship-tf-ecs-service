data "aws_vpc" "selected" {
  default = true
}

data "aws_availability_zones" "available" {}

data "aws_subnet" "selected" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  default_for_az    = true
  vpc_id            = "${data.aws_vpc.selected.id}"
}

data "aws_security_group" "selected" {
  name   = "default"
  vpc_id = "${data.aws_vpc.selected.id}"
}

module "ecs_cluster" {
  source = "git::git@github.com:blinkist/terraform-aws-airship-ecs-cluster.git?ref=master"

  name = "${terraform.workspace}-cluster"

  vpc_id     = "${data.aws_vpc.selected.id}"
  subnet_ids = ["${data.aws_subnet.selected.id}"]

  vpc_security_group_ids = ["${data.aws_security_group.selected.id}"]

  cluster_properties {
    # ec2_instance_type defines the instance type
    ec2_instance_type = "t3.small"
    ec2_key_name      = ""

    # ec2_asg_min defines the minimum size of the autoscaling group
    ec2_asg_min = "1"

    # ec2_asg_max defines the maximum size of the autoscaling group
    ec2_asg_max = "1"

    # ec2_disk_size defines the size in GB of the non-root volume of the EC2 Instance
    ec2_disk_size = "30"

    # ec2_disk_type defines the disktype of that EBS Volume
    ec2_disk_type = "gp2"

    # ec2_disk_encryption = "true"

    # block_metadata_service blocks the aws metadata service from the ECS Tasks true / false, this is preferred security wise
    block_metadata_service = false
  }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route53_zone" "this" {
  name = "some.zonename.com"
}

resource "aws_security_group_rule" "allow_all" {
  type              = "ingress"
  from_port         = "${var.echo_port}"
  to_port           = "${var.echo_port}"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${data.aws_security_group.selected.id}"
}

data "aws_network_interface" "nlb" {
  depends_on = ["aws_lb.this"]

  filter = {
    name   = "subnet-id"
    values = ["${data.aws_subnet.selected.id}"]
  }
}

resource "aws_security_group_rule" "allow_ecs" {
  type              = "ingress"
  from_port         = "32768"
  to_port           = "65535"
  protocol          = "tcp"
  cidr_blocks       = ["${formatlist("%s/32",sort(distinct(compact(concat(list(""),data.aws_network_interface.nlb.private_ips)))))}"]
  security_group_id = "${data.aws_security_group.selected.id}"
}

data "http" "icanhazip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group_rule" "allow_user" {
  type              = "ingress"
  from_port         = "32768"
  to_port           = "65535"
  protocol          = "tcp"
  cidr_blocks       = ["${format("%s/%s",trimspace(data.http.icanhazip.body), "32")}"]
  security_group_id = "${data.aws_security_group.selected.id}"
}

resource "aws_lb" "this" {
  name               = "${terraform.workspace}-service-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${data.aws_subnet.selected.id}"]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Environment = "${terraform.workspace}"
  }
}

variable "echo_port" {
  default = "1025"
}

# Test that create true works
module "nlb_service" {
  source = "../../"

  create = true

  # The name of the project, must be unique
  name = "${terraform.workspace}-echo-service"

  # ecs_cluster_id is the cluster to which the ECS Service will be added.
  ecs_cluster_id = "${module.ecs_cluster.cluster_id}"

  # Region of the ECS Cluster
  region = "${var.region}"

  # image_url defines the docker image location
  bootstrap_container_image = "cjimti/go-echo"

  # Container name 
  container_name = "go-echo"

  # cpu defines the needed cpu for the container
  container_cpu = "256"

  # container_memory  defines the hard memory limit of the container
  container_memory = "128"

  # port defines the needed port of the container
  container_port = "${var.echo_port}"

  # scheduling_strategy defaults to REPLICA
  scheduling_strategy = "REPLICA"

  # Spread tasks over ECS Cluster based on AZ, Instance-id, memory
  with_placement_strategy = false

  # load_balancing_type is either "none", "network","application"
  load_balancing_type = "network"

  lb_arn = "${aws_lb.this.arn}"

  cognito_auth_enabled = false
  route53_record_type  = "ALIAS"

  ## load_balancing_properties map defines the map for services hooked to a load balancer
  load_balancing_properties_route53_zone_id      = "${aws_route53_zone.this.zone_id}"
  load_balancing_properties_route53_name         = "service-web"
  load_balancing_properties_lb_vpc_id            = "${data.aws_vpc.selected.id}"
  load_balancing_properties_target_group_port    = "${var.echo_port}"
  load_balancing_properties_nlb_listener_port    = "${var.echo_port}"
  load_balancing_properties_deregistration_delay = 0

  # deployment_controller_type sets the deployment type
  # ECS for Rolling update, and CODE_DEPLOY for Blue/Green deployment via CodeDeploy
  deployment_controller_type = "ECS"

  ## capacity_properties map defines the capacity properties of the service
  force_bootstrap_container_image = "false"

  # Whether to provide access to the supplied kms_keys. If no kms keys are
  # passed, set this to false.

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Test that create false works
module "nlb_service" {
  source = "../../"

  create = false

  # The name of the project, must be unique
  name = "${terraform.workspace}-not-created-service"

  # ecs_cluster_id is the cluster to which the ECS Service will be added.
  ecs_cluster_id = "${module.ecs_cluster.cluster_id}"

  # Region of the ECS Cluster
  region = "${var.region}"

  # image_url defines the docker image location
  bootstrap_container_image = "cjimti/go-echo"

  # Container name 
  container_name = "go-echo"

  # cpu defines the needed cpu for the container
  container_cpu = "256"

  # container_memory  defines the hard memory limit of the container
  container_memory = "128"

  # port defines the needed port of the container
  container_port = "${var.echo_port}"

  # scheduling_strategy defaults to REPLICA
  scheduling_strategy = "REPLICA"

  # Spread tasks over ECS Cluster based on AZ, Instance-id, memory
  with_placement_strategy = false

  # load_balancing_type is either "none", "network","application"
  load_balancing_type = "network"

  lb_arn = "${aws_lb.this.arn}"

  cognito_auth_enabled = false
  route53_record_type  = "ALIAS"

  ## load_balancing_properties map defines the map for services hooked to a load balancer
  load_balancing_properties_route53_zone_id      = "${aws_route53_zone.this.zone_id}"
  load_balancing_properties_route53_name         = "service-web"
  load_balancing_properties_lb_vpc_id            = "${data.aws_vpc.selected.id}"
  load_balancing_properties_target_group_port    = "${var.echo_port}"
  load_balancing_properties_nlb_listener_port    = "${var.echo_port}"
  load_balancing_properties_deregistration_delay = 0

  # deployment_controller_type sets the deployment type
  # ECS for Rolling update, and CODE_DEPLOY for Blue/Green deployment via CodeDeploy
  deployment_controller_type = "ECS"

  ## capacity_properties map defines the capacity properties of the service
  capacity_properties             = {}
  force_bootstrap_container_image = "false"

  # Whether to provide access to the supplied kms_keys. If no kms keys are
  # passed, set this to false.

  tags = {
    Environment = "${terraform.workspace}"
  }
}
