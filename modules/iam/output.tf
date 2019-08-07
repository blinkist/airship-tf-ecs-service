output "ecs_task_execution_role_arn" {
  description = "ecs_task_execution_role_arn outputs the Role-Arn for the ECS Task Execution role."
  value       = "${element(concat(aws_iam_role.ecs_task_execution_role.*.arn, list("")), 0)}"
}

output "ecs_task_execution_role_name" {
  description = "ecs_task_execution_role_arn outputs the Role-name for the ECS Task Execution role."
  value       = "${element(concat(aws_iam_role.ecs_task_execution_role.*.name, list("")), 0)}"
}

output "ecs_taskrole_arn" {
  description = "ecs_taskrole_arn outputs the Role-Arn of the ECS Task"
  value       = "${element(concat(aws_iam_role.ecs_tasks_role.*.arn, list("")), 0)}"
}

output "ecs_taskrole_name" {
  description = "ecs_taskrole_name outputs the Role-name of the ECS Task"
  value       = "${element(concat(aws_iam_role.ecs_tasks_role.*.name, list("")), 0)}"
}

output "lambda_lookup_role_arn" {
  description = "IAM Role arn of the lambda lookup helper"
  value       = "${element(concat(aws_iam_role.lambda_lookup.*.arn, list("")), 0)}"
}

output "lambda_lookup_role_name" {
  description = "IAM Role name of the lambda lookup helper"
  value       = "${element(concat(aws_iam_role.lambda_lookup.*.name, list("")), 0)}"
}

output "lambda_lookup_role_policy_id" {
  description = "policy ID of the lambda role, this to force dependency"
  value       = "${element(concat(aws_iam_role_policy.lambda_lookup_policy.*.id, list("")), 0)}"
}

output "lambda_ecs_task_scheduler_role_arn" {
  description = "IAM Role arn of the lambda lookup helper"
  value       = "${element(concat(aws_iam_role.lambda_ecs_task_scheduler.*.arn, list("")), 0)}"
}

output "scheduled_task_cloudwatch_role_arn" {
  description = "Arn for the role assumed by CloudWatch to execute scheduling events."
  value       = "${element(concat(aws_iam_role.scheduled_task_cloudwatch.*.arn, list("")), 0)}"
}
