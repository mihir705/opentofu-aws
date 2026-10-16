# SNS Module

OpenTofu module to create AWS SNS topics with optional KMS encryption, topic policies, subscriptions, and Lambda invoke permissions.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_sns_topic` | Yes | Standard or FIFO topic |
| `aws_sns_topic_policy` | No | When `policy_json` or `policy_statements` is set |
| `aws_sns_topic_subscription` | No | One per entry in `subscriptions` |
| `aws_lambda_permission` | No | For `lambda` protocol subscriptions |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Standard topic with email alert

```hcl
sns_topics = {
  app-alerts = {
    name         = "my-company-app-alerts-prod"
    display_name = "Application Alerts"

    subscriptions = {
      ops-email = {
        protocol = "email"
        endpoint = "ops@example.com"
      }
    }

    tags = { Purpose = "app-alerts" }
  }
}
```

### Lambda subscription with KMS encryption

```hcl
sns_topics = {
  app-events = {
    name        = "my-company-app-events-prod"
    kms_key_key = "app-encryption"

    subscriptions = {
      handler = {
        protocol            = "lambda"
        lambda_function_key = "alert-handler"
      }
    }
  }
}
```

When `lambda_function_key` is set, the environment stack resolves the function ARN and creates the required `aws_lambda_permission`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Topic name | `string` | `null` | no* |
| `name_prefix` | Topic name prefix | `string` | `null` | no* |
| `display_name` | Console display name | `string` | `null` | no |
| `fifo_topic` | FIFO topic | `bool` | `false` | no |
| `content_based_deduplication` | FIFO content-based dedup | `bool` | `false` | no |
| `fifo_throughput_scope` | FIFO high-throughput: `Topic` or `MessageGroup` | `string` | `null` | no |
| `kms_key_id` | KMS key ID or ARN | `string` | `null` | no |
| `delivery_policy` | JSON delivery policy | `string` | `null` | no |
| `archive_policy` | FIFO message archive JSON (`MessageRetentionPeriod`) | `string` | `null` | no |
| `policy_json` | Full topic policy JSON | `string` | `null` | no |
| `policy_statements` | Policy statements merged into default policy | `list(object)` | `[]` | no |
| `subscriptions` | Subscriptions keyed by logical name | `map(object)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Exactly one of `name` or `name_prefix` is required.

### Subscription object

| Field | Description |
|-------|-------------|
| `protocol` | `sqs`, `lambda`, `email`, `email-json`, `sms`, `application`, `http`, `https`, `firehose` |
| `endpoint` | Target ARN, email, phone, or URL |
| `lambda_function_name` | Lambda name for invoke permissions |
| `raw_message_delivery` | Deliver raw payload (common for SQS) |
| `filter_policy` | JSON filter policy |
| `filter_policy_scope` | `MessageAttributes` or `MessageBody` |
| `redrive_policy` | JSON dead-letter redrive policy |
| `subscription_role_arn` | IAM role for cross-account delivery |

## Outputs

| Name | Description |
|------|-------------|
| `topic_id` | Topic ID |
| `topic_arn` | Topic ARN |
| `topic_name` | Topic name |
| `display_name` | Display name |
| `fifo_topic` | Whether topic is FIFO |
| `subscription_arns` | Subscription ARNs by logical key |
| `subscription_ids` | Subscription IDs by logical key |
| `owner` | AWS account ID |

## Validation

The module includes **12 `check` blocks** for:

- Exclusive `name` / `name_prefix`
- FIFO naming (`.fifo` suffix)
- FIFO-only attributes (`content_based_deduplication`, `archive_policy`)
- FIFO subscription protocol restrictions
- Policy source exclusivity
- Supported subscription protocols
- Endpoint / Lambda name requirements
- Filter policy scope values
- HTTP auto-confirm protocol rules

## Coverage matrix

| Capability | Supported | Notes |
|------------|-----------|-------|
| Standard topics | Yes | Default topic type |
| FIFO topics | Yes | Name must end with `.fifo` |
| KMS encryption | Yes | `kms_key_id` or `kms_key_key` |
| Topic policy | Yes | `policy_json` or `policy_statements` |
| Lambda subscriptions | Yes | Auto `aws_lambda_permission` |
| SQS subscriptions | Yes | Queue policy must allow SNS publish |
| Email / SMS alerts | Yes | Standard topics only; email needs confirmation |
| HTTP/HTTPS webhooks | Yes | Standard topics; optional auto-confirm |
| Firehose delivery | Yes | |
| Message filtering | Yes | `filter_policy` + scope |
| Dead-letter redrive | Yes | `redrive_policy` on subscription |
| FIFO high throughput | Yes | `fifo_throughput_scope` |
| FIFO message archive | Yes | `archive_policy` JSON |
| Delivery policy | Yes | Retry/backoff JSON |
| Cross-account delivery | Yes | `subscription_role_arn` |
| SMS sandbox / opt-in | No | AWS account-level setup |
| Auto SQS queue policy | No | Configure queue policy separately |
| SNS → SQS fanout module | No | Wire queue ARNs explicitly |

## Environment wiring

In `environments/prod`, use `sns_topics` with cross-module keys:

| Key | Resolves to |
|-----|-------------|
| `kms_key_key` | KMS key ARN from KMS module |
| `lambda_function_key` | Lambda function ARN + permission name |

## Notes

- Email and HTTP/HTTPS subscriptions require manual confirmation unless `endpoint_auto_confirms` is used (HTTP/HTTPS only).
- FIFO topic names **must** end with `.fifo`.
- SQS subscriptions require the queue policy to allow SNS to publish.
- For encrypted topics, subscribers need KMS decrypt permissions on the topic key.
- When using `kms_key_key`, ensure the KMS key policy allows `sns.amazonaws.com` to use the key.
