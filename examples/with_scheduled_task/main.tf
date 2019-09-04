terraform {
  required_version = "~> 0.11.0"
}

locals {
  region = "eu-west-1"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${terraform.workspace}-cluster"
  tags = "${local.tags}"

  lifecycle {
    create_before_destroy = true
  }
}

# Create a task defintion and associate a scheduling rule with it
module "scheduled_task" {
  source = "../../"

  name                      = "${terraform.workspace}-scheduled-task"
  ecs_cluster_id            = "${aws_ecs_cluster.this.id}"
  region                    = "${local.region}"
  bootstrap_container_image = "hello-world:latest"
  container_cpu             = 256
  container_memory          = 512
  fargate_enabled           = true
  awsvpc_enabled            = true
  awsvpc_subnets            = ["${data.aws_subnet.selected.id}"]
  awsvpc_security_group_ids = ["${data.aws_security_group.selected.id}"]
  tags                      = "${local.tags}"

  # Scheduled task configuration
  is_scheduled_task         = true             # Make this a scheduled task
  scheduled_task_expression = "rate(1 minute)" # Every minute
  scheduled_task_count      = 1                # The number of tasks to run
}
