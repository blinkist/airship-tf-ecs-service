## IAM

# There are two different types of secrets: SSM Parameter Store
# parameters and Secrets Manager secrets. Their uses partially
# overlap: container secrets are injected into environment variables
# and can come from either service. However, containers can also have
# Docker repository credentials specified, and these can only be
# Secrets Manager secrets.
#
# The relevant variables are:
#
#   var.ssm_enabled: whether to allow SSM access
#
#   var.ssm_paths: SSM paths to allow access to
#
#   var.secretsmanager_enabled: whether to allow Secrets Manager access
#
#   var.secretsmanager_secret_arns: Secrets Manager ARNs to allow
#       access to, a combination of repository credentials specified
#       as the top-level 'repository_credentials_secret_arn' parameter
#       and any container secrets specified as Secrets Manager ARNs.

# We need the AWS Account ID for the SSM Permissions
data "aws_caller_identity" "current" {
  count = var.create ? 1 : 0
}

# Assume Role Policy for the ECS Task
data "aws_iam_policy_document" "ecs_task_assume_role" {
  count = var.create ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# The ECS TASK ROLE execution role needed for FARGATE & AWS LOGS
resource "aws_iam_role" "ecs_task_execution_role" {
  count              = var.create && var.fargate_enabled || var.secretsmanager_enabled ? 1 : 0
  name               = "${var.name}-ecs-task-execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role[0].json
  tags               = var.tags
}

# We need this for tasks with an execution role, e.g. those using Fargate or SSM secrets
resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  count      = var.create && var.fargate_enabled || var.secretsmanager_enabled ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The actual ECS TASK ROLE
resource "aws_iam_role" "ecs_tasks_role" {
  count              = var.create ? 1 : 0
  name               = "${var.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role[0].json
  tags               = var.tags
}

# Policy Document to allow KMS Decryption with given keys
data "aws_iam_policy_document" "kms_permissions" {
  count = var.create && var.kms_enabled ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = var.kms_keys
  }
}

# Allow KMS-Decrypt permissions for the ECS Task Role
resource "aws_iam_role_policy" "kms_permissions" {
  count  = var.create && var.kms_enabled ? 1 : 0
  name   = "${var.name}-kms-permissions"
  role   = aws_iam_role.ecs_tasks_role[0].id
  policy = data.aws_iam_policy_document.kms_permissions[0].json
}

# Policy Document to allow access to SSM Parameter Store paths
data "aws_iam_policy_document" "ssm_permissions" {
  count = var.create && var.ssm_enabled && length(var.ssm_paths) > 0 ? 1 : 0

  ## Add Describe Parameters as per https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-access.html
  statement {
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  ## With the custom application prefix for ssm
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter", "ssm:GetParametersByPath", "ssm:GetParameters"]
    resources = formatlist(
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current[0].account_id}:parameter/application/%s/*",
      var.ssm_paths,
    )
  }

  ## And also without the application prefix
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter", "ssm:GetParametersByPath", "ssm:GetParameters"]
    resources = formatlist(
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current[0].account_id}:parameter/%s/*",
      var.ssm_paths,
    )
  }
}

# Add the SSM policy to the task role
resource "aws_iam_role_policy" "ssm_permissions" {
  count  = var.create && var.ssm_enabled && length(var.ssm_paths) > 0 ? 1 : 0
  name   = "${var.name}-ssm-permissions"
  role   = aws_iam_role.ecs_tasks_role[0].id
  policy = data.aws_iam_policy_document.ssm_permissions[0].json
}

# Add the SSM policy to the task execution role
resource "aws_iam_role_policy" "ssm_permissions_execution" {
  count  = var.create && var.ssm_enabled && length(var.ssm_paths) > 0 ? 1 : 0
  name   = "${var.name}-ssm-permissions-execution-role"
  role   = aws_iam_role.ecs_task_execution_role[0].id
  policy = data.aws_iam_policy_document.ssm_permissions[0].json
}

# Policy document allowing access to the repository credentials secret
data "aws_iam_policy_document" "sm_secrets" {
  count = var.secretsmanager_enabled && length(var.secretsmanager_secret_arns) > 0 ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [for arn in var.secretsmanager_secret_arns: "${arn}-??????"]
  }
}

resource "aws_iam_role_policy" "sm_secrets" {
  count  = var.secretsmanager_enabled && length(var.secretsmanager_secret_arns) > 0 ? 1 : 0
  name   = "${var.name}-secretsmanager-permissions"
  role   = aws_iam_role.ecs_task_execution_role[0].id
  policy = data.aws_iam_policy_document.sm_secrets[0].json
}

# Policy Document to allow S3 Read-Write Access to given paths
data "aws_iam_policy_document" "s3_rw_permissions" {
  count = var.create ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = formatlist("arn:aws:s3:::%s", var.s3_rw_paths)
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = formatlist("arn:aws:s3:::%s/*", var.s3_rw_paths)
  }
}

# Policy Document to allow S3 Read-Only Access to given paths
data "aws_iam_policy_document" "s3_ro_permissions" {
  count = var.create ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = formatlist("arn:aws:s3:::%s", var.s3_ro_paths)
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = formatlist("arn:aws:s3:::%s/*", var.s3_ro_paths)
  }
}

# Add the S3 Read-Write policy to the task role
resource "aws_iam_role_policy" "s3_rw_permissions" {
  name   = "s3-read-write-policy"
  count  = var.create && length(var.s3_rw_paths) > 0 ? 1 : 0
  role   = aws_iam_role.ecs_tasks_role[0].id
  policy = data.aws_iam_policy_document.s3_rw_permissions[0].json
}

# Add the S3 Read-Only policy to the task role
resource "aws_iam_role_policy" "s3_ro_permissions" {
  count  = var.create && length(var.s3_ro_paths) > 0 ? 1 : 0
  name   = "s3-readonly-policy"
  role   = aws_iam_role.ecs_tasks_role[0].id
  policy = data.aws_iam_policy_document.s3_ro_permissions[0].json
}

### Lambdas

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

# Policy for the ecs lookup lambda
data "aws_iam_policy_document" "lambda_lookup_policy" {
  count = var.create ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:ListTaskDefinitions",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      format(
        "arn:aws:logs:%s:%s:log-group:/aws/lambda/%s-lambda-lookup:*",
        var.region,
        join("", data.aws_caller_identity.current.*.account_id),
        var.name,
      ),
    ]

    effect = "Allow"
  }

  statement {
    actions = ["logs:PutLogEvents"]

    resources = [
      format(
        "arn:aws:logs:%s:%s:log-group:/aws/lambda/%s-lambda-lookup:*.*",
        var.region,
        join("", data.aws_caller_identity.current.*.account_id),
        var.name,
      ),
    ]

    effect = "Allow"
  }
}

# Role for lambda to lookup the ecs cluster & services
resource "aws_iam_role" "lambda_lookup" {
  count              = var.create ? 1 : 0
  name               = "ecs-lambda-lookup-${var.name}"
  description        = "Role permitting Lambda functions to be invoked from Lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_lookup_policy" {
  count  = var.create ? 1 : 0
  role   = aws_iam_role.lambda_lookup[0].name
  policy = data.aws_iam_policy_document.lambda_lookup_policy[0].json
}

# Policy for the Lambda Logging & ECS
data "aws_iam_policy_document" "lambda_ecs_task_scheduler_policy" {
  count = var.create ? 1 : 0

  statement {
    actions = [
      "iam:PassRole",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:RunTask",
    ]

    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "ecs:cluster"
      values   = ["arn:aws:ecs:${var.region}:*:cluster/${var.ecs_cluster_id}"]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:ListTaskDefinitions",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      format(
        "arn:aws:logs:%s:%s:log-group:/aws/lambda/%s-task-scheduler:*",
        var.region,
        join("", data.aws_caller_identity.current.*.account_id),
        var.name,
      ),
    ]

    effect = "Allow"
  }

  statement {
    actions = ["logs:PutLogEvents"]

    resources = [
      format(
        "arn:aws:logs:%s:%s:log-group:/aws/lambda/%s-task-scheduler:*.*",
        var.region,
        join("", data.aws_caller_identity.current.*.account_id),
        var.name,
      ),
    ]

    effect = "Allow"
  }
}

# Role for the lambda
resource "aws_iam_role" "lambda_ecs_task_scheduler" {
  count              = var.create && var.task_scheduler_enabled ? 1 : 0
  name               = "ecs-lambda-task-scheduler-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "lambda_ecs_task_scheduler_policy" {
  count  = var.create && var.task_scheduler_enabled ? 1 : 0
  role   = aws_iam_role.lambda_ecs_task_scheduler[0].name
  policy = data.aws_iam_policy_document.lambda_ecs_task_scheduler_policy[0].json
}

# Role for ECS scheduled task
data "aws_iam_policy_document" "scheduled-task-cloudwatch-assume-role-policy" {
  count = var.create ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "scheduled_task_cloudwatch_policy" {
  count = var.create ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]

    #    resources = ["${aws_iam_role.ecs_task_execution_role.arn}"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "scheduled_task_cloudwatch" {
  count              = var.create && var.is_scheduled_task ? 1 : 0
  name               = "cloudwatch_ecs_task-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.scheduled-task-cloudwatch-assume-role-policy[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "scheduled_task_cloudwatch_policy" {
  count  = var.create && var.is_scheduled_task ? 1 : 0
  name   = "${var.name}-scheduled-task-policy"
  role   = aws_iam_role.scheduled_task_cloudwatch[0].id
  policy = data.aws_iam_policy_document.scheduled_task_cloudwatch_policy[0].json
}

