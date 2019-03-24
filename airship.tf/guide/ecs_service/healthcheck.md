---
sidebarDepth: 2
---

# Health Checks

The AWS / ECS ecosystem has a few ways of discovering if a task is healthy or not.

## Process

The most basic health check is if the docker process is running. The moment the process of a docker dies the task is marked as unhealthy.

## Load Balancer Checks

In case of ALB the `health_uri` defines which URI the Application Load Balancer requests from the ECS Task. The task is marked healthy as long as a HTTP 200 OK is returned. In case it does not `unhealthy_threshold` sets the amount of errored requests before the task is marked unhealthy.

```json
      .. 
      .. 
      # After which threshold in health check is the task marked as unhealthy, defaults to 3
      # load_balancing_properties_unhealthy_threshold   = "3"
  
      # load_balancing_properties_health_uri defines which health-check uri the target group needs to check on for health_check, defaults to /ping
      # load_balancing_properties_health_uri = "/ping"
  
      # The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds.
      load_balancing_properties_deregistration_delay = "10"
    }
```


## Docker Healthcheck

Docker provides a [HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck) directive to use from within docker. Without using the Dockerfile directive, the ECS Module has a parameter `container_healthcheck`.

```json
  container_healthcheck = {
    command     = ["CMD-SHELL", "curl http://localhost:port/"]
    interval    = "10"
    startperiod = "120"
    retries     = "3"
    timeout     = "5"
  }
```
:::warning
All vars of the container_healthcheck map need to be filled or ECS will keep updating the Task Definition.
:::
