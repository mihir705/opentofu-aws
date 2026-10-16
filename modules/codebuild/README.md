# CodeBuild Module

OpenTofu module to create an AWS CodeBuild project with IAM service role, CloudWatch logs, optional VPC access, webhooks, and artifact/cache configuration.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_codebuild_project` | Yes | CodeBuild project |
| `aws_iam_role` | No | Created when `create_service_role = true` |
| `aws_iam_role_policy` | No | Baseline logs, S3, and VPC permissions |
| `aws_iam_role_policy_attachment` | No | Optional managed policies |
| `aws_cloudwatch_log_group` | No | Created when `create_log_group = true` |
| `aws_codebuild_webhook` | No | Created when `webhook` is configured |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### GitHub source with inline buildspec

```hcl
codebuild_projects = {
  api = {
    name = "my-company-api-build-prod"

    source = {
      type                = "GITHUB"
      location            = "https://github.com/my-org/my-api.git"
      buildspec           = "buildspec.yml"
      git_clone_depth     = 1
      report_build_status = true
    }

    environment = {
      image         = "aws/codebuild/standard:7.0"
      compute_type  = "BUILD_GENERAL1_SMALL"
      type          = "LINUX_CONTAINER"
    }

    tags = {
      Purpose = "api-build"
    }
  }
}
```

### VPC builds with `vpc_key` and `security_group_key`

When `vpc_key` is set, the environment stack resolves `vpc_id`, private `subnet_ids`, and security groups from the VPC and security-group modules.

```hcl
codebuild_projects = {
  api = {
    name                = "my-company-api-build-prod"
    vpc_key             = "main"
    security_group_key  = "app"

    source = {
      type     = "GITHUB"
      location = "https://github.com/my-org/my-api.git"
      buildspec = "buildspec.yml"
    }

    environment = {
      image = "aws/codebuild/standard:7.0"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Project name | `string` | — | yes |
| `source_config` | Source repository or S3 config | `object` | — | yes |
| `environment` | Build image and compute | `object` | — | yes |
| `create_service_role` | Create IAM service role | `bool` | `true` | no |
| `artifacts` | Output artifacts | `object` | `NO_ARTIFACTS` | no |
| `cache` | S3 or local cache | `object` | `null` | no |
| `vpc_config` | VPC subnets and security groups | `object` | `null` | no |
| `webhook` | Git webhook filters | `object` | `null` | no |
| `buildspec` | Inline buildspec for `NO_SOURCE` | `string` | `null` | no |
| `policy_statements` | Extra IAM permissions | `list(object)` | `[]` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `project_arn` | CodeBuild project ARN |
| `project_name` | CodeBuild project name |
| `service_role_arn` | IAM service role ARN |
| `log_group_name` | CloudWatch log group name |
| `webhook_url` | Webhook payload URL (when configured) |

## Notes

- Supported sources: **CODECOMMIT**, **GITHUB**, **BITBUCKET**, **S3**, **NO_SOURCE**, and more.
- Use `policy_statements` for ECR pull, Secrets Manager, Parameter Store, or other service access.
- **VPC builds** require at least one security group.
- **Webhooks** only work with GitHub, GitHub Enterprise, or Bitbucket sources.
- Connect private GitHub repos using a separate `aws_codebuild_source_credential` resource (account-level).
- `CODEPIPELINE` source type does not use `location` — configure the source in CodePipeline instead.
- `PARAMETER_STORE` and `SECRETS_MANAGER` environment variables require matching `policy_statements` on the service role.
- Set `role_name` explicitly when the project name is long (IAM role names max 64 characters).
- Use `policy_statements` for ECR image pushes, cross-account S3, or other service access beyond the baseline IAM policy.
