# ECR Module

OpenTofu module to create an AWS Elastic Container Registry (ECR) repository with encryption, image scanning, lifecycle policies, and optional repository policies.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_ecr_repository` | Yes | Container image repository |
| `aws_ecr_lifecycle_policy` | No | Created when lifecycle policy is configured |
| `aws_ecr_repository_policy` | No | Created when repository policy is configured |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Application repository with lifecycle cleanup

```hcl
ecr_repositories = {
  app = {
    name                 = "my-company-app-prod"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true

    lifecycle_rules = [
      {
        rule_priority = 1
        description   = "Keep last 30 images"
        tag_status    = "any"
        count_type    = "imageCountMoreThan"
        count_number  = 30
      }
    ]

    tags = { Purpose = "application-images" }
  }
}
```

### KMS-encrypted repository

```hcl
kms_keys = {
  app-encryption = {
    description         = "Application encryption key"
    enable_key_rotation = true
    policy_statements = [{
      sid    = "AllowECRService"
      effect = "Allow"
      actions = [
        "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
        "kms:GenerateDataKey*", "kms:CreateGrant", "kms:DescribeKey",
      ]
      resources = ["*"]
      principals = {
        type        = "Service"
        identifiers = ["ecr.amazonaws.com"]
      }
    }]
  }
}

ecr_repositories = {
  secure-app = {
    name            = "my-company-secure-app-prod"
    encryption_type = "KMS"
    kms_key_key     = "app-encryption"
    scan_on_push    = true
  }
}
```

### Cross-account pull access

```hcl
ecr_repositories = {
  shared-app = {
    name = "my-company-shared-app-prod"

    policy_statements = [
      {
        sid    = "AllowCrossAccountPull"
        effect = "Allow"
        actions = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
        ]
        principals = {
          type        = "AWS"
          identifiers = ["arn:aws:iam::123456789012:root"]
        }
      }
    ]
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Repository name | `string` | — | yes |
| `image_tag_mutability` | `MUTABLE` or `IMMUTABLE` | `string` | `"MUTABLE"` | no |
| `force_delete` | Delete repo with images | `bool` | `false` | no |
| `encryption_type` | `AES256` or `KMS` | `string` | `"AES256"` | no |
| `kms_key_id` | KMS key for encryption | `string` | `null` | no |
| `scan_on_push` | Scan images on push | `bool` | `true` | no |
| `policy_json` | Full repository policy JSON | `string` | `null` | no |
| `policy_statements` | Structured repository policy | `list(object)` | `[]` | no |
| `lifecycle_policy_json` | Full lifecycle policy JSON | `string` | `null` | no |
| `lifecycle_rules` | Structured lifecycle rules | `list(object)` | `[]` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `repository_name` | Repository name |
| `repository_arn` | Repository ARN |
| `repository_url` | Docker push/pull URL |
| `registry_id` | AWS account ID |
| `image_tag_mutability` | Tag mutability setting |
| `scan_on_push` | Scan-on-push enabled |
| `encryption_type` | Encryption type |

## Validation

The module includes check blocks for:

- KMS key required/exclusive when using KMS encryption
- Exclusive `policy_json` / `policy_statements`
- Exclusive `lifecycle_policy_json` / `lifecycle_rules`
- Policy statement effects and principal types
- Lifecycle rule priorities, tag status, count types, and count units

## Environment wiring

In `environments/prod`, configure the `ecr_repositories` map. Use `kms_key_key` to reference keys from the `kms_keys` map.

## Related modules

- [kms](../kms/) — KMS keys for repository encryption
- [eks](../eks/) — Kubernetes clusters that pull images from ECR
- [iam-role](../iam-role/) — IAM roles for CI/CD push/pull permissions
- [codebuild](../codebuild/) — Build pipelines that push images to ECR
