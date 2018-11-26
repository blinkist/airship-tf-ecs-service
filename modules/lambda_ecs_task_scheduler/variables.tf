# create defines if resources are created inside this module
variable "create" {}

# ecs_cluster_id sets the cluster id
variable "ecs_cluster_id" {}

# ecs_service_name sets the service name
variable "ecs_service_name" {}

# Container name to run the command in
variable "container_name" {}

# Role of the AWS Lambda
variable "lambda_ecs_task_scheduler_role_arn" {}

# ecs_cron_tasks holds a list of maps defining the scheduled jobs which need to run
#
#
#  [{
#     # name of the scheduled task
#     job_name  = "vacuum_db"
#
#     # expression defined in
#     # http://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
#     schedule_expression  = "cron(0 12 * * ? *)"
#
#     # command defines the command which needs to run inside the docker container
#     command = "python vacuum_db.py"
#
#   },]
variable "ecs_cron_tasks" {
  type    = "list"
  default = []
}

# Tags applied to the resources in the submodule
variable "tags" {
  type    = "map"
  default = {}
}
