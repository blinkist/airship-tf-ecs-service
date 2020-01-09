locals {
  cluster_plus_service_name = "${var.cluster_name}-${var.ecs_service_name}"
}

resource "aws_appautoscaling_target" "target" {
  count              = var.create ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.desired_min_capacity
  max_capacity       = var.desired_max_capacity
}

resource "aws_appautoscaling_policy" "policy" {
  count = var.create ? 1 : 0 * length(var.scaling_properties)

  name = "${local.cluster_plus_service_name}-${var.scaling_properties[count.index]["type"]}-${element(
    var.direction[var.scaling_properties[count.index]["direction"]],
    1,
  )}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.ecs_service_name}"

  step_scaling_policy_configuration {
    adjustment_type         = var.scaling_properties[count.index]["adjustment_type"]
    cooldown                = var.scaling_properties[count.index]["cooldown"]
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = var.scaling_properties[count.index]["scaling_adjustment"] == "-1" ? "" : "0"
      metric_interval_upper_bound = var.scaling_properties[count.index]["scaling_adjustment"] == "-1" ? "0" : ""
      scaling_adjustment          = var.scaling_properties[count.index]["scaling_adjustment"]
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  count = var.create ? 1 : 0 * length(var.scaling_properties)

  alarm_name = "${local.cluster_plus_service_name}-${var.scaling_properties[count.index]["type"]}-${element(
    var.direction[var.scaling_properties[count.index]["direction"]],
    1,
  )}"

  comparison_operator = element(
    var.direction[var.scaling_properties[count.index]["direction"]],
    0,
  )

  evaluation_periods = var.scaling_properties[count.index]["evaluation_periods"]
  metric_name        = var.scaling_properties[count.index]["type"]
  namespace          = "AWS/ECS"
  period             = var.scaling_properties[count.index]["observation_period"]
  statistic          = var.scaling_properties[count.index]["statistic"]
  threshold          = var.scaling_properties[count.index]["threshold"]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_appautoscaling_policy.policy[count.index].arn]

  depends_on = [aws_appautoscaling_target.target]
}

