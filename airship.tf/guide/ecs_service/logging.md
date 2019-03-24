---
sidebarDepth: 2
---

# Logging

The ECS Services log to Cloudwatch and are by default kept for 14 days and unencrypted. It can be configured to have the logs encrypted by a given KMS key, together with a different retention.

They log to the log-group with the following interpolated name: `<ecs_cluster_name>/<ecs_service_name>`


```json
module "demo_web" {
  ..
  # cloudwatch_kms_key = ".. arn of kms key"
  # log_retention_in_days = "14"
  ..
}
```
