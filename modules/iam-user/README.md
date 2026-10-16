# IAM User Module

OpenTofu module to create a standalone AWS IAM user with inline policies, managed policy attachments, and optional programmatic or console access.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_iam_user` | Yes | IAM user |
| `aws_iam_user_policy` | No | Default inline policy from `policy_statements` |
| `aws_iam_user_policy` | No | Additional named policies from `inline_policies` |
| `aws_iam_user_policy_attachment` | No | One per managed policy attachment |
| `aws_iam_access_key` | No | Created when `create_access_key = true` |
| `aws_iam_user_login_profile` | No | Created when `create_login_profile = true` |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### CI/CD user with customer-managed policy

```hcl
iam_policies = {
  deploy-read = {
    name        = "my-company-deploy-read-prod"
    policy_statements = [{
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::my-company-deploy-artifacts-prod", "arn:aws:s3:::my-company-deploy-artifacts-prod/*"]
    }]
  }
}

iam_users = {
  ci-deploy = {
    name                = "my-company-ci-deploy-prod"
    managed_policy_keys = ["deploy-read"]
    tags                = { Purpose = "ci-deploy" }
  }
}
```

### Programmatic user with access key

```hcl
iam_users = {
  automation = {
    name              = "my-company-automation-prod"
    create_access_key = true
    policy_statements = [{
      effect    = "Allow"
      actions   = ["s3:PutObject", "s3:GetObject"]
      resources = ["arn:aws:s3:::my-company-automation-prod/*"]
    }]
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | IAM user name | `string` | — | yes |
| `path` | IAM path | `string` | `"/"` | no |
| `permissions_boundary` | Permissions boundary ARN | `string` | `null` | no |
| `force_destroy` | Force delete user | `bool` | `false` | no |
| `managed_policy_arns` | Managed policy ARNs | `list(string)` | `[]` | no |
| `managed_policy_key_arns` | Policy ARNs by stable key | `map(string)` | `{}` | no |
| `policy_statements` | Default inline policy | `list(object)` | `[]` | no |
| `inline_policies` | Named inline policies | `map(object)` | `{}` | no |
| `create_access_key` | Create access key | `bool` | `false` | no |
| `access_key_status` | `Active` or `Inactive` | `string` | `"Active"` | no |
| `access_key_pgp_key` | PGP key for secret encryption | `string` | `null` | no |
| `create_login_profile` | Create console login | `bool` | `false` | no |
| `login_profile_password_reset_required` | Force password reset | `bool` | `true` | no |
| `login_profile_password_length` | Generated password length | `number` | `20` | no |
| `login_profile_pgp_key` | PGP key for password encryption | `string` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `user_name` | IAM user name |
| `user_arn` | IAM user ARN |
| `user_unique_id` | Stable unique ID |
| `managed_policy_arns` | Attached managed policy ARNs |
| `inline_policy_names` | Inline policy names |
| `access_key_id` | Access key ID when created |
| `secret_access_key` | Access key secret (sensitive) |
| `encrypted_secret_access_key` | PGP-encrypted secret (sensitive) |
| `login_profile_encrypted_password` | PGP-encrypted console password (sensitive) |

## Validation

The module enforces:

- IAM `path` format and user name length (64)
- Valid IAM policy ARN format for `managed_policy_arns` and `permissions_boundary`
- Policy statement `effect`, `actions`/`not_actions`, and `resources`/`not_resources`
- No `inline_policies` key collision with the default policy name
- Console password / PGP key exclusivity
- Login profile password length (14–128)

## Environment wiring

In `environments/prod`, configure the `iam_users` map. Attach customer-managed policies with `managed_policy_keys` (resolved automatically) or `managed_policy_arns` for AWS-managed policies.

## Security notes

- Prefer IAM roles (including OIDC/IRSA) over long-lived IAM users where possible.
- `create_access_key` defaults to `false`.
- Store `secret_access_key` in Secrets Manager; never commit credentials to git.
- Use `permissions_boundary` for operator/break-glass users.

## Related modules

- [iam-policy](../iam-policy/) — Reusable customer-managed policies
- [iam-role](../iam-role/) — Preferred alternative for workloads and federation
- [secrets-manager](../secrets-manager/) — Store generated credentials securely
