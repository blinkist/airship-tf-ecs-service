#
# lookup_type lambda
#
resource "aws_lambda_function" "lambda_lookup" {
  count            = "${var.create && var.lookup_type == "lambda" ? 1 : 0}"
  function_name    = "${basename(var.ecs_cluster_id)}-${var.ecs_service_name}-lambda-lookup"
  handler          = "index.handler"
  runtime          = "nodejs8.10"
  filename         = "${path.module}/lookup.zip"
  source_code_hash = "${base64sha256(file("${path.module}/lookup.zip"))}"
  role             = "${var.lambda_lookup_role_arn}"
  publish          = true
  tags             = "${var.tags}"

  lifecycle {
    ignore_changes = ["filename"]
  }
}

data "aws_lambda_invocation" "lambda_lookup" {
  count         = "${var.create && var.lookup_type == "lambda" ? 1 :0 }"
  function_name = "${aws_lambda_function.lambda_lookup.function_name}"
  qualifier     = "${aws_lambda_function.lambda_lookup.version}"

  input = <<JSON
{
  "ecs_cluster": "${basename(var.ecs_cluster_id)}",
  "ecs_service": "${var.ecs_service_name}",
  "ecs_task_container_name": "${var.container_name}"
}
JSON
}

#
# lookup_type datasource
#
data "aws_ecs_service" "lookup" {
  count        = "${var.create && var.lookup_type == "datasource" ? 1 : 0 }"
  service_name = "${var.ecs_service_name}"
  cluster_arn  = "${var.ecs_cluster_id}"
}

data "aws_ecs_task_definition" "lookup" {
  count           = "${var.create && var.lookup_type == "datasource" ? 1 : 0 }"
  task_definition = "${data.aws_ecs_service.lookup.task_definition}"
}

data "aws_ecs_container_definition" "lookup" {
  count           = "${var.create && var.lookup_type == "datasource" ? 1 : 0 }"
  task_definition = "${data.aws_ecs_service.lookup.task_definition}"
  container_name  = "${var.container_name}"
}
