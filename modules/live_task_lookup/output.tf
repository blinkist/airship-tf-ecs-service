locals {
  empty_lookup = {
    environment        = ""
    image              = ""
    cpu                = ""
    memory             = ""
    memory_reservation = ""
    task_revision      = ""
    docker_label_hash  = ""
  }

  # Lambda invoke returns a map, but as it's inside a conditional coalescelist make sure it can be looked up when it does not exist
  safe_lambda_lookup = "${coalescelist(data.aws_lambda_invocation.lambda_lookup.*.result_map, list(local.empty_lookup))}"

  # First item of the list is the actual map
  lambda_lookup = "${local.safe_lambda_lookup[0]}"

  # data.aws_ecs_container_definition.lookup returns a map, coalescelist again makes it save to use inside a conditional
  environment_coalesce = "${coalescelist(data.aws_ecs_container_definition.lookup.*.environment, list(map()))}"

  dockerlabels_coalesce = "${coalescelist(data.aws_ecs_container_definition.lookup.*.docker_labels, list(map("_airship_dockerlabel_hash","")))}"
}

output "docker_label_hash" {
  value = "${var.lookup_type == "lambda" ? 
              lookup(local.lambda_lookup, "docker_label_hash", "") :
                ( var.lookup_type == "datasource" ?
                   lookup(local.dockerlabels_coalesce[0],"_airship_dockerlabel_hash", "") : "" )}"
}

output "environment_json" {
  value = "${var.lookup_type == "lambda" ? 
              lookup(local.lambda_lookup, "environment", "") :
                ( var.lookup_type == "datasource" ?
                   jsonencode(local.environment_coalesce[0]) : "" )}"
}

output "image" {
  value = "${var.lookup_type == "lambda" ? 
                lookup(local.lambda_lookup, "image", "") : 
                  ( var.lookup_type == "datasource" ? 
                     element(concat(data.aws_ecs_container_definition.lookup.*.image, list("")), 0) : "" )}"
}

output "cpu" {
  value = "${var.lookup_type == "lambda" ? 
              lookup(local.lambda_lookup, "cpu", "") : 
                ( var.lookup_type == "datasource" ? 
                   element(concat(data.aws_ecs_container_definition.lookup.*.cpu, list("")), 0) : "" )}"
}

output "memory" {
  value = "${var.lookup_type == "lambda" ? 
              lookup(local.lambda_lookup, "memory", "") : 
                ( var.lookup_type == "datasource" ? 
                   element(concat(data.aws_ecs_container_definition.lookup.*.memory, list("")), 0) : "" )}"
}

output "memory_reservation" {
  value = "${var.lookup_type == "lambda" ? 
              lookup(local.lambda_lookup, "memory_reservation", "") : 
                ( var.lookup_type == "datasource" ? 
                   element(concat(data.aws_ecs_container_definition.lookup.*.memory_reservation, list("")), 0) : "" )}"
}

output "revision" {
  value = "${var.lookup_type == "lambda" ? 
              lookup(local.lambda_lookup, "task_revision", "") : 
                ( var.lookup_type == "datasource" ? 
                   element(concat(data.aws_ecs_task_definition.lookup.*.revision, list("")), 0) : "" )}"
}
