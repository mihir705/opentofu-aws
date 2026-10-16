# EC2 Module

OpenTofu module to create an AWS EC2 instance with always-encrypted root volumes, IMDSv2 by default, optional Elastic IP, AMI lookup, and volume tagging.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_instance` | Yes | EC2 instance with encrypted root volume (`gp3` default) |
| `aws_eip` | No | Created when `create_eip = true` |
| `aws_eip_association` | No | Associates Elastic IP with the instance |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Without key pair (SSM Session Manager)

Omit `key_name` to launch without an SSH key pair. Attach `AmazonSSMManagedInstanceCore` to the instance IAM role and connect via **AWS Systems Manager Session Manager** in the console or CLI.

```hcl
iam_roles = {
  app-ec2 = {
    name                    = "my-company-app-ec2-prod"
    trust_services          = ["ec2.amazonaws.com"]
    create_instance_profile = true
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    ]
    tags = { Purpose = "app-ec2" }
  }
}

ec2_instances = {
  app = {
    name          = "my-company-app-prod"
    instance_type = "t3.small"
    vpc_key       = "main"
    subnet_key    = "az-a"
    subnet_type   = "private"
    security_group_keys = ["app"]
    iam_role_key  = "app-ec2"
    # no key_name — SSM access only

    ami_lookup = {
      filters = { name = ["al2023-ami-*-kernel-*-x86_64"] }
    }

    tags = { Purpose = "application-server" }
  }
}
```

Private subnets need outbound connectivity (NAT gateway or VPC endpoints for `ssm`, `ssmmessages`, `ec2messages`) for SSM to work.

### Private app server with VPC wiring

```hcl
ec2_instances = {
  app = {
    name          = "my-company-app-prod"
    instance_type = "t3.small"
    vpc_key       = "main"
    subnet_key    = "az-a"
    subnet_type   = "private"
    security_group_keys = ["app"]
    iam_role_key  = "app-ec2"

    ami_lookup = {
      owners = ["amazon"]
      filters = {
        name                = ["al2023-ami-*-kernel-*-x86_64"]
        virtualization-type = ["hvm"]
      }
    }

    key_name = "my-company-prod"

    root_block_device = {
      volume_size = 30
    }

    ignore_ami_changes = true

    tags = { Purpose = "application-server" }
  }
}
```

When `vpc_key` is set, the environment stack resolves `subnet_id` from the VPC module using `subnet_key` and `subnet_type` (`public` or `private`, default `private`). Use `security_group_keys` and `iam_role_key` to wire security groups and IAM instance profiles from other modules.

### Bastion with Elastic IP

```hcl
ec2_instances = {
  bastion = {
    name          = "my-company-bastion-prod"
    instance_type = "t3.micro"
    vpc_key       = "main"
    subnet_key    = "az-a"
    subnet_type   = "public"
    security_group_keys = ["bastion"]

    ami_lookup = {
      filters = { name = ["al2023-ami-*-kernel-*-x86_64"] }
    }

    key_name                    = "my-company-prod"
    create_eip                  = true
    associate_public_ip_address = false

    tags = { Purpose = "bastion" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Instance Name tag | `string` | — | yes |
| `instance_type` | EC2 instance type | `string` | — | yes |
| `subnet_id` | Subnet for the instance | `string` | — | yes |
| `vpc_security_group_ids` | Security group IDs (1–5) | `list(string)` | `[]` | yes |
| `ami` | AMI ID | `string` | `null` | no* |
| `ami_lookup` | AMI data source lookup (requires filters) | `object` | `null` | no* |
| `key_name` | SSH key pair name; omit for keyless instances (SSM) | `string` | `null` | no |
| `iam_instance_profile` | IAM instance profile name | `string` | `null` | no |
| `availability_zone` | Pin instance to an AZ | `string` | `null` | no |
| `associate_public_ip_address` | Assign public IP in subnet | `bool` | `null` | no |
| `private_ip` | Static private IPv4 | `string` | `null` | no |
| `secondary_private_ips` | Extra private IPv4 addresses | `list(string)` | `[]` | no |
| `source_dest_check` | ENI source/destination check | `bool` | `null` | no |
| `user_data` / `user_data_base64` | Bootstrap script (mutually exclusive) | `string` | `null` | no |
| `user_data_replace_on_change` | Replace instance when user data changes | `bool` | `false` | no |
| `monitoring` | Detailed CloudWatch monitoring | `bool` | `false` | no |
| `ebs_optimized` | EBS optimization override | `bool` | `null` | no |
| `disable_api_termination` | Termination protection | `bool` | `false` | no |
| `instance_initiated_shutdown_behavior` | `stop` or `terminate` | `string` | `null` | no |
| `tenancy` | `default`, `dedicated`, or `host` | `string` | `default` | no |
| `placement_group` | Placement group name | `string` | `null` | no |
| `hibernation` | Enable hibernation | `bool` | `false` | no |
| `root_block_device` | Root volume overrides (merged with defaults) | `object` | `null` | no |
| `ebs_block_devices` | Additional EBS volumes | `map(object)` | `{}` | no |
| `metadata_options` | IMDS configuration (IMDSv2 default) | `object` | see below | no |
| `create_eip` | Create and attach Elastic IP | `bool` | `false` | no |
| `ignore_ami_changes` | Ignore AMI drift after create | `bool` | `false` | no |
| `volume_tags` | Extra tags on EBS volumes | `map(string)` | `{}` | no |
| `cpu_options` | Nitro CPU options | `object` | `null` | no |
| `credit_specification` | T-family CPU credits | `object` | `null` | no |
| `tags` | Instance and EIP tags | `map(string)` | `{}` | no |

\* Requires `ami` or `ami_lookup` (mutually exclusive). `ami_lookup.filters` must be non-empty.

### Root volume defaults

`root_block_device` is optional. When omitted, the module still applies:

| Setting | Default |
|---------|---------|
| `volume_type` | `gp3` |
| `encrypted` | `true` |
| `delete_on_termination` | `true` |

Pass `root_block_device` to override size, type, KMS key, or other settings.

### Environment-level wiring (`environments/prod`)

| Field | Resolves from |
|-------|----------------|
| `vpc_key` + `subnet_key` + `subnet_type` | VPC module subnets (`public` or `private`) |
| `security_group_keys` | Security Group module |
| `iam_role_key` | IAM Role module (`create_instance_profile = true` required) |
| `root_block_device.kms_key_key` / `ebs_block_devices.*.kms_key_key` | KMS module |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | EC2 instance ID |
| `instance_arn` | EC2 instance ARN |
| `instance_state` | EC2 instance state |
| `private_ip` | Primary private IPv4 |
| `public_ip` | Public IP or Elastic IP |
| `private_dns` | Private DNS name |
| `public_dns` | Public DNS name |
| `availability_zone` | Instance AZ |
| `ami_id` | AMI ID in use |
| `primary_network_interface_id` | Primary ENI ID |
| `eip_allocation_id` | EIP allocation ID when created |
| `eip_public_ip` | Elastic IP address when created |
| `root_block_device_volume_id` | Root EBS volume ID |
| `ebs_block_device_volume_ids` | Additional EBS volume IDs by device name |

## Validation

The module enforces:

- `ami` or `ami_lookup` required (not both); `ami_lookup.filters` non-empty
- Valid `subnet_id` format
- At least one security group (max 5)
- `user_data` and `user_data_base64` are mutually exclusive
- `create_eip` cannot be combined with `associate_public_ip_address = true`
- IMDS `http_tokens`, `http_endpoint`, and `instance_metadata_tags` values
- Unique `ebs_block_devices` device names and valid volume types
- Each EBS device defines `volume_size` or `snapshot_id`
- Root volume size, type, tenancy, shutdown behavior, and credit specification values

The environment stack additionally validates:

- `subnet_type` is `public` or `private`
- `ami` or `ami_lookup` per instance
- `create_eip` with `vpc_key` wiring requires `subnet_type = public`
- Valid `vpc_key`, `subnet_key`, `security_group_keys`, `iam_role_key`, and `kms_key_key` references

## Notes

- **Root volume encryption** is always enabled by module defaults — not dependent on account-level EBS encryption settings.
- **IMDSv2** is enforced by default (`http_tokens = required`).
- **Volume tags** inherit instance tags plus `volume_tags` and a `Name` tag on EBS volumes.
- Set `ignore_ami_changes = true` to avoid replacement when AMIs are updated in tfvars.
- Use `create_eip` for a stable public IP in a **public** subnet; do not also set `associate_public_ip_address = true`.
- `iam_role_key` requires the IAM role to have `create_instance_profile = true`.
- Pre-create EC2 key pairs in AWS when using `key_name`; omit `key_name` for keyless instances.
- For keyless access, attach `AmazonSSMManagedInstanceCore` to the IAM role and use SSM Session Manager.
