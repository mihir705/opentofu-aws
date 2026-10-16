# SQS Module

OpenTofu module to create AWS SQS queues with optional dead-letter queues, encryption, queue policies, and SNS publish permissions.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_sqs_queue` | Yes | Standard or FIFO queue |
| `aws_sqs_queue` (DLQ) | No | When `create_dlq = true` |
| `aws_sqs_queue_policy` | No | When `policy_json`, `policy_statements`, or `allowed_sns_topic_arns` is set |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

### Standard queue with DLQ

```hcl
sqs_queues = {
  app-jobs = {
    name                       = "my-company-app-jobs-prod"
    visibility_timeout_seconds = 60
    receive_wait_time_seconds  = 20
    create_dlq                 = true
    max_receive_count          = 5

    tags = { Purpose = "background-jobs" }
  }
}
```

### SNS fan-out (queue policy auto-generated)

```hcl
sqs_queues = {
  app-events = {
    name           = "my-company-app-events-prod"
    sns_topic_keys = ["app-events"]
  }
}
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `name` / `name_prefix` | Queue naming (exactly one required) | — |
| `fifo_queue` | FIFO queue | `false` |
| `content_based_deduplication` | FIFO deduplication | `false` |
| `deduplication_scope` | `messageGroup` or `queue` | `null` |
| `fifo_throughput_limit` | `perQueue` or `perMessageGroupId` | `null` |
| `delay_seconds` | Delivery delay (0–900) | `0` |
| `max_message_size` | Max bytes (1024–262144) | `262144` |
| `message_retention_seconds` | Retention (60–1209600) | `345600` |
| `receive_wait_time_seconds` | Long polling (0–20) | `0` |
| `visibility_timeout_seconds` | Visibility (0–43200) | `30` |
| `kms_key_id` | KMS encryption | `null` |
| `sqs_managed_sse_enabled` | SSE-SQS (default when no KMS) | `true` |
| `create_dlq` | Create dead-letter queue | `false` |
| `max_receive_count` | DLQ redrive threshold | `3` |
| `policy_json` / `policy_statements` | Queue access policy | — |
| `allowed_sns_topic_arns` | SNS ARNs allowed to publish | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| `queue_arn` | Queue ARN |
| `queue_url` | Queue URL |
| `queue_name` | Queue name |
| `dlq_arn` | DLQ ARN when created |
| `dlq_url` | DLQ URL when created |

## Validation

The module includes **19 `check` blocks** for:

- Exclusive `name` / `name_prefix`
- FIFO naming (`.fifo` suffix) for main and DLQ queues
- FIFO-only attributes and high-throughput mode consistency
- Timing, size, and retention ranges
- Encryption source exclusivity (KMS vs SSE-SQS)
- Redrive policy rules and DLQ naming
- Policy source exclusivity (`policy_json` vs statements vs SNS ARNs)

## Coverage matrix

| Capability | Supported | Notes |
|------------|-----------|-------|
| Standard queues | Yes | Default queue type |
| FIFO queues | Yes | Name must end with `.fifo` |
| SSE-SQS encryption | Yes | Enabled by default |
| KMS encryption | Yes | `kms_key_id` or `kms_key_key` |
| Dead-letter queue | Yes | `create_dlq` with auto redrive policy |
| Custom redrive | Yes | `redrive_policy` / `redrive_allow_policy` |
| Queue policy | Yes | `policy_json` or `policy_statements` |
| SNS fan-out policy | Yes | `sns_topic_keys` auto-generates publish policy |
| Long polling | Yes | `receive_wait_time_seconds` |
| FIFO high throughput | Yes | `deduplication_scope` + `fifo_throughput_limit` |
| Message size / delay / retention | Yes | Full tuning parameters |
| Lambda event source mapping | No | Configure in Lambda module |
| S3 event notifications | No | Wire separately if needed |
| Auto-create SNS subscription | No | Subscribe in SNS module |

## Environment wiring

| Key | Resolves to |
|-----|-------------|
| `kms_key_key` | KMS key ARN |
| `sns_topic_keys` | SNS topic ARNs for auto queue policy |

## Notes

- FIFO queue names must end with `.fifo`.
- When using KMS, `sqs_managed_sse_enabled` is automatically disabled in prod wiring.
- Lambda event source mappings are configured in the Lambda module, not here.
- SNS subscriptions to SQS still require a matching queue policy (use `sns_topic_keys`).
- When using `kms_key_key`, ensure the KMS key policy allows `sqs.amazonaws.com` to use the key.
- Set `visibility_timeout_seconds` >= Lambda timeout when using event source mappings.
