variable "create" {}
variable "ecs_cluster_id" {}
variable "ecs_service_name" {}
variable "container_name" {}

variable "ecs_scheduled_tasks" {
  type    = "list"
  default = []
}

variable "tags" {
  type    = "map"
  default = {}
}

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

    resources = ["${format("arn:aws:logs:*:*:log-group:/aws/lambda/%s:*", local.identifier)}"]
    effect    = "Allow"
  }

  statement {
    actions = ["logs:PutLogEvents"]

    resources = ["${format("arn:aws:logs:*:*:log-group:/aws/lambda/%s:*.*", local.identifier)}"]
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

  assume_role_policy = "${data.aws_iam_policy_document.lambda_trust_policy.json}"
}

# Policy attachment for the lambda
resource "aws_iam_role_policy" "lambda_taskrunner_policy" {
  count  = "${var.create ? 1 : 0}"
  role   = "${aws_iam_role.lambda_task_runner_role.name}"
  policy = "${data.aws_iam_policy_document.lambda_taskrunner_policy.json}"
}

#
# aws_cloudwatch_event_rule with a schedule_expressions
#
resource "aws_cloudwatch_event_rule" "schedule_expressions" {
  count               = "${length(var.ecs_scheduled_tasks)}"
  name                = "${local.identifier}-${lookup(var.ecs_scheduled_tasks[count.index],"job_name")}"
  description         = "${local.identifier}-${lookup(var.ecs_scheduled_tasks[count.index],"job_name")}"
  schedule_expression = "${lookup(var.ecs_scheduled_tasks[count.index],"schedule_expression")}"
}

locals {
  lambda_params = {
    job_identifier = "$${job_name}"

    overrides = {
      containerOverrides = [
        {
          name              = "$${container_name}"
          command           = "$${container_cmd}"
          cpu               = "$${container_cpu}"
          memory            = "$${container_memory}"
          memoryReservation = "$${container_memory_reservation}"
          environment       = "$${container_environment}"
        },
      ]
    }
  }
}

data "template_file" "task_defs" {
  count = "${var.create ? length(var.ecs_scheduled_tasks): 0}"

  template = "${jsonencode(local.lambda_params)}"

  vars {
    job_name                     = "${lookup(var.ecs_scheduled_tasks[count.index],"job_name")}"
    container_cpu                = "${lookup(var.ecs_scheduled_tasks[count.index],"cpu","")}"
    container_name               = "${var.container_name}"
    container_memory             = "${lookup(var.ecs_scheduled_tasks[count.index],"memory","")}"
    container_memory_reservation = "${lookup(var.ecs_scheduled_tasks[count.index],"memory_reservation","")}"
    container_cmd                = "${lookup(var.ecs_scheduled_tasks[count.index],"command","")}"
    container_environment        = "${lookup(var.ecs_scheduled_tasks[count.index],"container_envvars_override","")}"
  }
}

resource "aws_cloudwatch_event_target" "call_task_runner_scheduler" {
  count     = "${var.create ? length(var.ecs_scheduled_tasks): 0}"
  rule      = "${aws_cloudwatch_event_rule.schedule_expressions.*.name[count.index]}"
  target_id = "${aws_lambda_function.lambda_task_runner.function_name}"
  arn       = "${aws_lambda_function.lambda_task_runner.arn}"
  input     = "${data.template_file.task_defs.*.rendered[count.index]}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_task_runner" {
  count         = "${var.create ? length(var.ecs_scheduled_tasks): 0}"
  statement_id  = "${lookup(var.ecs_scheduled_tasks[count.index],"job_name")}-cloudwatch-exec"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_task_runner.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.schedule_expressions.*.arn[count.index]}"
}
