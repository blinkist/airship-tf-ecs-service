locals {
  identifier = "${basename(var.ecs_cluster_id)}-${var.ecs_service_name}-task-scheduler"
}

# Zip the lambda dir
data "archive_file" "ecs_task_scheduler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/ecs_task_scheduler.zip"
}

#
# The lambda taking care of running the tasks in scheduled fasion
#
resource "aws_lambda_function" "lambda_task_runner" {
  count            = var.create ? 1 : 0
  function_name    = local.identifier
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  timeout          = 30
  filename         = "${path.module}/ecs_task_scheduler.zip"
  source_code_hash = data.archive_file.ecs_task_scheduler_zip.output_base64sha256
  role             = var.lambda_ecs_task_scheduler_role_arn

  publish = true
  tags    = var.tags

  lifecycle {
    ignore_changes = [filename]
  }
}

#
# aws_cloudwatch_event_rule with a schedule_expressions
#
resource "aws_cloudwatch_event_rule" "schedule_expressions" {
  count               = length(var.ecs_cron_tasks)
  name                = format("job-%.32s", var.ecs_cron_tasks[count.index]["job_name"])
  description         = "${local.identifier}-${var.ecs_cron_tasks[count.index]["job_name"]}"
  schedule_expression = var.ecs_cron_tasks[count.index]["schedule_expression"]
}

locals {
  lambda_params = {
    job_identifier = "$${job_name}"
    ecs_cluster    = "$${ecs_cluster}"
    ecs_service    = "$${ecs_service}"
    started_by     = "$${started_by}"
    overrides = {
      containerOverrides = [
        {
          name    = "$${container_name}"
          command = ["/bin/sh", "-c", "$${container_cmd}"]
        },
      ]
    }
  }
}

data "template_file" "task_defs" {
  count = var.create ? length(var.ecs_cron_tasks) : 0

  template = jsonencode(local.lambda_params)

  vars = {
    ecs_cluster    = var.ecs_cluster_id
    ecs_service    = var.ecs_service_name
    started_by     = format("job-%.32s", var.ecs_cron_tasks[count.index]["job_name"])
    job_name       = var.ecs_cron_tasks[count.index]["job_name"]
    container_name = var.container_name
    container_cmd  = lookup(var.ecs_cron_tasks[count.index], "command", "")
  }
}

resource "aws_cloudwatch_event_target" "call_task_runner_scheduler" {
  count     = var.create ? length(var.ecs_cron_tasks) : 0
  rule      = aws_cloudwatch_event_rule.schedule_expressions[count.index].name
  target_id = aws_lambda_function.lambda_task_runner[0].function_name
  arn       = aws_lambda_function.lambda_task_runner[0].arn

  input = data.template_file.task_defs[count.index].rendered
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_task_runner" {
  count         = var.create ? length(var.ecs_cron_tasks) : 0
  statement_id  = "${var.ecs_cron_tasks[count.index]["job_name"]}-cloudwatch-exec"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_task_runner[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_expressions[count.index].arn
}

