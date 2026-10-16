# S3 Module

OpenTofu module to create and manage a single AWS S3 bucket with secure defaults, optional lifecycle rules, CORS, bucket policy, and server access logging.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_s3_bucket` | Yes | Core bucket |
| `aws_s3_bucket_public_access_block` | Yes | Blocks public access by default |
| `aws_s3_bucket_ownership_controls` | Yes | `BucketOwnerEnforced` by default |
| `aws_s3_bucket_versioning` | No | Controlled by `versioning_enabled` |
| `aws_s3_bucket_server_side_encryption_configuration` | Yes | SSE-S3 or SSE-KMS |
| `aws_s3_bucket_logging` | No | Created when `access_logging` is set |
| `aws_s3_bucket_lifecycle_configuration` | No | Created when `lifecycle_rules` is non-empty |
| `aws_s3_bucket_policy` | No | Created when `bucket_policy_json` is set |
| `aws_s3_bucket_cors_configuration` | No | Created when `cors_rules` is non-empty |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Basic bucket

```hcl
module "app_data" {
  source = "./modules/s3"

  bucket_name        = "my-company-app-data-dev"
  versioning_enabled = true

  tags = {
    Environment = "dev"
    Purpose     = "application-data"
  }
}
```

### SSE-KMS encryption

```hcl
module "secure_data" {
  source = "./modules/s3"

  bucket_name        = "my-company-secure-data-prod"
  versioning_enabled = true
  sse_algorithm      = "aws:kms"
  kms_key_arn        = "arn:aws:kms:ap-south-1:123456789012:key/abcd1234-5678-90ab-cdef-1234567890ab"

  tags = {
    Environment = "prod"
  }
}
```

### Server access logging

The target logging bucket must already exist. AWS also requires the target bucket to grant write access to the S3 logging service principal.

```hcl
module "app_data" {
  source = "./modules/s3"

  bucket_name        = "my-company-app-data-dev"
  versioning_enabled = true

  access_logging = {
    target_bucket = "my-company-access-logs-dev"
    target_prefix = "app-data/"
  }

  tags = {
    Environment = "dev"
  }
}
```

### Lifecycle rules

Omit `filter` to apply a rule to the entire bucket. Use `filter.prefix` or `filter.tags` to scope a rule.

```hcl
module "logs" {
  source = "./modules/s3"

  bucket_name        = "my-company-logs-dev"
  versioning_enabled = true

  lifecycle_rules = [
    {
      id      = "expire-old-logs"
      enabled = true
      expiration = {
        days = 90
      }
    },
    {
      id      = "transition-to-ia"
      enabled = true
      filter = {
        prefix = "archive/"
      }
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
    },
    {
      id      = "cleanup-old-versions"
      enabled = true
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]

  tags = {
    Purpose = "logs"
  }
}
```

### CORS

```hcl
module "frontend_assets" {
  source = "./modules/s3"

  bucket_name = "my-company-frontend-assets-dev"

  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://app.example.com"]
      allowed_headers = ["*"]
      max_age_seconds = 3600
    }
  ]

  tags = {
    Purpose = "frontend-assets"
  }
}
```

### Bucket policy

Pass a full JSON policy document. The module applies the policy only after public access block and ownership controls are in place.

```hcl
module "restricted_bucket" {
  source = "./modules/s3"

  bucket_name = "my-company-restricted-data-prod"

  bucket_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::my-company-restricted-data-prod",
          "arn:aws:s3:::my-company-restricted-data-prod/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bucket_name` | Globally unique S3 bucket name | `string` | n/a | yes |
| `force_destroy` | Allow bucket deletion even when it contains objects | `bool` | `false` | no |
| `versioning_enabled` | Enable S3 bucket versioning | `bool` | `false` | no |
| `sse_algorithm` | Server-side encryption algorithm (`AES256` or `aws:kms`) | `string` | `"AES256"` | no |
| `kms_key_arn` | KMS key ARN when `sse_algorithm` is `aws:kms` | `string` | `null` | no |
| `bucket_key_enabled` | Enable S3 Bucket Keys for SSE-KMS | `bool` | `true` | no |
| `object_ownership` | Object ownership setting | `string` | `"BucketOwnerEnforced"` | no |
| `block_public_acls` | Block public ACLs on the bucket | `bool` | `true` | no |
| `block_public_policy` | Block public bucket policies | `bool` | `true` | no |
| `ignore_public_acls` | Ignore public ACLs on the bucket | `bool` | `true` | no |
| `restrict_public_buckets` | Restrict public bucket policies | `bool` | `true` | no |
| `access_logging` | Server access logging target. Set to `null` to disable | `object` | `null` | no |
| `lifecycle_rules` | Lifecycle rules applied to the bucket | `list(object)` | `[]` | no |
| `bucket_policy_json` | Optional JSON bucket policy document | `string` | `null` | no |
| `cors_rules` | CORS rules applied to the bucket | `list(object)` | `[]` | no |
| `tags` | Tags applied to the bucket | `map(string)` | `{}` | no |

### `access_logging` object

```hcl
access_logging = {
  target_bucket = string
  target_prefix = optional(string, "")
}
```

### `lifecycle_rules` object

```hcl
lifecycle_rules = [
  {
    id      = string
    enabled = optional(bool, true)
    filter = optional(object({
      prefix                   = optional(string)
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      tags                     = optional(map(string), {})
    }))
    expiration = optional(object({
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }))
  }
]
```

Supported `storage_class` values include `STANDARD_IA`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER`, `DEEP_ARCHIVE`, and `GLACIER_IR`.

### `cors_rules` object

```hcl
cors_rules = [
  {
    allowed_methods = list(string)
    allowed_origins = list(string)
    allowed_headers = optional(list(string))
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | Name (ID) of the bucket |
| `bucket_arn` | ARN of the bucket |
| `bucket_domain_name` | Bucket domain name |
| `bucket_regional_domain_name` | Bucket region-specific domain name |
| `bucket_region` | AWS region of the bucket |
| `access_logging_enabled` | Whether server access logging is enabled |
| `access_logging_target_bucket` | Target bucket for server access logs |

## Security defaults

This module applies secure defaults suitable for private application buckets:

- Public access blocked on all four settings
- `BucketOwnerEnforced` ownership controls
- Encryption enabled by default with SSE-S3 (`AES256`)
- `force_destroy` disabled by default

If you intentionally need a public bucket, override the public access settings and provide an explicit bucket policy. That should be a deliberate choice, not the default.

## Validation rules

- `sse_algorithm` must be `AES256` or `aws:kms`
- `kms_key_arn` is required when `sse_algorithm = "aws:kms"`
- `object_ownership` must be one of:
  - `BucketOwnerEnforced`
  - `BucketOwnerPreferred`
  - `ObjectWriter`

## Resource ordering

The module applies resources in an order that avoids common S3 API errors:

1. Bucket
2. Public access block
3. Ownership controls
4. Versioning, encryption, logging, lifecycle, and CORS
5. Bucket policy after public access block and ownership controls

## IAM notes for access logging

When enabling `access_logging`, ensure:

1. The target bucket exists before apply
2. The target bucket policy allows the logging service principal to write logs
3. The Terraform execution role can configure logging on the source bucket

## Example output usage

```hcl
module "app_data" {
  source = "./modules/s3"

  bucket_name = "my-company-app-data-dev"
}

resource "aws_iam_policy" "app_read" {
  name = "app-data-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          module.app_data.bucket_arn,
          "${module.app_data.bucket_arn}/*"
        ]
      }
    ]
  })
}
```

## What this module does not manage

The following are intentionally out of scope and can be added later if needed:

- Cross-region or same-region replication
- S3 event notifications
- Object Lock / compliance retention
- Static website hosting
- Transfer acceleration
- Inventory and analytics configurations
