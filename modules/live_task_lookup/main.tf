# In some cases the lambda is being invoked before the lamba policies have been added
# This null_resources forces a dependency
#
resource "null_resource" "force_policy_dependency" {
  triggers = {
    listeners = var.lambda_lookup_role_policy_id
  }
}

# Zip the lambda dir
data "archive_file" "lookup_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lookup_lambda"
  output_path = "${path.module}/lookup.zip"
}

#
# lookup_type lambda
#
resource "aws_lambda_function" "lambda_lookup" {
  count            = var.create ? 1 : 0
  function_name    = "${basename(var.ecs_cluster_id)}-${var.ecs_service_name}-lambda-lookup"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  filename         = "${path.module}/lookup.zip"
  source_code_hash = data.archive_file.lookup_zip.output_base64sha256
  role             = var.lambda_lookup_role_arn
  publish          = true
  tags             = var.tags

  lifecycle {
    ignore_changes = all
  }

  depends_on = [null_resource.force_policy_dependency]
}

data "aws_lambda_invocation" "lambda_lookup" {
  count         = var.create && var.lookup_type == "lambda" ? 1 : 0
  function_name = aws_lambda_function.lambda_lookup[0].function_name
  qualifier     = aws_lambda_function.lambda_lookup[0].version

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
  count        = var.create && var.lookup_type == "datasource" ? 1 : 0
  service_name = var.ecs_service_name
  cluster_arn  = var.ecs_cluster_id
}

data "aws_ecs_task_definition" "lookup" {
  count           = var.create && var.lookup_type == "datasource" ? 1 : 0
  task_definition = data.aws_ecs_service.lookup[0].task_definition
}

data "aws_ecs_container_definition" "lookup" {
  count           = var.create && var.lookup_type == "datasource" ? 1 : 0
  task_definition = data.aws_ecs_service.lookup[0].task_definition
  container_name  = var.container_name
}

