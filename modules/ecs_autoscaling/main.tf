locals {
  cluster_plus_service_name = "${var.cluster_name}-${var.ecs_service_name}"
}

resource "aws_appautoscaling_target" "target" {
  count              = "${var.create ? 1 : 0 }"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = "${var.desired_min_capacity}"
  max_capacity       = "${var.desired_max_capacity}"
}

resource "aws_appautoscaling_policy" "policy" {
  count = "${(var.create ? 1 : 0 ) * length(var.scaling_properties) }"

  name               = "${local.cluster_plus_service_name}-${lookup(var.scaling_properties[count.index], "type")}-${element(var.direction[lookup(var.scaling_properties[count.index], "direction")],1)}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.ecs_service_name}"

  step_scaling_policy_configuration {
    adjustment_type         = "${lookup(var.scaling_properties[count.index], "adjustment_type", "1")}"
    cooldown                = "${lookup(var.scaling_properties[count.index], "cooldown", "300")}"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = "${lookup(var.scaling_properties[count.index], "scaling_adjustment")}"
    }
  }

  depends_on = ["aws_appautoscaling_target.target"]
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  count = "${(var.create ? 1 : 0 ) * length(var.scaling_properties) }"

  alarm_name = "${local.cluster_plus_service_name}-${lookup(var.scaling_properties[count.index], "type")}-${element(var.direction[lookup(var.scaling_properties[count.index], "direction")],1)}"

  comparison_operator = "${element(var.direction[lookup(var.scaling_properties[count.index], "direction")],0)}"

  evaluation_periods = "${lookup(var.scaling_properties[count.index], "evaluation_periods")}"
  metric_name        = "${lookup(var.scaling_properties[count.index], "type")}"
  namespace          = "AWS/ECS"
  period             = "${lookup(var.scaling_properties[count.index], "observation_period")}"
  statistic          = "${lookup(var.scaling_properties[count.index], "statistic")}"
  threshold          = "${lookup(var.scaling_properties[count.index], "threshold")}"

  dimensions {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${var.ecs_service_name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.policy.*.arn[count.index]}"]

  depends_on = ["aws_appautoscaling_target.target"]
}
