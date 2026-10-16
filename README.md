# opentofu-aws

Reusable OpenTofu modules for AWS S3, Secrets Manager, KMS, Lambda, CloudFront, VPC, ALB, NLB, Security Groups, CodeBuild, CodePipeline, IAM policies, IAM roles, IAM users, EC2, RDS, API Gateway, SNS, SQS, EKS, ECR, ECS, EFS, Cognito, and MSK, deployed per environment.

This repository is the OpenTofu counterpart of `terraform-aws`. HCL is the same; use the `tofu` CLI and the OpenTofu registry for providers.

## Structure

```
opentofu-aws/
├── modules/
│   ├── s3/
│   ├── secrets-manager/
│   ├── kms/
│   ├── lambda/
│   ├── cloudfront/
│   ├── vpc/
│   ├── alb/
│   ├── nlb/
│   ├── security-group/
│   ├── codebuild/
│   ├── codepipeline/
│   ├── iam-policy/
│   ├── iam-role/
│   ├── iam-user/
│   ├── ec2/
│   ├── rds/
│   ├── apigateway/
│   ├── sns/
│   ├── sqs/
│   ├── eks/
│   ├── ecr/
│   ├── ecs/
│   ├── efs/
│   ├── cognito/
│   └── msk/
└── environments/
    └── prod/
        ├── backend.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        ├── lambda_packages.tf      # optional zip + S3 upload for Lambda
        ├── lambda-src/             # sample Lambda source code
        └── terraform.tfvars.example
```

Add more environments by copying `environments/prod` to `environments/dev`, `environments/staging`, etc.

## How it works

Each **environment** (e.g. `prod`) manages all resources for that environment in one place:

| `terraform.tfvars` block | Module |
|--------------------------|--------|
| `buckets` | S3 |
| `secrets` | Secrets Manager |
| `kms_keys` | KMS |
| `lambda_functions` | Lambda |
| `cloudfront_distributions` | CloudFront + S3 origin |
| `vpcs` | VPC + subnets + NAT + NACL |
| `load_balancers` | Application Load Balancer |
| `network_load_balancers` | Network Load Balancer |
| `security_groups` | VPC Security Groups |
| `codebuild_projects` | CodeBuild |
| `codepipelines` | CodePipeline |
| `iam_policies` | IAM Policy |
| `iam_roles` | IAM Role |
| `iam_users` | IAM User |
| `ec2_instances` | EC2 Instance |
| `rds_instances` | RDS DB Instance |
| `api_gateways` | API Gateway HTTP API |
| `sns_topics` | SNS Topic |
| `sqs_queues` | SQS Queue |
| `eks_clusters` | EKS Cluster |
| `ecr_repositories` | ECR Repository |
| `ecs_clusters` | ECS Cluster |
| `efs_file_systems` | EFS File System |
| `cognito_user_pools` | Cognito User Pool |
| `msk_clusters` | MSK Kafka Cluster |

Each module includes a **`terraform.tfvars.example`** alongside its README with focused configuration examples. Copy the blocks you need into `environments/prod/terraform.tfvars`.

Modules are independent. Omit any block from `terraform.tfvars` when you are not managing that resource type. No empty `{}` required.

Outputs are grouped under `environment` and only include resource types you configure.

## Prerequisites

- **OpenTofu** >= 1.6.0 (`tofu` CLI)
- **S3 bucket** for remote state (already created)
- **DynamoDB table** for state locking (already created)

| Environment | State key |
|-------------|-----------|
| prod | `opentofu-aws/prod/terraform.tfstate` |

Environment providers:

- `aws` — primary region (`aws_region`)
- `aws.replica` — KMS replica region (`aws_replica_region`)
- `archive` — Lambda package zip builds

## Quick start (prod)

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
# edit backend.tf and terraform.tfvars
tofu init
tofu plan
tofu apply
```

```bash
tofu output environment
```

## Lambda deployment packages

Lambda Zip functions load code from S3. The S3 bucket **must be in the same region** as the Lambda function.

Two options:

**Option A — OpenTofu builds and uploads (recommended for dev/prod)**

```hcl
buckets = {
  lambda-artifacts = {
    bucket_name = "my-lambda-artifacts-prod"
  }
}

lambda_functions = {
  api-handler = {
    function_name      = "my-api-handler-prod"
    runtime            = "python3.12"
    handler            = "app.handler"
    s3_bucket          = "my-lambda-artifacts-prod"
    s3_key             = "api-handler/latest.zip"
    package_source_dir = "lambda-src/api-handler"
  }
}
```

`lambda_packages.tf` zips `lambda-src/api-handler` and uploads to S3 before creating the function.

**Option B — Manual upload**

Upload your zip to S3 yourself and reference `s3_bucket` + `s3_key` without `package_source_dir`.

## CloudFront static sites

The CloudFront module creates a private S3 origin bucket, Origin Access Control (OAC), and a distribution. Upload site files to the origin bucket; CloudFront serves them over HTTPS.

```hcl
cloudfront_distributions = {
  static-site = {
    origin_bucket_name  = "my-static-site-prod"
    default_root_object = "index.html"
  }
}
```

Use `create_origin_bucket = false` with `existing_origin_bucket_*` fields to front an S3 bucket created by the S3 module instead.

## Module documentation

- [modules/s3/README.md](modules/s3/README.md)
- [modules/secrets-manager/README.md](modules/secrets-manager/README.md)
- [modules/kms/README.md](modules/kms/README.md)
- [modules/lambda/README.md](modules/lambda/README.md)
- [modules/cloudfront/README.md](modules/cloudfront/README.md)
- [modules/vpc/README.md](modules/vpc/README.md)
- [modules/alb/README.md](modules/alb/README.md)
- [modules/nlb/README.md](modules/nlb/README.md)
- [modules/security-group/README.md](modules/security-group/README.md)
- [modules/codebuild/README.md](modules/codebuild/README.md)
- [modules/codepipeline/README.md](modules/codepipeline/README.md)
- [modules/iam-role/README.md](modules/iam-role/README.md)
- [modules/ec2/README.md](modules/ec2/README.md)
- [modules/rds/README.md](modules/rds/README.md)

Never commit real secret values to version control.
