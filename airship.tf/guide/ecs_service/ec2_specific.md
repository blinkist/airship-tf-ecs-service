---
sidebarDepth: 2
---

# EC2 Specific

For EC2 Backed ECS Cluster nodes there are a few extra configuration possibilties.

## Placement Strategy

By default the ECS Scheduler is not placing the ECS Tasks of an ECS Cluster spread, in some cases this can lead to
having a tasks belonging to one ECS Service placed on one EC2 instance, even when there are multiple EC2 Instances available.

By enabling `with_placement_strategy` in the module, the ECS tasks are configured with the following spread.


```json
module "demo_web" {
  ..
  with_placement_strategy = true
  ..
}
```

Configured spread inside the ECS Service.

```json
ordered_placement_strategy {
  field = "attribute:ecs.availability-zone"
  type  = "spread"
}

ordered_placement_strategy {
  field = "instanceId"
  type  = "spread"
}

ordered_placement_strategy {
  field = "memory"
  type  = "binpack"
}
```

## Scheduling Strategy

The [Service Scheduler](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html#service_scheduler) is set to 'Replica' by default. The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. 

The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, there is no need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For example, this can be helpful to run monitoring tools on the ECS Cluster where exactly one task is needed per instance.


```json
module "demo_web" {
  ..
  scheduling_strategy = "DAEMON"
  ..
}
```

## Volume Mounting

When running on an EC2 backed ECS cluster, it is possible to mount folders from the host machines inside task containers.

```json
module "mycluster" {
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "0.5.1"
  
  name = "mycluster"

  ...
  
  cluster_properties = {
    ...
    efs_enabled = true            # Mount a volume to "/efs" on every EC2 host instance in the cluster
    efs_id      = "${var.efs_id}" # EFS volume id
  }
}

module "myservice" {
  source  = "blinkist/airship-ecs-service/aws"
  version = "0.9.7"

  name                      = "myservice"
  bootstrap_container_image = "nginx:stable"
  container_cpu             = 256
  container_memory          = 512
  ecs_cluster_id            = "${module.mycluster.id}"
  region                    = "eu-west-1"

  # Maps host folders as volumes
  host_path_volumes = [{
    name      = "efs"
    host_path = "/mnt/efs/myservice"
  }]

  # Mounts volumes inside containers
  mountpoints = [{
    sourceVolume  = "efs"
    containerPath = "/usr/share/nginx/html" # This dir is what the nginx server serves at http://localhost:80/
    readOnly      = "false" # Must be quoted string!
  }]
}
```