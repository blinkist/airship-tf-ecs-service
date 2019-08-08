---
sidebarDepth: 2
---

# Scheduled tasks

Airship supports two types of scheduled tasks. 

"Cron tasks" are commands that are run inside running task containers at intervals.

"ECS Scheduled Tasks" are containers that are started at intervals by CloudWatch rules, and run until they terminate naturally.


## Cron tasks

In many environments it's common to have cronjob like tasks. This module provide an easy way of configuring cron jobs for a running docker. The cronjobs will not be executed inside a running docker but a new task will be executed and the configured command will be ran.

<mermaid/>
<div class="mermaid">
sequenceDiagram
    Cloudwatch Event->>Lambda: Triggers Lambda at given rate
    Lambda->>AWS API ECS: Asks for task definition of current running service
    AWS API ECS-->>Lambda: task definition
    Lambda->>AWS API ECS: Start Task Definition with given command
</div>

## Implementation

The `ecs_cron_tasks` parameter holds a list of maps with information regarding the 'cron' jobs.

```json
   # ecs_cron_tasks holds a list of maps defining scheduled jobs
   # when ecs_cron_tasks holds at least one 'job' a lambda will be created which will
   # trigger jobs with the currently running task definition. The given command will be used
   # to override the CMD in the dockerfile. The lambda will prepend this command with ["/bin/sh", "-c" ]
   ecs_cron_tasks = [
   {
     # name of the scheduled task
     job_name            = "vacuum_db"
     # expression defined in
     # http://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
     schedule_expression = "cron(0 12 * * ? *)"
   
     # command defines the command which needs to run inside the docker container
     command             = "/usr/local/bin/vacuum_db"
    },{
     # name of the scheduled task
     job_name            = "something_else"
     # expression defined in
     # http://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
     schedule_expression = "rate(10 minutes)"
   
     # command defines the command which needs to run inside the docker container
     command             = "/usr/local/bin/something_else"
   }
   ]
```

## ECS Scheduled Tasks

Scheduled tasks are a good fit for replacing containers that spend most of their time idle, and only occasionally run batch jobs or other maintenance.
They use AWS [scheduled tasks](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html) to start temporary containers at intervals. 
The containers are expected to run and terminate when they are done.

```json
module "myservice" {
  source  = "blinkist/airship-ecs-service/aws"
  version = "0.9.7"

  name                      = "myservice"
  bootstrap_container_image = "hello-world:latest"
  container_cpu             = 256
  container_memory          = 512
  ecs_cluster_id            = "${var.cluster_id}"
  region                    = "eu-west-1"

  # Run the hello world task in one container every 15 minutes
  is_scheduled_task         = true
  scheduled_task_expression = "rate(15 minutes)" # Same as "cron(0,15,30,45 * * * *)"
  scheduled_task_count      = 1
}
```
