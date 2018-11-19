output "lb_target_group_arn" {
  value = "${join("",concat(list(var.lb_target_group_arn),aws_lb_target_group.service.*.arn))}"
}
