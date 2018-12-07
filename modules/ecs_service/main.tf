#
# With HCL1 it's not possible to add dynamic blocks for the aws_ecs_service resource. For this
# reason many aws_ecs_service's are repeated for their different goals.
#

locals {
  lb_attached = "${var.load_balancing_type != "none"}"
}

# Make an LB connected service dependent of this rule
# This to make sure the Target Group is linked to a Load Balancer before the aws_ecs_service is created
resource "null_resource" "aws_lb_listener_rules" {
  count = "${var.create ? 1 : 0}"

  triggers {
    listeners = "${join(",", var.aws_lb_listener_rules)}"
  }
}

resource "aws_ecs_service" "app_with_lb_awsvpc" {
  count = "${var.create && var.awsvpc_enabled && local.lb_attached && !var.enable_service_discovery ? 1 : 0}"

  name    = "${var.name}"
  cluster = "${var.cluster_id}"

  task_definition                    = "${var.selected_task_definition}"
  desired_count                      = "${var.desired_capacity}"
  launch_type                        = "${var.launch_type}"
  scheduling_strategy                = "${var.scheduling_strategy}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  load_balancer {
    target_group_arn = "${var.lb_target_group_arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  network_configuration {
    subnets         = ["${var.awsvpc_subnets}"]
    security_groups = ["${var.awsvpc_security_group_ids}"]
  }

  depends_on = ["null_resource.aws_lb_listener_rules"]
}

resource "aws_ecs_service" "app_with_lb_spread" {
  count       = "${var.create && !var.awsvpc_enabled && local.lb_attached && var.with_placement_strategy && !var.enable_service_discovery ? 1 : 0}"
  name        = "${var.name}"
  launch_type = "${var.launch_type}"
  cluster     = "${var.cluster_id}"

  task_definition = "${var.selected_task_definition}"

  desired_count       = "${var.desired_capacity}"
  scheduling_strategy = "${var.scheduling_strategy}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "instanceId"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "memory"
    type  = "binpack"
  }

  load_balancer {
    target_group_arn = "${var.lb_target_group_arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  depends_on = ["null_resource.aws_lb_listener_rules"]
}

resource "aws_ecs_service" "app_with_lb" {
  count           = "${var.create && !var.awsvpc_enabled && local.lb_attached && !var.with_placement_strategy && !var.enable_service_discovery ? 1 : 0}"
  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${var.cluster_id}"
  task_definition = "${var.selected_task_definition}"

  desired_count       = "${var.desired_capacity}"
  scheduling_strategy = "${var.scheduling_strategy}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  load_balancer {
    target_group_arn = "${var.lb_target_group_arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  depends_on = ["null_resource.aws_lb_listener_rules"]
}

resource "aws_ecs_service" "app" {
  count = "${var.create && ! local.lb_attached && ! var.awsvpc_enabled && !var.enable_service_discovery ? 1 : 0 }"

  name                = "${var.name}"
  launch_type         = "${var.launch_type}"
  scheduling_strategy = "${var.scheduling_strategy}"
  cluster             = "${var.cluster_id}"
  task_definition     = "${var.selected_task_definition}"

  desired_count = "${var.desired_capacity}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

resource "aws_ecs_service" "app_awsvpc" {
  count = "${var.create && ! local.lb_attached && var.awsvpc_enabled && !var.enable_service_discovery ? 1 : 0 }"

  name                = "${var.name}"
  launch_type         = "${var.launch_type}"
  scheduling_strategy = "${var.scheduling_strategy}"
  cluster             = "${var.cluster_id}"
  task_definition     = "${var.selected_task_definition}"
  desired_count       = "${var.desired_capacity}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  network_configuration {
    subnets         = ["${var.awsvpc_subnets}"]
    security_groups = ["${var.awsvpc_security_group_ids}"]
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

### Service Registry resources

resource "aws_ecs_service" "app_with_lb_awsvpc_with_service_registry" {
  count = "${var.create && var.awsvpc_enabled && local.lb_attached && var.enable_service_discovery ? 1 : 0}"

  name    = "${var.name}"
  cluster = "${var.cluster_id}"

  task_definition                    = "${var.selected_task_definition}"
  desired_count                      = "${var.desired_capacity}"
  launch_type                        = "${var.launch_type}"
  scheduling_strategy                = "${var.scheduling_strategy}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  load_balancer {
    target_group_arn = "${var.lb_target_group_arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  network_configuration {
    subnets         = ["${var.awsvpc_subnets}"]
    security_groups = ["${var.awsvpc_security_group_ids}"]
  }

  service_registries {
    registry_arn   = "${var.service_discovery_namespace_arn}"
    container_name = "${var.service_discovery_container_name == "" ? var.name : var.service_discovery_container_name }"
  }

  depends_on = ["null_resource.aws_lb_listener_rules"]
}

resource "aws_ecs_service" "app_with_lb_spread_with_service_registry" {
  count       = "${var.create && !var.awsvpc_enabled && local.lb_attached && var.with_placement_strategy && var.enable_service_discovery ? 1 : 0}"
  name        = "${var.name}"
  launch_type = "${var.launch_type}"
  cluster     = "${var.cluster_id}"

  task_definition = "${var.selected_task_definition}"

  desired_count       = "${var.desired_capacity}"
  scheduling_strategy = "${var.scheduling_strategy}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "instanceId"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "memory"
    type  = "binpack"
  }

  load_balancer {
    target_group_arn = "${var.lb_target_group_arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  service_registries {
    registry_arn   = "${var.service_discovery_namespace_arn}"
    container_name = "${var.service_discovery_container_name == "" ? var.name : var.service_discovery_container_name }"
  }

  depends_on = ["null_resource.aws_lb_listener_rules"]
}

resource "aws_ecs_service" "app_with_lb_with_service_registry" {
  count           = "${var.create && !var.awsvpc_enabled && local.lb_attached && !var.with_placement_strategy && var.enable_service_discovery ? 1 : 0}"
  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${var.cluster_id}"
  task_definition = "${var.selected_task_definition}"

  desired_count       = "${var.desired_capacity}"
  scheduling_strategy = "${var.scheduling_strategy}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  load_balancer {
    target_group_arn = "${var.lb_target_group_arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  service_registries {
    registry_arn   = "${var.service_discovery_namespace_arn}"
    container_name = "${var.service_discovery_container_name == "" ? var.name : var.service_discovery_container_name }"
  }

  depends_on = ["null_resource.aws_lb_listener_rules"]
}

resource "aws_ecs_service" "app_with_service_registry" {
  count = "${var.create && ! local.lb_attached && ! var.awsvpc_enabled && var.enable_service_discovery ? 1 : 0 }"

  name                = "${var.name}"
  launch_type         = "${var.launch_type}"
  scheduling_strategy = "${var.scheduling_strategy}"
  cluster             = "${var.cluster_id}"
  task_definition     = "${var.selected_task_definition}"

  desired_count = "${var.desired_capacity}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  service_registries {
    registry_arn   = "${var.service_discovery_namespace_arn}"
    container_name = "${var.service_discovery_container_name == "" ? var.name : var.service_discovery_container_name }"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

resource "aws_ecs_service" "app_awsvpc_with_service_registry" {
  count = "${var.create && ! local.lb_attached && var.awsvpc_enabled && var.enable_service_discovery ? 1 : 0 }"

  name                = "${var.name}"
  launch_type         = "${var.launch_type}"
  scheduling_strategy = "${var.scheduling_strategy}"
  cluster             = "${var.cluster_id}"
  task_definition     = "${var.selected_task_definition}"
  desired_count       = "${var.desired_capacity}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  network_configuration {
    subnets         = ["${var.awsvpc_subnets}"]
    security_groups = ["${var.awsvpc_security_group_ids}"]
  }

  service_registries {
    registry_arn   = "${var.service_discovery_namespace_arn}"
    container_name = "${var.service_discovery_container_name == "" ? var.name : var.service_discovery_container_name }"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}
