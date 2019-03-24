---
sidebarDepth: 2
---

# Scaling and Capacity

## Capacity

The default capacity for services is defined by their min and max capacity. The min capacity defines the minimum amount of tasks the Scheduler need to keep running. The maximum capacity defines the upper limit. By default the min and max capacity is two.

```json
   # capacity_properties defines the size in task for the ECS Service.
   # Without scaling enabled, desired_capacity is the only necessary property
   # With scaling enabled, desired_min_capacity and desired_max_capacity define the lower and upper boundary in task size
   capacity_properties_desired_capacity     = "2"
   capacity_properties_desired_min_capacity = "2"
   capacity_properties_desired_max_capacity = "2"
```

## Scaling

Autoscaling properties can be set to adjust the amount of ECS Tasks per service based on certain cloudwatch metrics. The lower and upper capacity limit defined in `capacity_properties` stay valid.

```json
  # https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html
  scaling_properties = [
    {
      type               = "CPUUtilization"
      direction          = "up"
      evaluation_periods = "2"
      observation_period = "300"
      statistic          = "Average"
      threshold          = "89"
      cooldown           = "900"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = "1"
    },
    {
      type               = "CPUUtilization"
      direction          = "down"
      evaluation_periods = "4"
      observation_period = "300"
      statistic          = "Average"
      threshold          = "10"
      cooldown           = "300"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = "-1"
    },
  ]
```

