---
sidebarDepth: 2
---

# Task IAM Role

Task IAM Roles are a mechanism similar to EC2 Instance profiles. All available AWS SDK's can authenticate to AWS through the Task IAM Role without `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. The policies attached to the Task IAM Role define which AWS services are accessible. For more information visit the [Developer Guide on Task IAM Roles](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)

## Built-in policies
This ECS Module takes care of creating an IAM role for the task and will also attach certain policies in case they are configured.

### KMS
[KMS](https://aws.amazon.com/kms/) (Key Management Service) is AWS' offering for envelope encryptiong next to the expensive CloudHSM. The module has as a list as input `kms_keys` which should be filled with the ARNs of KMS keys which the ECS Service then has allows kms:Decrypt on.

```json
    kms_keys  = ["${module.global-kms.aws_kms_key_arn}", "${module.demo-kms.aws_kms_key_arn}"]
    # We can disable the policy creation by setting kms_enabled to true
    # kms_enabled = false
```

### SSM
The module has a list `ssm_paths` as input which the policy will interpolate as `parameter/application/%s/`. Applications can use the SSM Parameter Store to securely retrieve configuration parameters by ssm:GetParameter and ssm:GetParametersByPath on the paths provided. From Terraform

```json
    # The SSM paths for which the service will be allowed to ssm:GetParameter and ssm:GetParametersByPath on
    # ssm_paths = ["shared_domain","application_specific_name"]
    ssm_paths = ["${module.global_kms.name}", "${module.demo_kms.name}"]
    # We can disable the policy creation by setting ssm_enabled to true
    # ssm_enabled = false
  }
```

### S3

As it's very common that Applications have access to S3 for reading or writing access. The module has built-in policies for access to s3 buckets. A list of bucket names given as input to `s3_ro_paths` will automatically give Read-Only access to these buckets. In similar fashion `s3_rw_paths` can be used to give full access to a bucket.
```json
  # s3_ro_paths define which paths on S3 can be accessed from the ecs service in read-only fashion.
  s3_ro_paths = []

  # s3_ro_paths define which paths on S3 can be accessed from the ecs service in read-write fashion.
  s3_rw_paths = []
```

## Add policies
The module outputs the name and the arn of the IAM role. This way it is possible to add new policies to the IAM Role outside of the ECS Module.

```json
module "ecs_service_demo" {
  ..
  ..
}

resource "aws_iam_role_policy" "jobsystem_kinesis_events_stream_policy" {
    name   = "Add access to Kinesis"
    role   = "${module.ecs_service_demo.ecs_taskrole_name}"
    policy = "${data.aws_iam_policy_document.jobsystem_kinesis_events_stream_policy.json}"
}

```
