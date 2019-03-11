variable "cluster_name" {
  type        = "string"
  description = "Get the ecs cluster name"
}

variable "schedule_scale_up" {
  type        = "string"
  description = "Set the schedule with the at or the cron notation e.g. cron(* * ? * SAT-SUN *)"
  default     = ""
}

variable "schedule_scale_down" {
  type        = "string"
  description = "Set the schedule with the at or the cron notation e.g. cron(* * ? * SAT-SUN *)"
  default     = ""
}

variable "ecs_service_name" {
  type        = "string"
  description = "Ecs service name"
}

variable "desired_min_capacity" {
  type        = "string"
  description = "The minimum capacity in tasks for this service"
}

variable "desired_max_capacity" {
  type        = "string"
  description = "The maximum capacity in tasks for this service"
}

variable "scalable_target_action_min_capacity_down" {
  type        = "string"
  description = "The min capacity of the scalable target when scaling down."
  default     = 0
}

variable "scalable_target_action_max_capacity_down" {
  type        = "string"
  description = "The max capacity of the scalable target when scaling down."
  default     = 0
}

variable "scalable_target_action_min_capacity_up" {
  type        = "string"
  description = "The max capacity of the scalable target when scaling up. Defaults to desired_min_capacity if not specified"
  default     = ""
}

variable "scalable_target_action_max_capacity_up" {
  type        = "string"
  description = "The max capacity of the scalable target when scaling up. Defaults to desired_man_capacity if not specified"
  default     = ""
}

variable "scaling_properties" {
  type        = "list"
  description = "Pass the scaling properties here to check if the autoscaling_app_target should be created"
  default     = []
}

variable "service_namespace" {
  type        = "string"
  description = "If another autoscaling_app_target is created this variable is used to pass on the service_namespace from it"
  default     = ""
}

variable "resource_id" {
  type        = "string"
  description = "If another autoscaling_app_target is created this variable is used to pass on the resource_id from it"
  default     = ""
}

variable "scalable_dimension" {
  type        = "string"
  description = "If another autoscaling_app_target is created this variable is used to pass on the scalable_dimension from it"
  default     = ""
}
