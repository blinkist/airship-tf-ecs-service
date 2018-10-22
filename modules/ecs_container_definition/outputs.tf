#
# This code was adapted from the `terraform-aws-ecs-container-definition` module from Cloud Posse, LLC on 2018-09-18.
# Available here: https://github.com/cloudposse/terraform-aws-ecs-container-definition
#

output "json" {
  description = "JSON encoded container definitions for use with other terraform resources such as aws_ecs_task_definition."

  # The following hack is required to overcome TF automatic type conversions which lead to issues with the resulting json types.
  # Conversion happens by using the built-in `replace` function in this order:
  #  - Convert `""`, `{}`, `[]`, and `[""]` to `null`
  #  - Convert `"true"` and `"false"` to `true` and `false`
  #  - Convert quoted numbers (e.g. `"123"`) to `123`.
  # Environment variables are kept as strings.
  value = "${replace(replace(replace(jsonencode(local.container_definitions[local.use_port]), "/(\\[\\]|\\[\"\"\\]|\"\"|{})/", "null"), "/(\"[^v][[:alpha:]]+\":)\"([0-9]+\\.?[0-9]*|true|false)\"/", "$1$2"),local.safe_search_replace_string,"")}"
}
