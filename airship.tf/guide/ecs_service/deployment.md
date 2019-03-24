---
sidebarDepth: 2
---

# Deployment & drift detection

## Deployment

The idea with the module is that third party software and pipelines are used to deploy docker image with. Unless configured different Terraform will only deploy the bootstrap_container_image the moment the ECS Service Module is being applied for the first time.

Popular tools for deploying Docker images are:

* [ECS Deploy](https://github.com/silinternational/ecs-deploy)
* [AWS Codepipeline](https://aws.amazon.com/codepipeline/)
* [Deploy fish](https://github.com/caltechads/deployfish)

The parameter `bootstrap_container_image` defines the container image for the container definition for the first time. After the service has been deployed it will not be used anymore unless `force_bootstrap_container_image` is set to true.
```json
  # force_bootstrap_container_image to true will force the deployment to use var.bootstrap_container_image as container_image
  # if container_image is already deployed, no actual service update will happen
  # force_bootstrap_container_image = false
  bootstrap_container_image = "nginx:stable"
```

<mermaid/>

## Drift Detection

*A diagram of the interaction between the submodules with the ECS Service Module.*

<div class="mermaid">
sequenceDiagram
    ECS Module->>live_task_lookup: Retrieve image of running ECS Task
    live_task_lookup->>live_task_lookup: Invoke lambda to check for current live task
    live_task_lookup-->>ECS Module: live_image
    ECS Module->>ecs_container_definition: create container def with live image or parameter image
    ecs_container_definition-->>ECS Module: return container definition
    ECS Module->>ecs_task_definition: create task definition with new container definition
    ecs_task_definition-->>ECS Module:task version
    ECS Module->>ecs_task_definition_selector: return the live task definition when no change has been made
    ecs_task_definition_selector-->>ECS Module: live or new task definition version
    ECS Module->>ecs_service: Update Service with given task definition version
</div>


When using the module for the first time, a Task Definition is created with a container definition. This container definition has the `bootstrap_container_image`, cpu and memory capacity, environment variables and other params defined inside the submodule : ecs_container_definition. 

These deployment tools create a new Task Definition, by copying the current Task Definition in use and replacing the image with what is given as parameter. After creation of the new Task Definition, the ECS Service task definition attribute will be set to the newly created ECS Task definition. ECS takes care of the deployment without downtime, this can either be configured as rolling or something similar to a green/blue deployment.

As updates happen outside of the Terraform State a so called drift takes place. The ECS Service in Terraform is still pointing to an older version of the Task definition. The ECS Module takes care of that by looking up the current active ECS Task definition. It grabs the running image from the live container definition and it creates a new Task Definition with the updated image. If there are no changes between the live task definition and the newly created one. The ECS Service will keep pointing to the live definition and no actual update takes place.


## Policy for deployment

The IAM User or IAM Role which updates the ECS Service with new Task Definitions need the following IAM Policy.
```json
data "aws_iam_policy_document" "ecs_deploy_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:ListTaskDefinitions",
      "ecs:RegisterTaskDefinition",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:UpdateService",
      "iam:PassRole",
    ]

    resources = ["*"]
  }
}
```

