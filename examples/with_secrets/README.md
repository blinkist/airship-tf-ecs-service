# with_secrets

This is an example of creating a service that places SSM secrets in the task environment variables.

Variables declared in `container_secrets` can come in two formats:

* `DB_USER = "arn:aws:ssm:${local.region}:${local.remote_account_id}:parameter/myapp/dev/db.user"`:
   This is useful for cross account access, where the SSM registry is in another account.
* `DB_PASSWORD = "/myapp/dev/db.password"`: This is useful for referring to SSM variables in the same account
