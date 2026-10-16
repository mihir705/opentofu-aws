# EFS Module

OpenTofu module to create an AWS Elastic File System (EFS) with mount targets, optional access points, lifecycle policies, and AWS Backup integration.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_efs_file_system` | Yes | Shared NFS file system |
| `aws_efs_mount_target` | Yes | One per subnet ID (typically one per AZ) |
| `aws_efs_access_point` | No | Application-specific mount paths |
| `aws_efs_backup_policy` | No | When `enable_backup_policy = true` |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Shared storage for ECS/EKS

```hcl
security_groups = {
  efs = {
    name        = "my-company-efs-prod"
    vpc_key     = "main"
    description = "EFS NFS access"
    ingress_rules = [{
      description = "NFS from VPC"
      protocol    = "tcp"
      from_port   = 2049
      to_port     = 2049
      cidr_blocks = ["10.0.0.0/16"]
    }]
  }
}

efs_file_systems = {
  app-data = {
    name                = "my-company-app-data-prod"
    vpc_key             = "main"
    subnet_keys         = ["az-a", "az-b"]
    security_group_keys = ["efs"]

    access_points = {
      app = {
        path = "/app"
        posix_user = { uid = 1000, gid = 1000 }
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "755"
        }
      }
    }
  }
}
```

Mount in ECS task definitions:

```hcl
# Use output dns_name or access point ID in volume configuration
# file_system_id = module.efs["app-data"].file_system_id
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | File system name / creation token | `string` | — | yes |
| `subnet_ids` | Mount target subnets | `list(string)` | — | yes |
| `security_group_ids` | NFS security groups | `list(string)` | — | yes |
| `performance_mode` | `generalPurpose` or `maxIO` | `string` | `"generalPurpose"` | no |
| `throughput_mode` | `bursting`, `provisioned`, or `elastic` | `string` | `"bursting"` | no |
| `provisioned_throughput_in_mibps` | Provisioned MiB/s | `number` | `null` | no |
| `encrypted` | Encryption at rest | `bool` | `true` | no |
| `kms_key_id` | KMS key for encryption | `string` | `null` | no |
| `lifecycle_policy` | IA/archive transitions | `object` | `null` | no |
| `enable_backup_policy` | Enable AWS Backup | `bool` | `false` | no |
| `access_points` | Access points map | `map(object)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `file_system_id` | EFS file system ID |
| `file_system_arn` | EFS file system ARN |
| `dns_name` | DNS name for NFS mount |
| `mount_target_ids` | Mount target IDs by subnet |
| `mount_target_ips` | Mount target IPs by subnet |
| `access_point_arns` | Access point ARNs |
| `access_point_ids` | Access point IDs |

## Validation

The module includes check blocks for:

- Subnets and security groups required
- Throughput mode / provisioned throughput consistency
- KMS key only when encrypted
- Access point paths start with `/`
- Valid lifecycle transition values

## Environment wiring

In `environments/prod`, configure `efs_file_systems` with:

- `vpc_key` + `subnet_keys` for private subnets (one mount target per AZ)
- `security_group_keys` allowing NFS (TCP 2049) from clients
- `kms_key_key` for customer-managed encryption
- `access_points` for ECS/EKS pod-level isolation

## Related modules

- [vpc](../vpc/) — Subnets for mount targets
- [security-group](../security-group/) — NFS ingress rules
- [kms](../kms/) — Encryption keys
- [ecs](../ecs/) — Fargate tasks mounting EFS volumes
- [eks](../eks/) — Kubernetes persistent volumes
