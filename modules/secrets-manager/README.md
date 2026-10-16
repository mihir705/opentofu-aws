# Secrets Manager Module

OpenTofu module to create and manage a single AWS Secrets Manager secret with optional initial value, generated passwords, KMS encryption, rotation, resource policy, and multi-region replicas.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_secretsmanager_secret` | Yes | Core secret |
| `random_password` | No | Created when `generate_random_password` is set |
| `aws_secretsmanager_secret_version` | No | Created when a secret value source is configured |
| `aws_secretsmanager_secret_rotation` | No | Created when `rotation` is set |
| `aws_secretsmanager_secret_policy` | No | Created when `resource_policy_json` is set |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |
| [Random Provider](https://registry.opentofu.org/hashicorp/random/latest) | >= 3.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Empty secret (value set outside Terraform)

Use this when the secret shell is created by Terraform but the value is injected by CI/CD or the AWS Console.

```hcl
module "app_config" {
  source = "./modules/secrets-manager"

  name        = "my-company/app/config/dev"
  description = "Application configuration secret"

  tags = {
    Environment = "dev"
    Purpose     = "app-config"
  }
}
```

### Secret with initial string value

```hcl
module "database_credentials" {
  source = "./modules/secrets-manager"

  name        = "my-company/database/credentials/dev"
  description = "Database username and password"

  secret_string = jsonencode({
    username = "db_user"
    password = "CHANGE_ME"
  })

  tags = {
    Environment = "dev"
    Purpose     = "database-credentials"
  }
}
```

### Generated random password

Use for database credentials and other secrets where Terraform should generate a strong password. Set `username` to store JSON with both username and password.

```hcl
module "database_credentials" {
  source = "./modules/secrets-manager"

  name_prefix = "my-company/database/credentials/dev-"
  description = "Database credentials with generated password"

  generate_random_password = {
    length   = 32
    username = "db_admin"
  }

  ignore_secret_changes = true

  tags = {
    Purpose = "database-credentials"
  }
}
```

### Name prefix

Use when AWS should append a random suffix to avoid name collisions.

```hcl
module "dynamic_secret" {
  source = "./modules/secrets-manager"

  name_prefix = "my-company/runtime/secret-"
  description = "Secret with AWS-generated suffix"
}
```

### Ignore value changes after creation

Use when the secret value is rotated or updated outside Terraform.

```hcl
module "database_credentials" {
  source = "./modules/secrets-manager"

  name        = "my-company/database/credentials/dev"
  description = "Database credentials managed outside Terraform after initial create"

  secret_string         = jsonencode({ username = "db_user", password = "CHANGE_ME" })
  ignore_secret_changes = true

  tags = {
    Purpose = "database-credentials"
  }
}
```

### Customer-managed KMS encryption

```hcl
module "api_key" {
  source = "./modules/secrets-manager"

  name        = "my-company/api/key/dev"
  description = "Third-party API key"
  kms_key_id  = "arn:aws:kms:ap-south-1:123456789012:key/abcd1234-5678-90ab-cdef-1234567890ab"
  secret_string = "REPLACE_WITH_REAL_API_KEY"

  tags = {
    Purpose = "api-key"
  }
}
```

### Automatic rotation

The rotation Lambda must exist and be permitted to rotate this secret. A secret version must exist before rotation is enabled.

```hcl
module "rotated_database" {
  source = "./modules/secrets-manager"

  name        = "my-company/database/rotated/dev"
  description = "Database credentials with automatic rotation"

  secret_string = jsonencode({
    username = "db_user"
    password = "CHANGE_ME"
  })

  rotation = {
    lambda_arn               = "arn:aws:lambda:ap-south-1:123456789012:function:rotate-db-secret"
    automatically_after_days = 30
  }

  tags = {
    Purpose = "database-rotation"
  }
}
```

### Resource policy

```hcl
module "shared_secret" {
  source = "./modules/secrets-manager"

  name        = "my-company/shared/secret/dev"
  description = "Secret shared with a specific IAM role"

  resource_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadForAppRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/my-app-role"
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      }
    ]
  })

  tags = {
    Purpose = "shared-secret"
  }
}
```

### Multi-region replicas

```hcl
module "global_secret" {
  source = "./modules/secrets-manager"

  name        = "my-company/global/secret/dev"
  description = "Secret replicated to another region"

  replica_regions = [
    {
      region = "us-east-1"
    }
  ]

  tags = {
    Purpose = "global-secret"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Fixed name of the secret | `string` | `null` | no |
| `name_prefix` | Name prefix with AWS-generated suffix | `string` | `null` | no |
| `description` | Description of the secret | `string` | `null` | no |
| `kms_key_id` | KMS key ID or ARN for encryption | `string` | `null` | no |
| `recovery_window_in_days` | Deletion recovery window (`0` or `7-30`) | `number` | `30` | no |
| `secret_string` | Secret value as UTF-8 text | `string` | `null` | no |
| `secret_binary` | Secret value as base64-encoded binary | `string` | `null` | no |
| `generate_random_password` | Generate and store a random password | `object` | `null` | no |
| `ignore_secret_changes` | Ignore secret value changes after create | `bool` | `false` | no |
| `rotation` | Automatic rotation configuration | `object` | `null` | no |
| `resource_policy_json` | JSON resource policy document | `string` | `null` | no |
| `replica_regions` | Read replica regions | `list(object)` | `[]` | no |
| `tags` | Tags applied to the secret | `map(string)` | `{}` | no |

Exactly one of `name` or `name_prefix` is required.

### `generate_random_password` object

```hcl
generate_random_password = {
  length           = optional(number, 32)
  special          = optional(bool, true)
  override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
  username         = optional(string, null)
}
```

When `username` is set, the secret value is stored as JSON:

```json
{"username":"db_admin","password":"<generated>"}
```

### `rotation` object

```hcl
rotation = {
  lambda_arn               = string
  automatically_after_days = optional(number, 30)
}
```

### `replica_regions` object

```hcl
replica_regions = [
  {
    region     = string
    kms_key_id = optional(string)
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| `secret_id` | ID of the secret |
| `secret_arn` | ARN of the secret |
| `secret_name` | Name of the secret |
| `secret_version_id` | Version ID when Terraform manages the secret value |
| `rotation_enabled` | Whether automatic rotation is enabled |
| `random_password_generated` | Whether the secret value was generated by Terraform |
| `kms_key_id` | KMS key ID used to encrypt the secret |

Secret values are never exported as outputs.

## Security defaults and recommendations

- Secret values are marked `sensitive` in Terraform
- Recovery window defaults to `30` days
- Do not commit real secret values to git
- Prefer `ignore_secret_changes = true` when values are rotated outside Terraform
- Use a customer-managed KMS key for production workloads when required by policy

### Safer ways to supply secret values

| Approach | Example |
|----------|---------|
| Environment variable | `TF_VAR_secrets='{"db":{"name":"...","secret_string":"..."}}'` |
| CI/CD secret store | Inject at pipeline runtime |
| Empty secret shell | Create secret in Terraform, set value in AWS Console |

## Validation rules

- Exactly one of `name` or `name_prefix` must be set
- `recovery_window_in_days` must be `0` or between `7` and `30`
- Only one of `secret_string`, `secret_binary`, or `generate_random_password` may be set
- `rotation` requires a secret value from `secret_string`, `secret_binary`, or `generate_random_password`

## Resource ordering

1. Secret
2. Secret version (when a value is provided)
3. Rotation (depends on secret version)
4. Resource policy

## Example output usage

```hcl
module "database_credentials" {
  source = "./modules/secrets-manager"

  name = "my-company/database/credentials/dev"
}

resource "aws_iam_policy" "read_database_secret" {
  name = "read-database-secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = module.database_credentials.secret_arn
      }
    ]
  })
}
```

## What this module does not manage

The following are intentionally out of scope:

- Rotation Lambda function creation
- KMS key creation
- Secret replication from an existing primary in another account
