# RDS Module

OpenTofu module to create an AWS RDS DB instance with DB subnet group, optional parameter group, encrypted storage by default, and flexible master password management.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_db_instance` | Yes | RDS database instance |
| `aws_db_subnet_group` | No | Created when `create_db_subnet_group = true` (default) |
| `aws_db_parameter_group` | No | Created when `create_parameter_group = true` |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |
| [Random Provider](https://registry.opentofu.org/hashicorp/random/latest) | >= 3.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### PostgreSQL with VPC wiring and AWS-managed password

```hcl
rds_instances = {
  app-db = {
    identifier     = "my-company-app-db-prod"
    engine         = "postgres"
    engine_version_lookup = {
      version = "16"
      latest  = true
    }
    instance_class = "db.t4g.micro"
    allocated_storage = 20
    username       = "dbadmin"
    manage_master_user_password = true

    db_name = "appdb"

    vpc_key     = "main"
    subnet_keys = ["az-a", "az-b"]
    security_group_keys = ["rds"]

    enabled_cloudwatch_logs_exports = ["postgresql"]

    tags = { Purpose = "application-database" }
  }
}
```

When `vpc_key` is set, the environment stack resolves **private** subnet IDs from `subnet_keys` (minimum two AZs). Use `security_group_keys` and `kms_key_key` to wire security groups and KMS from other modules.

### Master password options

| Method | Use when |
|--------|----------|
| `manage_master_user_password = true` | **Recommended** — RDS stores password in Secrets Manager |
| `generate_password = {}` | Terraform generates password; retrieve via sensitive output |
| `password` | You supply the password directly (avoid in committed tfvars) |

Use **exactly one** of the above per instance.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `identifier` | RDS instance identifier (max 63 chars) | `string` | — | yes |
| `engine` | Database engine | `string` | — | yes |
| `engine_version` | Pin exact engine version | `string` | `null` | no* |
| `engine_version_lookup` | Resolve latest version in region | `object` | `null` | no* |
| `instance_class` | Instance class | `string` | — | yes |
| `allocated_storage` | Storage in GiB (min 20) | `number` | — | yes |
| `username` | Master username | `string` | — | yes |
| `subnet_ids` | Subnets for DB subnet group (min 2 AZs) | `list(string)` | `[]` | no* |
| `vpc_security_group_ids` | Security group IDs (1–5) | `list(string)` | `[]` | yes |
| `password` | Master password | `string` | `null` | no** |
| `manage_master_user_password` | AWS-managed password in Secrets Manager | `bool` | `false` | no** |
| `generate_password` | Terraform-generated password | `object` | `null` | no** |
| `db_name` | Initial database name | `string` | `null` | no |
| `port` | Database port | `number` | `null` | no |
| `max_allocated_storage` | Storage autoscaling ceiling (0 = off) | `number` | `0` | no |
| `storage_type` | `gp2`, `gp3`, `io1`, or `standard` | `string` | `gp3` | no |
| `iops` | Provisioned IOPS | `number` | `null` | no |
| `storage_throughput` | gp3 throughput | `number` | `null` | no |
| `multi_az` | Multi-AZ deployment | `bool` | `false` | no |
| `publicly_accessible` | Public accessibility | `bool` | `false` | no |
| `storage_encrypted` | Enable encryption | `bool` | `true` | no |
| `kms_key_id` | KMS key ARN/ID for storage | `string` | `null` | no |
| `create_db_subnet_group` | Create DB subnet group | `bool` | `true` | no |
| `db_subnet_group_name` | Existing subnet group name | `string` | `null` | no |
| `create_parameter_group` | Create parameter group | `bool` | `false` | no |
| `parameter_group_family` | Family when creating parameter group | `string` | `null` | no |
| `parameters` | DB parameters | `list(object)` | `[]` | no |
| `deletion_protection` | Deletion protection | `bool` | `true` | no |
| `backup_retention_period` | Backup retention (0–35 days) | `number` | `7` | no |
| `backup_window` | Preferred backup window | `string` | `null` | no |
| `maintenance_window` | Preferred maintenance window | `string` | `null` | no |
| `skip_final_snapshot` | Skip final snapshot on destroy | `bool` | `false` | no |
| `final_snapshot_identifier` | Final snapshot name | `string` | `null` | no |
| `apply_immediately` | Apply changes immediately | `bool` | `false` | no |
| `auto_minor_version_upgrade` | Auto minor version upgrades | `bool` | `true` | no |
| `monitoring_interval` | Enhanced monitoring seconds (0=off) | `number` | `0` | no |
| `monitoring_role_arn` | IAM role for enhanced monitoring | `string` | `null` | no |
| `enabled_cloudwatch_logs_exports` | Engine-specific log exports | `list(string)` | `[]` | no |
| `performance_insights_enabled` | Enable Performance Insights | `bool` | `false` | no |
| `performance_insights_kms_key_id` | PI KMS key ARN/ID | `string` | `null` | no |
| `performance_insights_retention_period` | PI retention days | `number` | `null` | no |
| `copy_tags_to_snapshot` | Copy tags to snapshots | `bool` | `true` | no |
| `iam_database_authentication_enabled` | IAM DB authentication | `bool` | `false` | no |
| `ca_cert_identifier` | RDS CA certificate identifier | `string` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Requires `engine_version` or `engine_version_lookup` (mutually exclusive). Prefer `engine_version_lookup` to auto-select a version available in your region.

\** Exactly one password method required.

### CloudWatch log exports by engine

| Engine | Allowed log types |
|--------|-------------------|
| `postgres` | `postgresql`, `upgrade` |
| `mysql`, `mariadb` | `audit`, `error`, `general`, `iam-db-auth-error`, `slowquery` |
| `sqlserver-*` | `agent`, `error` |
| `oracle-*` | `alert`, `audit`, `listener`, `trace`, `oemagent` |

### Environment-level wiring (`environments/prod`)

| Field | Resolves from |
|-------|----------------|
| `vpc_key` + `subnet_keys` | VPC module private subnets (min 2 AZs) |
| `security_group_keys` | Security Group module |
| `kms_key_key` | KMS module |

## Outputs

| Name | Description |
|------|-------------|
| `db_instance_id` | RDS instance identifier |
| `db_instance_arn` | RDS instance ARN |
| `db_instance_endpoint` | Connection endpoint (`host:port`) |
| `db_instance_address` | Hostname |
| `db_instance_port` | Port |
| `db_instance_resource_id` | RDS resource ID |
| `db_name` | Database name |
| `master_username` | Master username |
| `db_subnet_group_name` | DB subnet group name |
| `parameter_group_name` | Parameter group name |
| `master_user_secret_arn` | Secrets Manager ARN when using `manage_master_user_password` |
| `generated_password` | Sensitive output when using `generate_password` |

## Validation

The module enforces:

- `engine_version` or `engine_version_lookup` required (not both); lookup resolves region-available versions
- Valid `subnet_id` format
- At least one security group (max 5)
- Exactly one master password source
- `max_allocated_storage >= allocated_storage` when autoscaling is enabled
- Valid KMS key ARN/ID format when `kms_key_id` or `performance_insights_kms_key_id` is set
- Engine-specific CloudWatch log export types
- Parameter group family when creating a parameter group
- Final snapshot identifier when `skip_final_snapshot = false` (defaults to `<identifier>-final-snapshot`)
- Enhanced monitoring IAM role when `monitoring_interval > 0`
- Storage encryption when Performance Insights is enabled
- Supported engines, storage types, and backup retention range

The environment stack additionally validates:

- Two `subnet_keys` spanning at least two AZs in VPC config
- Valid `vpc_key`, `subnet_key`, `security_group_keys`, `iam_role_key`, and `kms_key_key` references
- Exactly one password method per instance

## Notes

- **Storage encryption** defaults to `true` (uses AWS managed RDS key when `kms_key_id` is omitted).
- **Deletion protection** defaults to `true` for production safety.
- RDS subnet groups require subnets in **at least two availability zones**.
- Place RDS in **private subnets**; keep `publicly_accessible = false`.
- Allow ingress only from application security groups (port 5432 PostgreSQL, 3306 MySQL).
- Retrieve AWS-managed credentials from Secrets Manager using `master_user_secret_arn`.
- `password` changes are ignored after create to avoid unintended replacements.
- Aurora clusters, read replicas, and option groups are out of scope for this single-instance module.
