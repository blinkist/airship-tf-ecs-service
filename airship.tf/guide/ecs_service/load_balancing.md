---
sidebarDepth: 2
---

# Load balancing

## types

Through the ECS Module the ECS Service can be connected to different types of Load Balancers or no load balancer at all.

The parameter `load_balancing_type` can be set to three options:
* `application` - Application Load Balancer
* `network` - Network Load Balancer
* `none` - No load balancer

### None

When set to `none` the ECS Service is not connected to a load balancer and will most likely function as a type of worker. Without a load balancer checking health check URL's the process is only marked unhealthy the moment the process is killed or when the docker `HEALTHCHECK` is failing.

```json
module "demo_web" {
  ..
  load_balancing_type = "none"
  ..
}
```

<mermaid/>

### Application LB

The Appication Load Balancer ( ALB ) can forward traffic of multiple domain names to different ECS Services by creating so called [lb_listener_rules](https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html). This module can create listener rules on both the HTTP as the HTTPS listener. Based on the `host-header` ALB traffic will be forwarded to the right ECS Service. The Application Load Balancer is not transparent and traffic needs to be allowed. See [ECS Service networking](/guide/ecs_service/#ecs-service-networking) for more information.

As many services can be connected to a single Applicaation Load Balancer, the load b


By default the Module will create a record in the given `route53_zone_id` with the value of the name of the service, e.g. &lt;ecs_name&gt;.zone.tld. The parameter `route53_record_type` can be set to either `NONE`, `ALIAS` or `CNAME`. In case `NONE` is given, no record will be made inside the Route53 Zone. `ALIAS` has as advantage that multiple records with the same name can be made, this can help a migration to a different service at a later stage.

For every host inside the module parameter `custom_listen_hosts` this module will create a listener rule pointing to your ECS Service. With the code snippet in mind of below, and if www.example.com is pointed to the ALB, traffic with www.example.com as host header will be be forwarded to the running ECS tasks of the service.

```json
module "demo_web" {
  ..
  ..
  name = "airship-web"
  ..
  # load_balancing_enabled sets if a load balancer will be attached to the ecs service / target group
  load_balancing_type = "application"
  # The ARN of the ALB, when left-out the service, will not be attached to a load-balance
  load_balancing_properties_lb_arn                = "${module.alb_shared_services_ext.load_balancer_id}"
  # https listener ARN
  load_balancing_properties_lb_listener_arn_https = "${element(module.alb_shared_services_ext.https_listener_arns,0)}"
  # http listener ARN
  load_balancing_properties_lb_listener_arn       = "${element(module.alb_shared_services_ext.http_tcp_listener_arns,0)}"
  load_balancing_properties
  # The VPC_ID the target_group is being created in
  load_balancing_properties_lb_vpc_id             = "${module.vpc.vpc_id}"
  # The route53 zone for which we create a subdomain
  load_balancing_properties_route53_zone_id       = "${aws_route53_zone.shared_ext_services_domain.zone_id}"

  # After which threshold in health check is the task marked as unhealthy, defaults to 3
  load_balancing_properties_unhealthy_threshold   = "3"

  # load_balancing_properties_unhealthy_threshold_health_uri defines which health-check uri the target group needs to check on for health_check, defaults to /ping
  # load_balancing_properties_unhealthy_threshold_health_uri = "/ping"

  # The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds.
  load_balancing_properties_deregistration_delay = "10"

  custom_listen_hosts    = ["www.example.com"]

```

This sample would create ...


<div class="mermaid">
graph LR
    subgraph Module Scope
    0
    end
    0[fa:fa-ban DNS Domain ecs_name.zone.tld]-->B[fa:fa-ban ALB]
    B-->C[fa:fa-ban ALB HTTP Listener]
    B-->D[fa:fa-ban ALB HTTPS Listener]
    C-->E[fa:fa-ban LB Listener Rule for ecs_name.zone.tld]
    D-->F[fa:fa-ban LB Listener Rule for ecs_name.zone.tld]
    C-->L[fa:fa-ban LB Listener Rule for custom_domains optional]
    D-->M[fa:fa-ban LB Listener Rule for custom_domains optional]
    subgraph Module Scope
    E-->G[fa:fa-ban Target Group]
    F-->G[fa:fa-ban Target Group]
    L-->G[fa:fa-ban Target Group]
    M-->G[fa:fa-ban Target Group]
    G-->H[fa:fa-ban ECS Service]
    G-->I[fa:fa-ban ECS Service]
    subgraph ECS Cluster
    subgraph ECS Service
    H[fa:fa-ban ECS Task N]
    I[fa:fa-ban ECS Task N+1]
    end
    end
    H-.->J[fa:fa-ban Task Definition:version]
    I-.->J[fa:fa-ban Task Definition:version]
    end
</div>

### Application LB HTTPS Redirect

The ECS Module can also redirect HTTP traffic to HTTPS using [ALB Listener Rule - Redirect actions](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#redirect-actions). Setting load_balancing_properties `redirect_http_to_https` to true will create LB Listener rules for the HTTP listener which won't forward traffic to the ECS Service but redirect the HTTP client to HTTPS.

```json{20}
module "demo_web" {
  ..
  ..
  name = "airship-web"
  ..
  # load_balancing_enabled sets if a load balancer will be attached to the ecs service / target group
  load_balancing_type = "application"
  load_balancing_properties {
    # The ARN of the ALB, when left-out the service, will not be attached to a load-balance
    load_balancing_properties_lb_arn                = "${module.alb_shared_services_ext.load_balancer_id}"
    # https listener ARN
    load_balancing_properties_lb_listener_arn_https = "${element(module.alb_shared_services_ext.https_listener_arns,0)}"
  
    # The VPC_ID the target_group is being created in
    load_balancing_properties_lb_vpc_id             = "${module.vpc.vpc_id}"
  
    # The route53 zone for which we create a subdomain
    load_balancing_properties_route53_zone_id       = "${aws_route53_zone.shared_ext_services_domain.zone_id}"

    load_balancing_properties_redirect_http_to_https = true
  }
  ..
  ..
```



### Application LB Cognito Authentication

Cognito provides an easy way to add authentication to any of your HTTP endpoints. A simple user pool can be created in Cognito which can be used to authenticate your users with. The following codeblock is a sample on how to create a cognito user pool.

```json
resource "aws_cognito_user_pool" "main" {
  name = "testpool"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 6
    require_lowercase = false
    require_uppercase = false
    require_numbers   = false
    require_symbols   = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
    unused_account_validity_days = 7

    invite_message_template {
      email_message = "Your username is {username} and temporary password is {####}. "
      email_subject = "Your temporary password"
      sms_message   = "Your username is {username} and temporary password is {####}. "
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
  }
}

resource "aws_cognito_user_pool_domain" "pool" {
  domain       = "testdomain"
  user_pool_id = "${aws_cognito_user_pool.main.id}"
}

resource "aws_cognito_user_pool_client" "client" {
  name                                 = "tfAWS"
  generate_secret                      = "true"
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  callback_urls                        = ["https://domain_of_your_http_endpoint/oauth2/idpresponse"]

  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile",
    "aws.cognito.signin.user.admin",
  ]

  user_pool_id = "${aws_cognito_user_pool.main.id}"
}

```

After you have created the userpool, you can add a user like this. In this example, only Administrators can create new users.

<img :src="$withBase('/cognito_create_user.png')" alt="create cognito user">



::: warning
Before the ECS Module can user the cognito user pool it needs to be applied with Terraform first.
:::


The `cognito_*` params take care of changing the ALB Listener to make sure the only authenticated users can visit the content. As cognito can only be applied to the https listener it's important to enable `redirect_http_to_https`.

```json
module "demo_web" {
  ..
  ..
  name = "airship-web"
  ..
  # load_balancing_enabled sets if a load balancer will be attached to the ecs service / target group
  load_balancing_type = "application"
  # The ARN of the ALB, when left-out the service, will not be attached to a load-balance
  load_balancing_properties_lb_arn                = "${module.alb_shared_services_ext.load_balancer_id}"
  
  # https listener ARN
  load_balancing_properties_lb_listener_arn_https = "${element(module.alb_shared_services_ext.https_listener_arns,0)}"
  
  # http listener ARN
  load_balancing_properties_lb_listener_arn       = "${element(module.alb_shared_services_ext.http_tcp_listener_arns,0)}"
  
  # The VPC_ID the target_group is being created in
  load_balancing_properties_lb_vpc_id             = "${module.vpc.vpc_id}"
  
  # The route53 zone for which we create a subdomain
  load_balancing_properties_route53_zone_id       = "${aws_route53_zone.shared_ext_services_domain.zone_id}"

  load_balancing_properties_redirect_http_to_https = true

  # cognito_auth_enabled is set when cognito authentication is used for the https listener
  Important to have redirect_http_to_https set to true as http authentication is only added to the https listener

  load_balancing_properties_cognito_auth_enabled = true

  ## cognito_user_pool_arn defines the cognito user pool arn for the added cognito authentication
  load_balancing_properties_cognito_user_pool_arn = "${aws_cognito_user_pool.main.arn}"

  # cognito_user_pool_client_id defines the cognito_user_pool_client_id
  load_balancing_properties_cognito_user_pool_client_id = "${aws_cognito_user_pool_client.client.id}"

  # cognito_user_pool_domain sets the domain of the cognito_user_pool
  load_balancing_properties_cognito_user_pool_domain = "${aws_cognito_user_pool_domain.pool.id}"
  ..
  ..
```

### Network LB ( NLB )

The Network Load Balancer (NLB) forwards TCP Traffic transparently to the ECS Tasks of an ECS Service. For an existing NLB the ECS Module creates a new NLB-Listener with a new LB Target Group as default. By default the listener port is set to port 80. It's not mandatory to use the NLB togeter with awsvpc network mode.

<div class="mermaid">
graph LR
    subgraph Module Scope
    0
    end
    0[fa:fa-ban DNS Domain ecs_name.zone.tld]-->B[fa:fa-ban NLB]
    B-->C[fa:fa-ban NLB Listener]
    subgraph Module Scope
    C-->D[fa:fa-ban Target Group]
    D-->H[fa:fa-ban ECS Task N]
    D-->I[fa:fa-ban ECS Task N+1]
    subgraph ECS Cluster
    subgraph ECS Service
    H
    I
    end
    end
    H-.->J[fa:fa-ban Task Definition:version]
    I-.->J[fa:fa-ban Task Definition:version]
    end
</div>

```json
module "demo_web" {
    ..
    ..
    awsvpc_enabled = true
    awsvpc_subnets            = ["${module.vpc.private_subnets}"]
    awsvpc_security_group_ids = ["${module.demo_sg.this_security_group_id}"]


    load_balancing_type = "network"
    load_balancing_properties_lb_arn                = "${module.nlb.load_balancer_id}"
    load_balancing_properties_lb_vpc_id             = "${module.vpc.vpc_id}"
    load_balancing_properties_route53_zone_id       = "${aws_route53_zone.shared_ext_services_domain.zone_id}"
    # load_balancing_properties_unhealthy_threshold   = "3"
    # load_balancing_properties_nlb_listener_port sets the port of the lb_listener
    # load_balancing_properties_nlb_listener_port = 80
    ..
    ..
```
