locals {
  identifier = "${basename(var.ecs_cluster_id)}-${var.ecs_service_name}-task-scheduler"
}

#
# The lambda taking care of running the tasks in scheduled fasion
#
resource "aws_lambda_function" "lambda_task_runner" {
  count            = "${var.create ? 1 : 0}"
  function_name    = "${local.identifier}"
  handler          = "index.handler"
  runtime          = "nodejs8.10"
  timeout          = 30
  filename         = "${path.module}/ecs_task_scheduler.zip"
  source_code_hash = "${base64sha256(file("${path.module}/ecs_task_scheduler.zip"))}"
  role             = "${var.lambda_ecs_task_scheduler_role_arn}"

  #publish          = true
  tags = "${var.tags}"

  lifecycle {
    ignore_changes = ["filename"]
  }
}

#
# aws_cloudwatch_event_rule with a schedule_expressions
#
resource "aws_cloudwatch_event_rule" "schedule_expressions" {
  count               = "${length(var.ecs_cron_tasks)}"
  name                = "${format("job-%.32s",lookup(var.ecs_cron_tasks[count.index],"job_name"))}"
  description         = "${local.identifier}-${lookup(var.ecs_cron_tasks[count.index],"job_name")}"
  schedule_expression = "${lookup(var.ecs_cron_tasks[count.index],"schedule_expression")}"
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
  count = "${var.create ? length(var.ecs_cron_tasks): 0}"

  template = "${jsonencode(local.lambda_params)}"

  vars {
    ecs_cluster    = "${var.ecs_cluster_id}"
    ecs_service    = "${var.ecs_service_name}"
    started_by     = "${format("job-%.32s",lookup(var.ecs_cron_tasks[count.index],"job_name"))}"
    job_name       = "${lookup(var.ecs_cron_tasks[count.index],"job_name")}"
    container_name = "${var.container_name}"
    container_cmd  = "${lookup(var.ecs_cron_tasks[count.index],"command","")}"
  }
}

resource "aws_cloudwatch_event_target" "call_task_runner_scheduler" {
  count     = "${var.create ? length(var.ecs_cron_tasks): 0}"
  rule      = "${aws_cloudwatch_event_rule.schedule_expressions.*.name[count.index]}"
  target_id = "${aws_lambda_function.lambda_task_runner.function_name}"
  arn       = "${aws_lambda_function.lambda_task_runner.arn}"

  input = "${data.template_file.task_defs.*.rendered[count.index]}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_task_runner" {
  count         = "${var.create ? length(var.ecs_cron_tasks): 0}"
  statement_id  = "${lookup(var.ecs_cron_tasks[count.index],"job_name")}-cloudwatch-exec"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_task_runner.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.schedule_expressions.*.arn[count.index]}"

  #qualifier     = "${aws_lambda_function.lambda_task_runner.version}"
}
