# We need to output the service name of the resource created
# Autoscaling uses the service name, by using the service name of the resource output, we make sure that the
# Order of creation is maintained
output "ecs_service_name" {
  value = join("", aws_ecs_service.this.*.name)
}

