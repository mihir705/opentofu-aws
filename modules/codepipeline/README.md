# CodePipeline Module

OpenTofu module to create an AWS CodePipeline with IAM service role, S3 artifact store, ordered stages, optional V2 triggers, and pipeline variables.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_codepipeline` | Yes | CI/CD pipeline |
| `aws_iam_role` | No | Created when `create_service_role = true` |
| `aws_iam_role_policy` | No | Baseline S3, CodeBuild, and CodeStar Connections permissions |
| `aws_iam_role_policy_attachment` | No | Optional managed policies |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Source → Build pipeline (GitHub + CodeBuild)

```hcl
codepipelines = {
  api = {
    name                = "my-company-api-pipeline-prod"
    artifact_bucket_key = "pipeline-artifacts"

    stages = [
      {
        name = "Source"
        actions = [
          {
            name             = "Source"
            category         = "Source"
            owner            = "AWS"
            provider         = "CodeStarSourceConnection"
            version          = "1"
            output_artifacts = ["source_output"]
            configuration = {
              ConnectionArn    = "arn:aws:codestar-connections:ap-south-1:123456789012:connection/abc"
              FullRepositoryId = "my-org/my-api"
              BranchName       = "main"
            }
          }
        ]
      },
      {
        name = "Build"
        actions = [
          {
            name              = "Build"
            category          = "Build"
            owner             = "AWS"
            provider          = "CodeBuild"
            version           = "1"
            input_artifacts   = ["source_output"]
            codebuild_project_key = "api"
          }
        ]
      }
    ]

    tags = {
      Purpose = "api-pipeline"
    }
  }
}
```

When `artifact_bucket_key` and `codebuild_project_key` are set, the environment stack resolves bucket and project names from the S3 and CodeBuild modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Pipeline name | `string` | — | yes |
| `artifact_bucket` | S3 artifact bucket name | `string` | — | yes |
| `stages` | Ordered stages and actions | `list(object)` | — | yes |
| `pipeline_type` | `V1` or `V2` | `string` | `V2` | no |
| `create_service_role` | Create IAM service role | `bool` | `true` | no |
| `artifact_kms_key_arn` | KMS key for artifact encryption | `string` | `null` | no |
| `trigger` | V2 git push trigger | `object` | `null` | no |
| `variables` | V2 pipeline variables | `list(object)` | `[]` | no |
| `policy_statements` | Extra IAM permissions | `list(object)` | `[]` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `pipeline_arn` | CodePipeline ARN |
| `pipeline_name` | CodePipeline name |
| `service_role_arn` | IAM service role ARN |
| `artifact_bucket` | S3 artifact bucket name |

## Notes

- Action `configuration` values must be **strings** (CodePipeline API requirement).
- Use `codebuild_project_key` in the environment tfvars to auto-wire CodeBuild project names.
- GitHub/GitLab sources require a **CodeStar connection** (`aws_codestarconnections_connection`) created separately.
- Add `policy_statements` for ECS, Lambda, CloudFormation, or other deploy action permissions.
- CodeBuild projects used in pipelines should use `artifacts.type = "CODEPIPELINE"` and `source.type = "CODEPIPELINE"` when fully managed by the pipeline.
- Cross-region pipelines require `artifact_store_region` on the primary store and `region` on each secondary artifact store.
- Pipeline action and stage names must be **unique**.
- Set `role_name` explicitly when the pipeline name is long (IAM role names max 64 characters).
