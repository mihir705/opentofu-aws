# Lambda Module

OpenTofu module to create and manage an AWS Lambda function with an IAM execution role, CloudWatch logging, optional VPC access, custom IAM permissions, and an optional function URL.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_iam_role` | Yes | Lambda execution role |
| `aws_lambda_function` | Yes | Lambda function |
| `aws_cloudwatch_log_group` | No | Created when `create_log_group = true` |
| `aws_iam_role_policy_attachment` | Yes | Basic execution policy |
| `aws_iam_role_policy_attachment` | No | VPC access policy when `vpc_config` is set |
| `aws_iam_role_policy` | No | Created when `policy_statements` is non-empty |
| `aws_lambda_function_url` | No | Created when `function_url` is set |
| `aws_lambda_event_source_mapping` | No | One per entry in `event_source_mappings` |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Zip function from S3

```hcl
module "api_handler" {
  source = "./modules/lambda"

  function_name = "my-company-api-handler-prod"
  description   = "API request handler"
  runtime       = "python3.12"
  handler       = "app.handler"

  s3_bucket = "my-company-lambda-artifacts-prod"
  s3_key    = "api-handler/latest.zip"

  memory_size = 256
  timeout     = 30

  environment_variables = {
    ENV = "prod"
  }

  tags = {
    Purpose = "api-handler"
  }
}
```

### Container image function

```hcl
module "worker" {
  source = "./modules/lambda"

  function_name = "my-company-worker-prod"
  package_type  = "Image"
  image_uri     = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/my-worker:latest"

  memory_size = 512
  timeout     = 60

  tags = {
    Purpose = "worker"
  }
}
```

### VPC-enabled function with custom IAM permissions

```hcl
module "private_processor" {
  source = "./modules/lambda"

  function_name = "my-company-private-processor-prod"
  runtime       = "python3.12"
  handler       = "processor.run"
  s3_bucket     = "my-company-lambda-artifacts-prod"
  s3_key        = "private-processor/latest.zip"

  vpc_config = {
    subnet_ids         = ["subnet-abc123"]
    security_group_ids = ["sg-abc123"]
  }

  policy_statements = [
    {
      sid    = "ReadAppBucket"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = [
        "arn:aws:s3:::my-company-app-data-prod",
        "arn:aws:s3:::my-company-app-data-prod/*",
      ]
    }
  ]

  tags = {
    Purpose = "private-processor"
  }
}
```

### Function URL

```hcl
module "webhook" {
  source = "./modules/lambda"

  function_name = "my-company-webhook-prod"
  runtime       = "python3.12"
  handler       = "webhook.handler"
  s3_bucket     = "my-company-lambda-artifacts-prod"
  s3_key        = "webhook/latest.zip"

  function_url = {
    authorization_type = "AWS_IAM"
    cors = {
      allow_methods = ["POST"]
      allow_origins = ["https://app.example.com"]
    }
  }
}
```

### SQS or SNS event source

```hcl
module "queue_processor" {
  source = "./modules/lambda"

  function_name = "my-company-queue-processor-prod"
  runtime         = "python3.12"
  handler         = "processor.handler"
  s3_bucket       = "my-company-lambda-artifacts-prod"
  s3_key          = "queue-processor/latest.zip"

  event_source_mappings = [
    {
      name             = "orders-queue"
      event_source_arn = "arn:aws:sqs:ap-south-1:123456789012:orders-queue-prod"
      batch_size       = 10
      function_response_types = ["ReportBatchItemFailures"]
    },
    {
      name             = "alerts-topic"
      event_source_arn = "arn:aws:sns:ap-south-1:123456789012:alerts-topic-prod"
    }
  ]
}
```

### Local Zip with source_code_hash

```hcl
module "local_handler" {
  source = "./modules/lambda"

  function_name   = "my-company-local-handler-prod"
  runtime         = "python3.12"
  handler         = "app.handler"
  filename        = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `function_name` | Unique Lambda function name | `string` | n/a | yes |
| `role_name` | IAM role name override | `string` | `null` | no |
| `description` | Function description | `string` | `null` | no |
| `package_type` | `Zip` or `Image` | `string` | `"Zip"` | no |
| `runtime` | Runtime for Zip packages | `string` | `null` | no |
| `handler` | Handler for Zip packages | `string` | `null` | no |
| `filename` | Local Zip deployment package path | `string` | `null` | no |
| `s3_bucket` | S3 bucket for Zip package | `string` | `null` | no |
| `s3_key` | S3 key for Zip package | `string` | `null` | no |
| `s3_object_version` | S3 object version | `string` | `null` | no |
| `source_code_hash` | SHA256 hash for local Zip packages | `string` | `null` | no |
| `image_uri` | Container image URI | `string` | `null` | no |
| `memory_size` | Memory in MB (`128-10240`) | `number` | `128` | no |
| `timeout` | Timeout in seconds (`1-900`) | `number` | `3` | no |
| `architectures` | `x86_64` and/or `arm64` | `list(string)` | `["x86_64"]` | no |
| `environment_variables` | Environment variables | `map(string)` | `{}` | no |
| `kms_key_arn` | KMS key for env var encryption | `string` | `null` | no |
| `layers` | Lambda layer ARNs | `list(string)` | `[]` | no |
| `ephemeral_storage_size` | `/tmp` storage in MB | `number` | `512` | no |
| `reserved_concurrent_executions` | Reserved concurrency | `number` | `null` | no |
| `tracing_mode` | X-Ray mode (`Active` or `PassThrough`) | `string` | `"PassThrough"` | no |
| `vpc_config` | VPC configuration | `object` | `null` | no |
| `dead_letter_config` | Dead letter target ARN | `object` | `null` | no |
| `create_log_group` | Create CloudWatch log group | `bool` | `true` | no |
| `log_retention_in_days` | Log retention in days | `number` | `14` | no |
| `policy_statements` | Extra IAM policy statements | `list(object)` | `[]` | no |
| `function_url` | Function URL configuration | `object` | `null` | no |
| `event_source_mappings` | SQS or SNS event source mappings | `list(object)` | `[]` | no |
| `tags` | Tags for function and role | `map(string)` | `{}` | no |

### `event_source_mappings` object

```hcl
event_source_mappings = [
  {
    name                               = string
    event_source_arn                   = string
    batch_size                         = optional(number, 10)
    enabled                            = optional(bool, true)
    maximum_batching_window_in_seconds = optional(number)
    function_response_types            = optional(list(string), [])
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| `function_name` | Name of the Lambda function |
| `function_arn` | ARN of the Lambda function |
| `invoke_arn` | Invoke ARN |
| `qualified_arn` | Qualified ARN |
| `role_arn` | Execution role ARN |
| `role_name` | Execution role name |
| `log_group_name` | CloudWatch log group name |
| `function_url` | Function URL |
| `event_source_mapping_uuids` | Map of event source names to mapping UUIDs |

## Security defaults

- Dedicated IAM execution role per function
- CloudWatch log group created by default with 14-day retention
- `AWSLambdaBasicExecutionRole` always attached
- `AWSLambdaVPCAccessExecutionRole` attached automatically when `vpc_config` is set
- Function URL defaults to `AWS_IAM` authorization

## Validation rules

- Zip functions require `runtime`, `handler`, and `filename` or `s3_bucket` + `s3_key`
- Zip functions cannot use both `filename` and `s3_bucket` + `s3_key`
- S3 deployment bucket must be in the **same AWS region** as the Lambda function
- `source_code_hash` is required when using `filename`
- Image functions require `image_uri`
- `package_type` must be `Zip` or `Image`
- `role_name` must be 64 characters or fewer
- `memory_size`, `timeout`, and `ephemeral_storage_size` are range-validated

## Environment-level packaging

When used from `environments/prod`, set `package_source_dir` in `lambda_functions` to zip and upload source before create. See root [README](../../README.md#lambda-deployment-packages).

## What this module does not manage

- Lambda layers creation
- DynamoDB stream, Kinesis, and MSK event sources
- Lambda aliases and versions publishing
- CodeBuild / CI packaging pipeline
- ECR image build and push
