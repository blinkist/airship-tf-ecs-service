# These outputs are needed in order to avoid creating two app_autoscaling_target resources
# and when using one we would need it's attributes.
output "aws_appautoscaling_target_service_namespace" {
  value = "${join("", aws_appautoscaling_target.target.*.service_namespace)}"
}

output "aws_appautoscaling_target_resource_id" {
  value = "${join("", aws_appautoscaling_target.target.*.resource_id)}"
}

output "aws_appautoscaling_target_scalable_dimension" {
  value = "${join("", aws_appautoscaling_target.target.*.scalable_dimension)}"
}
