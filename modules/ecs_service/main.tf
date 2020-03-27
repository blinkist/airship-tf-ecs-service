locals {
  lb_attached = lower(var.load_balancing_type) != "none"
}

# Make an LB connected service dependent of this rule
# This to make sure the Target Group is linked to a Load Balancer before the aws_ecs_service is created
resource "null_resource" "aws_lb_listener_rules" {
  count = var.create ? 1 : 0

  triggers = {
    listeners = join(",", var.aws_lb_listener_rules)
  }
}

resource "aws_ecs_service" "this" {
  count = var.create ? 1 : 0

  name    = var.name
  cluster = var.cluster_id

  task_definition                    = var.selected_task_definition
  desired_count                      = var.desired_capacity
  launch_type                        = var.launch_type
  scheduling_strategy                = var.scheduling_strategy
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  deployment_controller {
    type = var.deployment_controller_type
  }

  dynamic ordered_placement_strategy {
    for_each = var.with_placement_strategy ? [1] : []
    content {
      field = "attribute:ecs.availability-zone"
      type  = "spread"
    }
  }

  dynamic ordered_placement_strategy {
    for_each = var.with_placement_strategy ? [1] : []
    content {
      field = "instanceId"
      type  = "spread"
    }
  }

  dynamic ordered_placement_strategy {
    for_each = var.with_placement_strategy ? [1] : []
    content {
      field = "memory"
      type  = "binpack"
    }
  }

  dynamic load_balancer {
    for_each = local.lb_attached ? [1] : []
    content {
      target_group_arn = var.lb_target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  dynamic network_configuration {
    for_each = var.awsvpc_enabled ? [1] : []
    content {
      subnets          = var.awsvpc_subnets
      security_groups  = var.awsvpc_security_group_ids
      assign_public_ip = var.assign_public_ip
    }
  }

  dynamic service_registries {
    for_each = var.service_discovery_enabled ? [1] : []
    content {
      registry_arn   = aws_service_discovery_service.this[0].arn
      container_name = var.container_name
      container_port = local.service_registries_container_port[var.service_discovery_dns_type]
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [null_resource.aws_lb_listener_rules]
}

### Service Registry resources

locals {
  # service_registries block does not accept a port with "A"-record-type
  # Setting the port to false works through a local
  service_registries_container_port = {
    "SRV" = var.container_port
    "A"   = false
  }
}

resource "aws_service_discovery_service" "this" {
  count = var.create && var.service_discovery_enabled ? 1 : 0

  name = var.name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = var.service_discovery_dns_ttl
      type = var.service_discovery_dns_type
    }

    routing_policy = var.service_discovery_routing_policy
  }

  health_check_custom_config {
    failure_threshold = var.service_discovery_healthcheck_custom_failure_threshold
  }
}
