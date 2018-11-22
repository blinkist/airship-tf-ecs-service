# ecs_task_execution_role_arn outputs the Role-Arn for the ECS Task Execution role.
output "ecs_task_execution_role_arn" {
  value = "${element(concat(aws_iam_role.ecs_task_execution_role.*.arn, list("")), 0)}"
}

# ecs_taskrole_arn outputs the Role-Arn of the ECS Task
output "ecs_taskrole_arn" {
  value = "${element(concat(aws_iam_role.ecs_tasks_role.*.arn, list("")), 0)}"
}

# ecs_taskrole_name outputs the Role-name of the ECS Task
output "ecs_taskrole_name" {
  value = "${element(concat(aws_iam_role.ecs_tasks_role.*.name, list("")), 0)}"
}

# IAM Role arn of the lambda lookup helper
output "lambda_lookup_role_arn" {
  value = "${element(concat(aws_iam_role.lambda_lookup.*.arn, list("")), 0)}"
}

# IAM Role name of the lambda lookup helper
output "lambda_lookup_role_name" {
  value = "${element(concat(aws_iam_role.lambda_lookup.*.name, list("")), 0)}"
}

# IAM Role arn of the lambda lookup helper
output "lambda_ecs_task_scheduler_role_arn" {
  value = "${element(concat(aws_iam_role.lambda_ecs_task_scheduler.*.arn, list("")), 0)}"
}
