locals {
  identifier = "${basename(var.ecs_cluster_id)}-${var.ecs_service_name}-task-runner"
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
  filename         = "${path.module}/ecs_task_runner.zip"
  source_code_hash = "${base64sha256(file("${path.module}/ecs_task_runner.zip"))}"
  role             = "${aws_iam_role.lambda_task_runner_role.arn}"
  publish          = true
  tags             = "${var.tags}"

  lifecycle {
    ignore_changes = ["filename"]
  }
}

# Trust policy for the Lambda function
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

# Policy for the Lambda Logging & ECS 
data "aws_iam_policy_document" "lambda_taskrunner_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${format("arn:aws:logs:*:*:log-group:/aws/lambda/%s-lambda-task-runner:*", var.name)}"]
    effect    = "Allow"
  }

  statement {
    actions = ["logs:PutLogEvents"]

    resources = ["${format("arn:aws:logs:*:*:log-group:/aws/lambda/%s-lambda-task-runner:*.*", var.name)}"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "ecs:RunTask",
    ]

    resources = ["*"] // We could restrict to a specific task family if we wanted.

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = ["${var.ecs_cluster_id}"]
    }
  }
}

# Role for the lambda
resource "aws_iam_role" "lambda_task_runner_role" {
  count = "${var.create ? 1 : 0}"
  name  = "${local.identifier}"

  assume_role_policy = "${aws_iam_policy_document.lambda_trust_policy.json}"
}

# Policy attachment for the lambda
resource "aws_iam_role_policy" "lambda_taskrunner_policy" {
  count      = "${var.create ? 1 : 0}"
  role       = "${aws_iam_role.lambda_task_runner_role.name}"
  policy_arn = "${aws_iam_policy.lambda_taskrunner_policy.arn}"
}

#
#
#
resource "aws_cloudwatch_event_rule" "scheduled_expressions" {
  count               = "${length(var.ecs_scheduled_tasks)}"
  name                = "${local.identifier}"
  description         = "${local.identifier}"
  schedule_expression = "${var.schedule_expression}"
}

#/**
# * Target the lambda function with the schedule.
# */
#resource "aws_cloudwatch_event_target" "call_task_runner_scheduler" {
#  rule      = "${aws_cloudwatch_event_rule.task_runner_scheduler.name}"
#  target_id = "${var.lambda_function_name}"
#  arn       = "${var.lambda_function_arn}"
#  input     = "${data.template_file.task_json.rendered}"
#}
#
#data "template_file" "task_json" {
#  template = "${file("${path.module}/task.tpl")}"
#
#  vars {
#    job_identifier = "${var.job_identifier}"
#    region         = "${var.region}"
#    cluster        = "${var.ecs_cluster_id}"
#    ecs_task_def   = "${var.ecs_task_def}"
#    container_name = "${var.container_name}"
#    container_cmd  = "${jsonencode(var.container_cmd)}"
#  }
#}
#
#/**
# * Permission to allow Cloudwatch events to trigger the task runner
# * Lambda function.
# */
#resource "aws_lambda_permission" "allow_cloudwatch_to_call_task_runner" {
#  statement_id  = "${var.job_identifier}-AllowExecutionFromCloudWatch"
#  action        = "lambda:InvokeFunction"
#  function_name = "${var.lambda_function_name}"
#  principal     = "events.amazonaws.com"
#  source_arn    = "${aws_cloudwatch_event_rule.task_runner_scheduler.arn}"
#}

