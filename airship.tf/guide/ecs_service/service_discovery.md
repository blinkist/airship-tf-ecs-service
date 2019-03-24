---
sidebarDepth: 2
---

# Service Discovery

Please read [this](https://aws.amazon.com/blogs/aws/amazon-ecs-service-discovery/) article, on how Service Discovery can work for you.

`aws_service_discovery_private_dns_namespace` creates the private dns namespace and route53 zone needed needed for the ECS Services to register to.

```json
resource "aws_service_discovery_private_dns_namespace" "namespace" {
  name        = "namespace.local"
  description = "Description"
  vpc         = "${module.vpc.vpc_id}"
}
```

<br/>
<br/>
<br/>

The ECS Module has only implemented Service discovery for non-public namespaces. Only for AWSVPC networked ECS Services the `dns_type` A can be used, for bridge mode `SRV`.

<br/>
<br/>
<br/>

::: warning
Apply Terraform first with the `aws_service_discovery_private_dns_namespace` resource before continuing.
:::
<br/>

```json
module "demo_web" {
  ..
  service_discovery_enabled = true

  service_discovery_properties_namespace_id                         = "${aws_service_discovery_private_dns_namespace.namespace.id}"
  service_discovery_properties_dns_ttl                              = "60"
  service_discovery_properties_dns_type                             = "A"
  service_discovery_properties_routing_policy                       = "MULTIVALUE"
  service_discovery_properties_healthcheck_custom_failure_threshold = "1"
  ..
}
```
