locals {
  cluster_plus_service_name = "${var.cluster_name}-${var.ecs_service_name}"
}

resource "aws_appautoscaling_target" "ecs" {
  count              = "${(var.schedule_scale_up != "" || var.schedule_scale_down != "") && length(var.scaling_properties) == 0 ? 1 : 0}"
  max_capacity       = "${var.desired_max_capacity}"
  min_capacity       = "${var.desired_min_capacity}"
  resource_id        = "service/${var.cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_scheduled_action" "down" {
  count              = "${var.schedule_scale_down != "" ? 1 : 0}"
  name               = "${local.cluster_plus_service_name}_scheduled_scale_down"
  service_namespace  = "${length(var.scaling_properties) > 0 ? var.service_namespace : join(" ", aws_appautoscaling_target.ecs.*.service_namespace)}"
  resource_id        = "${length(var.scaling_properties) > 0 ? var.resource_id : join(" ", aws_appautoscaling_target.ecs.*.resource_id)}"
  scalable_dimension = "${length(var.scaling_properties) > 0 ? var.scalable_dimension : join(" ", aws_appautoscaling_target.ecs.*.scalable_dimension)}"
  schedule           = "${var.schedule_scale_down}"

  scalable_target_action {
    min_capacity = "${var.scalable_target_action_min_capacity_down}"
    max_capacity = "${var.scalable_target_action_max_capacity_down}"
  }
}

resource "aws_appautoscaling_scheduled_action" "up" {
  count              = "${var.schedule_scale_up != "" ? 1 : 0}"
  name               = "${local.cluster_plus_service_name}_scheduled_scale_up"
  service_namespace  = "${length(var.scaling_properties) > 0 ? var.service_namespace : join(" ", aws_appautoscaling_target.ecs.*.service_namespace)}"
  resource_id        = "${length(var.scaling_properties) > 0 ? var.resource_id : join(" ", aws_appautoscaling_target.ecs.*.resource_id)}"
  scalable_dimension = "${length(var.scaling_properties) > 0 ? var.scalable_dimension : join(" ", aws_appautoscaling_target.ecs.*.scalable_dimension)}"
  schedule           = "${var.schedule_scale_up}"

  scalable_target_action {
    max_capacity = "${var.scalable_target_action_max_capacity_up != "" ? var.scalable_target_action_max_capacity_up : var.desired_max_capacity}"
    min_capacity = "${var.scalable_target_action_min_capacity_up != "" ? var.scalable_target_action_max_capacity_up : var.desired_min_capacity}"
  }
}
