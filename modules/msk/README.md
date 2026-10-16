# MSK Module

OpenTofu module to create an Amazon MSK (Managed Streaming for Apache Kafka) cluster with optional configuration, broker logging, Prometheus monitoring, SASL/SCRAM secrets, and encryption.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_msk_cluster` | Yes | Managed Kafka cluster |
| `aws_msk_configuration` | No | Custom broker/server properties |
| `aws_cloudwatch_log_group` | No | Auto-created when CloudWatch logging is enabled |
| `aws_msk_single_scram_secret_association` | No | One per SCRAM secret ARN |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Private cluster with TLS and IAM auth

```hcl
security_groups = {
  msk = {
    name        = "my-company-msk-prod"
    vpc_key     = "main"
    description = "MSK broker access"
    ingress_rules = [{
      description = "Kafka TLS from VPC"
      protocol    = "tcp"
      from_port   = 9094
      to_port     = 9094
      cidr_blocks = ["10.0.0.0/16"]
    }, {
      description = "Kafka IAM from VPC"
      protocol    = "tcp"
      from_port   = 9098
      to_port     = 9098
      cidr_blocks = ["10.0.0.0/16"]
    }]
  }
}

msk_clusters = {
  events = {
    name                   = "my-company-events-prod"
    vpc_key                = "main"
    subnet_keys            = ["az-a", "az-b", "az-c"]
    security_group_keys    = ["msk"]
    number_of_broker_nodes = 3
    kms_key_key            = "main"

    client_authentication = {
      sasl = { iam = true }
    }

    logging = {
      cloudwatch = { enabled = true }
    }
  }
}
```

Connect using output `bootstrap_brokers_sasl_iam` with the [AWS MSK IAM SASL signer library](https://docs.aws.amazon.com/msk/latest/developerguide/iam-access-control.html).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Cluster name | `string` | — | yes |
| `subnet_ids` | Broker subnets (multi-AZ) | `list(string)` | — | yes |
| `security_group_ids` | Broker security groups | `list(string)` | — | yes |
| `kafka_version` | Kafka version | `string` | `"3.6.0"` | no |
| `number_of_broker_nodes` | Broker count (multiple of subnets) | `number` | `3` | no |
| `broker_instance_type` | Broker instance type | `string` | `"kafka.m5.large"` | no |
| `ebs_volume_size` | EBS size per broker (GiB) | `number` | `100` | no |
| `kms_key_id` | Custom KMS key ARN for at-rest encryption | `string` | `null` | no |
| `encryption_in_transit` | Client/broker and in-cluster TLS | `object` | TLS defaults | no |
| `client_authentication` | SASL/IAM/SCRAM/TLS/mTLS options | `object` | `{}` | no |
| `public_access` | `DISABLED` or `SERVICE_PROVIDED_E2E` | `string` | `"DISABLED"` | no |
| `configuration` | Create or attach MSK configuration | `object` | `null` | no |
| `logging` | CloudWatch, S3, or Firehose broker logs | `object` | `null` | no |
| `open_monitoring` | Prometheus JMX/node exporters | `object` | `null` | no |
| `enhanced_monitoring` | CloudWatch monitoring granularity | `string` | `"DEFAULT"` | no |
| `storage_mode` | `LOCAL` or `TIERED` | `string` | `"LOCAL"` | no |
| `scram_secret_arns` | SCRAM credentials in Secrets Manager | `list(string)` | `[]` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_arn` | MSK cluster ARN |
| `cluster_name` | Cluster name |
| `bootstrap_brokers_tls` | TLS bootstrap brokers |
| `bootstrap_brokers_sasl_iam` | IAM SASL bootstrap brokers |
| `bootstrap_brokers_sasl_scram` | SCRAM SASL bootstrap brokers |
| `bootstrap_brokers_public_tls` | Public TLS endpoints when enabled |
| `zookeeper_connect_string_tls` | TLS ZooKeeper connect string |
| `configuration_arn` | Attached/created configuration ARN |
| `cloudwatch_log_group_name` | Broker log group when CloudWatch logging is on |

## Validation

The module includes `check` blocks for:

- At least two subnets spanning two AZs
- Broker count is a multiple of subnet count
- SCRAM secrets when SCRAM auth is enabled
- Configuration create vs attach exclusivity
- Logging destination requirements (S3 bucket, Firehose stream)
- Provisioned EBS throughput when enabled

## Notes

- MSK cluster creation typically takes **15–30 minutes**.
- `number_of_broker_nodes` must be a **multiple of the number of subnets** (one subnet per AZ).
- For SCRAM auth, store credentials in Secrets Manager using the [MSK SCRAM secret format](https://docs.aws.amazon.com/msk/latest/developerguide/msk-password.html) before associating.
