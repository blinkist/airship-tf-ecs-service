variable "create" {
  default = true
}

variable "region" {
  default = ""
}

variable "name" {
  default = ""
}

variable "ecs_cluster_id" {
}

variable "fargate_enabled" {
  default = false
}

variable "container_secrets_enabled" {
  description = "true, if the container needs access to SSM secrets"
  default     = false
}

variable "kms_enabled" {
  description = "Whether to provide access to the supplied kms_keys. If no kms keys are passed, set this to false."
  default     = false
}

variable "kms_keys" {
  description = "List of KMS keys the task has access to."
  default     = []
}

variable "ssm_enabled" {
  description = "Whether to provide access to the supplied ssm_paths. If no ssm paths are passed, set this to false."
  default     = false
}

variable "ssm_paths" {
  description = "List of SSM Paths the task has access to."
  default     = []
}

variable "secretsmanager_secret_arns" {
  description = "ARNs of Secrets Manager secrets to allow access to"
  default = []
}

variable "s3_ro_paths" {
  description = "S3 Read-only paths the Task has access to."
  default     = []
}

variable "s3_rw_paths" {
  description = "S3 Read-write paths the Task has access to."
  default     = []
}

variable "is_scheduled_task" {
  description = "If true, this not a service, but a schedulked task."
  default     = false
}

