# We need to output the service name of the resource created
# Autoscaling uses the service name, by using the service name of the resource output, we make sure that the
# Order of creation is maintained

output "ecs_service_name" {
  value = "${
    join("",compact(concat(list(""),
    aws_ecs_service.app_with_lb_awsvpc.*.name,
    aws_ecs_service.app_awsvpc.*.name,
    aws_ecs_service.app_with_lb_spread.*.name,
    aws_ecs_service.app_with_lb.*.name,
    aws_ecs_service.app_with_network_lb.*.name,
    aws_ecs_service.app.*.name,
    aws_ecs_service.app_awsvpc_with_service_registry.*.name,
    aws_ecs_service.app_with_service_registry.*.name,
    aws_ecs_service.app_with_network_lb.*.name
    ) ) )
  }"
}

output "service_discovery_container_name" {
  value = "${var.service_discovery_container_name == "" ? var.name : var.service_discovery_container_name }"
}
