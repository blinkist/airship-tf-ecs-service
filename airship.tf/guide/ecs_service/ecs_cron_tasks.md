---
sidebarDepth: 2
---

# ECS Cron tasks

## Introduction
In many environments it's common to have cronjob like tasks. This module provide an easy way of configuring crontjobs for a running docker. The cronjobs will not be executed inside a running docker but a new task will be executed and the configured command will be ran.

<mermaid/>
<div class="mermaid">
sequenceDiagram
    Cloudwatch Event->>Lambda: Triggers Lambda at given rate
    Lambda->>AWS API ECS: Asks for task definition of current running service
    AWS API ECS-->>Lambda: task definition
    Lambda->>AWS API ECS: Start Task Definition with given command
</div>

## Implementation

The `ecs_cron_tasks` param holds a list of maps with information regarding the 'cron' jobs.

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
