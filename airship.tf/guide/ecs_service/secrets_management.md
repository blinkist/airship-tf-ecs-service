---
sidebarDepth: 2
---

# Secrets Management

## Chamber

The built in access to KMS and SSM make it possible to store application variables inside SSM. KMS is used to encrypt or decrypt the variables stored inside SSM.

[Chamber](https://github.com/segmentio/chamber/) can be used inside Docker to retrieve the values from SSM and expose them as ENV vars to the application

A modified CMD inside a Dockerfile which would normally runs `application_run.sh` will now first run chamber. And Chamber will exec `application_run.sh` and replace it's own PID doing so.

```docker
FROM example
..
..
CMD exec chamber exec application/servicename -- application_run.sh
```


## Creating secrets for chamber

Outside of the ECS Module you can create the secrets stored inside SSM.

```json
resource "aws_ssm_parameter" "environment" {
  name   = "/application/servicename/environment"
  type   = "SecureString"
  key_id = "ARN of the KMS"
  value  = "production"
}
```
