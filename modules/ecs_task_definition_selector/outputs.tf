output "selected_task_definition_for_deployment" {
  value = "${local.task_definition}"
}

output "has_changed" {
  value = "${
    format("\n%v\n%v\n%v\n%v\n%v\n%v\n%v\n",
    format("Image: %v | %v", local.image[0], var.live_aws_ecs_task_definition_image),
    format("CPU: %v | %v", local.cpu[0], var.live_aws_ecs_task_definition_cpu),
    format("Memory: %v | %v", local.memory[0], var.live_aws_ecs_task_definition_memory),
    format("Memory Reservation: %v | %v", local.memory_reservation[0], "${var.live_aws_ecs_task_definition_memory_reservation == "undefined" ? "0" : var.live_aws_ecs_task_definition_memory_reservation}"),
    format("Docker Labels: %v | %v", lookup(local.docker_labels[0],"_airship_dockerlabel_hash",""), var.live_aws_ecs_task_definition_docker_label_hash),
    format("Environment: %v | %v", jsonencode(local.environment[0]) , var.live_aws_ecs_task_definition_environment_json),
    format("Has_changed: %v", local.has_changed))
    }"
}
