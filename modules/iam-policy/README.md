# IAM Policy Module

OpenTofu module to create standalone AWS IAM customer-managed policies from structured statements or raw JSON.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_iam_policy` | Yes | Customer-managed IAM policy |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### S3 read policy attached to an IAM role

```hcl
iam_policies = {
  app-s3-read = {
    name        = "my-company-app-s3-read-prod"
    description = "Read-only access to application data bucket"

    policy_statements = [
      {
        sid    = "S3AppDataRead"
        effect = "Allow"
        actions = ["s3:GetObject", "s3:ListBucket"]
        resources = [
          "arn:aws:s3:::my-company-app-data-prod",
          "arn:aws:s3:::my-company-app-data-prod/*",
        ]
      }
    ]

    tags = { Purpose = "app-s3-read" }
  }
}

iam_roles = {
  app-ec2 = {
    name                    = "my-company-app-ec2-prod"
    trust_services          = ["ec2.amazonaws.com"]
    create_instance_profile = true
    managed_policy_keys     = ["app-s3-read"]
    tags                    = { Purpose = "app-ec2" }
  }
}
```

### Custom policy JSON

```hcl
iam_policies = {
  custom-deploy = {
    name_prefix = "my-company-deploy"
    description = "Custom deployment policy"

    policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "ECRPull"
          Effect   = "Allow"
          Action   = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
          Resource = "*"
        }
      ]
    })

    tags = { Purpose = "deploy" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | IAM policy name | `string` | `null` | no |
| `name_prefix` | Unique name prefix | `string` | `null` | no |
| `description` | Policy description | `string` | `null` | no |
| `path` | IAM path | `string` | `"/"` | no |
| `policy_json` | Full policy JSON | `string` | `null` | no |
| `policy_statements` | Structured policy statements | `list(object)` | `[]` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

Exactly one of `name` or `name_prefix` is required. Provide either `policy_json` or `policy_statements`.

## Outputs

| Name | Description |
|------|-------------|
| `policy_id` | IAM policy ID |
| `policy_arn` | IAM policy ARN |
| `policy_name` | IAM policy name |
| `policy_document` | Policy JSON document |

## Validation

The module includes check blocks for:

- Exclusive `name` / `name_prefix`
- Exclusive `policy_json` / `policy_statements`
- Required policy content
- Statement `effect`, `actions`/`not_actions`, and `resources`/`not_resources`

## Environment wiring

In `environments/prod`, configure the `iam_policies` map. IAM roles can reference policies with `managed_policy_keys` (resolved to ARNs automatically) alongside `managed_policy_arns` for AWS-managed policies.

## Related modules

- [iam-role](../iam-role/) — IAM roles with trust policies and policy attachments
- [lambda](../lambda/) — Lambda functions that use execution roles
- [ec2](../ec2/) — EC2 instances with instance profiles
