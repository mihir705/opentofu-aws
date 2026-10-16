# IAM Role Module

OpenTofu module to create a standalone AWS IAM role with trust policy, inline policies, managed policy attachments, and optional EC2 instance profile.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_iam_role` | Yes | IAM role with trust policy |
| `aws_iam_role_policy` | No | Default inline policy from `policy_statements` |
| `aws_iam_role_policy` | No | Additional named policies from `inline_policies` |
| `aws_iam_role_policy_attachment` | No | One per `managed_policy_arns` entry |
| `aws_iam_instance_profile` | No | Created when `create_instance_profile = true` |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Lambda execution role

```hcl
iam_roles = {
  lambda-exec = {
    name           = "my-company-lambda-exec-prod"
    description    = "Lambda execution role for API handlers"
    trust_services = ["lambda.amazonaws.com"]

    managed_policy_arns = [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    ]

    tags = {
      Purpose = "lambda-execution"
    }
  }
}
```

### EC2 role with instance profile and conditional S3 access

```hcl
iam_roles = {
  app-ec2 = {
    name                    = "my-company-app-ec2-prod"
    trust_services          = ["ec2.amazonaws.com"]
    create_instance_profile = true

    policy_statements = [
      {
        sid    = "S3AppDataRead"
        effect = "Allow"
        actions = ["s3:GetObject", "s3:ListBucket"]
        resources = [
          "arn:aws:s3:::my-company-app-data-prod",
          "arn:aws:s3:::my-company-app-data-prod/*",
        ]
        conditions = [
          {
            test     = "StringLike"
            variable = "s3:prefix"
            values   = ["app/*"]
          }
        ]
      }
    ]

    tags = { Purpose = "app-ec2" }
  }
}
```

### GitHub Actions OIDC role

```hcl
iam_roles = {
  github-deploy = {
    name = "my-company-github-deploy-prod"

    trust_principals = [
      {
        type        = "Federated"
        identifiers = ["arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"]
        conditions = [
          {
            test     = "StringEquals"
            variable = "token.actions.githubusercontent.com:aud"
            values   = ["sts.amazonaws.com"]
          },
          {
            test     = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values   = ["repo:my-org/my-repo:*"]
          }
        ]
      }
    ]

    assume_role_actions = ["sts:AssumeRoleWithWebIdentity"]

    policy_statements = [
      {
        effect    = "Allow"
        actions   = ["s3:PutObject", "s3:GetObject"]
        resources = ["arn:aws:s3:::my-company-deploy-artifacts-prod/*"]
      }
    ]

    tags = { Purpose = "github-oidc-deploy" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Role name (max 64 chars) | `string` | — | yes |
| `description` | Role description | `string` | `null` | no |
| `path` | IAM path (must start/end with `/`) | `string` | `"/"` | no |
| `max_session_duration` | Max session duration in seconds (3600–43200) | `number` | `3600` | no |
| `permissions_boundary` | Customer-managed policy ARN for permissions boundary | `string` | `null` | no |
| `force_detach_policies` | Detach managed policies before role delete | `bool` | `false` | no |
| `assume_role_policy_json` | Full trust policy JSON | `string` | `null` | no* |
| `trust_services` | AWS service principals for trust policy | `list(string)` | `[]` | no* |
| `trust_principals` | Custom trust principals (`AWS`, `Service`, `Federated`, `CanonicalUser`) | `list(object)` | `[]` | no* |
| `assume_role_actions` | STS actions in trust policy | `list(string)` | `["sts:AssumeRole"]` | no |
| `assume_role_conditions` | Conditions on the `trust_services` statement only | `list(object)` | `[]` | no |
| `managed_policy_arns` | Managed policy ARNs to attach | `list(string)` | `[]` | no |
| `policy_statements` | Default inline policy statements | `list(object)` | `[]` | no |
| `inline_policies` | Named additional inline policies | `map(object)` | `{}` | no |
| `create_instance_profile` | Create EC2 instance profile | `bool` | `false` | no |
| `instance_profile_name` | Instance profile name (defaults to role name) | `string` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Requires `assume_role_policy_json` or at least one `trust_services` / `trust_principals` entry. When `assume_role_policy_json` is set, omit the other trust inputs.

### Policy statement object

Each entry in `policy_statements` or `inline_policies.*.policy_statements` supports:

| Field | Required | Notes |
|-------|----------|-------|
| `effect` | yes | `Allow` or `Deny` |
| `actions` | no* | IAM actions |
| `not_actions` | no* | Inverse action list |
| `resources` | no* | Defaults to `["*"]` |
| `not_resources` | no* | Inverse resource list |
| `conditions` | no | IAM condition blocks |
| `sid` | no | Statement ID |

\* Each statement must define `actions` or `not_actions`, and `resources` or `not_resources`.

## Outputs

| Name | Description |
|------|-------------|
| `role_name` | IAM role name |
| `role_arn` | IAM role ARN |
| `role_id` | IAM role ID |
| `role_unique_id` | Stable unique ID for the role |
| `instance_profile_name` | Instance profile name when created |
| `instance_profile_arn` | Instance profile ARN when created |
| `managed_policy_arns` | Managed policy ARNs attached to the role |
| `inline_policy_names` | Inline policy names attached to the role |

## Validation

The module enforces:

- Trust policy source is **either** `assume_role_policy_json` **or** `trust_services` / `trust_principals` (not both)
- At least one trust principal when not using raw JSON
- IAM `path` format, role name length (64), instance profile name length (128)
- Valid IAM policy ARN format for `managed_policy_arns` and `permissions_boundary`
- Policy statement `effect`, `actions`/`not_actions`, and `resources`/`not_resources` requirements
- No `inline_policies` key collision with the default policy name (`<role-name>-policy`)
- Supported `trust_principals.type` values

## Notes

- In `environments/prod`, attach customer-managed policies created by the [iam-policy](../iam-policy/) module using `managed_policy_keys` on the `iam_roles` entry (resolved to ARNs automatically). Use `managed_policy_arns` for AWS-managed policies.
- Use `assume_role_policy_json` for complex trust policies (multi-statement SAML, custom federation).
- `assume_role_conditions` applies only to the **service principals** statement; use per-principal `conditions` on `trust_principals` for AWS/Federated trust.
- For OIDC (EKS IRSA, GitHub Actions), set `assume_role_actions = ["sts:AssumeRoleWithWebIdentity"]` and use a `Federated` principal.
- Service-specific modules (Lambda, CodeBuild, CodePipeline) create their own roles; use this module for standalone or shared roles.
- IAM role names are limited to **64 characters**; inline policy names to **128 characters**.
