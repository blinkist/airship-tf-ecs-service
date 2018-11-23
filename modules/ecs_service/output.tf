# We need to output the service name of the resource created
# Autoscaling uses the service name, by using the service name of the resource output, we make sure that the
# Order of creation is maintained
output "ecs_service_name" {
  value = "${var.awsvpc_enabled ? 
                ( local.lb_attached ? join("",aws_ecs_service.app_with_lb_awsvpc.*.name) : join("",aws_ecs_service.app_awsvpc.*.name) ) 
                :
                ( local.lb_attached ? ( var.with_placement_strategy ? join("",aws_ecs_service.app_with_lb_spread.*.name) : join("",aws_ecs_service.app_with_lb.*.name)) : join("",aws_ecs_service.app.*.name) )
  }"
}
