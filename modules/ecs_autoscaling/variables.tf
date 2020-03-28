# Internal lookup map
variable "direction" {
  type = map(list(string))

  default = {
    up   = ["GreaterThanOrEqualToThreshold", "scale_out"]
    down = ["LessThanThreshold", "scale_in"]
  }
}

# Sets the cluster_name 
variable "cluster_name" {
  type = string
}

# Sets the ecs_service name
variable "ecs_service_name" {
  type = string
}

# Do we create resources
variable "create" {
  type = bool
}

# The minimum capacity in tasks for this service
variable "desired_min_capacity" {
  type = number
}

# The maximum capacity in tasks for this service
variable "desired_max_capacity" {
  type = number
}

# List of maps with scaling properties
variable "scaling_properties" {
  type    = list(map(string))
  default = []
}

variable "tags" {
  description = "A map of tags to apply to all taggable resources"
  type        = map(string)
  default     = {}
}
