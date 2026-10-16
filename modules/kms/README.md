# KMS Module

OpenTofu module to create and manage a customer-managed AWS KMS key with secure defaults, service principal helpers, structured policy statements, optional aliases, and multi-Region replica support.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_kms_key` | Yes | Customer-managed KMS key |
| `aws_kms_replica_key` | No | Created when `multi_region = true` and `replica_region` is set |
| `aws_kms_alias` | No | One per entry in `aliases` |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

When using `replica_region`, the root module must pass an `aws.replica` provider configured for the replica region.

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Basic key with service access for S3 and Secrets Manager

```hcl
module "app_encryption" {
  source = "./modules/kms"

  description         = "Application data encryption key"
  enable_key_rotation = true
  allowed_services    = ["s3", "secretsmanager"]
  aliases             = ["my-company/app/prod"]

  tags = {
    Environment = "prod"
    Purpose     = "app-encryption"
  }
}
```

### Structured policy statements

Merged with the default account-root policy. Cannot be combined with `key_policy_json`.

```hcl
module "team_key" {
  source = "./modules/kms"

  description = "KMS key with role-based access"
  aliases     = ["my-company/team/prod"]

  policy_statements = [
    {
      sid    = "AllowAppRole"
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
      ]
      principals = {
        type        = "AWS"
        identifiers = ["arn:aws:iam::123456789012:role/my-app-role"]
      }
    }
  ]
}
```

### Multi-Region key with replica

```hcl
provider "aws" {
  alias  = "replica"
  region = "us-east-1"
}

module "global_encryption" {
  source = "./modules/kms"

  providers = {
    aws.replica = aws.replica
  }

  description         = "Multi-Region encryption key"
  multi_region        = true
  replica_region      = "us-east-1"
  enable_key_rotation = true
  allowed_services    = ["secretsmanager"]
  aliases             = ["my-company/global/prod"]
}
```

### Full custom policy JSON

Replaces the built-in policy builder entirely.

```hcl
module "restricted_key" {
  source = "./modules/kms"

  description = "KMS key with custom policy"
  aliases     = ["my-company/restricted/prod"]

  key_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `description` | Description of the KMS key | `string` | `null` | no |
| `deletion_window_in_days` | Deletion waiting period (`7-30`) | `number` | `30` | no |
| `enable_key_rotation` | Enable automatic annual rotation | `bool` | `true` | no |
| `multi_region` | Create a multi-Region primary key | `bool` | `false` | no |
| `replica_region` | Region for the KMS replica key | `string` | `null` | no |
| `key_policy_json` | Full custom key policy JSON | `string` | `null` | no |
| `allowed_services` | Services to grant standard KMS usage (`s3`, `secretsmanager`) | `list(string)` | `[]` | no |
| `policy_statements` | Additional structured policy statements | `list(object)` | `[]` | no |
| `aliases` | Key aliases without the `alias/` prefix | `list(string)` | `[]` | no |
| `tags` | Tags applied to the KMS key | `map(string)` | `{}` | no |

### `policy_statements` object

```hcl
policy_statements = [
  {
    sid       = optional(string)
    effect    = string
    actions   = list(string)
    resources = optional(list(string), ["*"])
    principals = {
      type        = string
      identifiers = list(string)
    }
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| `key_id` | ID of the KMS key |
| `key_arn` | ARN of the KMS key |
| `key_rotation_enabled` | Whether automatic rotation is enabled |
| `replica_key_arn` | ARN of the replica key |
| `replica_key_id` | ID of the replica key |
| `alias_names` | Map of input alias names to full alias names |
| `alias_arns` | Map of input alias names to alias ARNs |

## Security defaults

- Automatic key rotation enabled by default
- Deletion window defaults to `30` days
- Default key policy grants full KMS access to the account root
- `allowed_services` adds least-privilege service principal statements for S3 and Secrets Manager
- `key_policy_json` is exclusive when you need full manual control

## Validation rules

- `deletion_window_in_days` must be between `7` and `30`
- `replica_region` requires `multi_region = true`
- `key_policy_json` cannot be combined with `policy_statements` or `allowed_services`
- `allowed_services` only supports `s3` and `secretsmanager`

## What this module does not manage

- Multiple replica regions in a single module call (one replica per key)
- KMS grants
- Custom key stores (CloudHSM / External)
