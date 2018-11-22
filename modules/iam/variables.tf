variable "create" {
  default = true
}

variable "region" {
  default = ""
}

variable "name" {
  default = ""
}

variable "ecs_cluster_id" {}

variable "fargate_enabled" {
  default = false
}

# Whether to provide access to the supplied kms_keys. If no kms keys are
# passed, set this to false.
variable "kms_enabled" {
  default = true
}

# List of KMS keys the task has access to
variable "kms_keys" {
  default = []
}

# Whether to provide access to the supplied ssm_paths. If no ssm paths are
# passed, set this to false.
variable "ssm_enabled" {
  default = true
}

# List of SSM Paths the task has access to
variable "ssm_paths" {
  default = []
}

# S3 Read-only paths the Task has access to
variable "s3_ro_paths" {
  default = []
}

# S3 Read-write paths the Task has access to
variable "s3_rw_paths" {
  default = []
}
