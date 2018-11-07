output "lb_target_group_arn" {
  value = "${join("",concat(aws_lb_target_group.service.*.arn, list("")))}"
}
