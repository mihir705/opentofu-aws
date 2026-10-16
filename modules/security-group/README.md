# Security Group Module

OpenTofu module to create an AWS security group with separate ingress and egress rules using the modern `aws_vpc_security_group_*_rule` resources.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_security_group` | Yes | Core security group with `name_prefix` |
| `aws_vpc_security_group_ingress_rule` | No | One per expanded ingress rule |
| `aws_vpc_security_group_egress_rule` | No | One per expanded egress rule; defaults to all outbound IPv4 |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Basic security group with VPC integration

```hcl
security_groups = {
  app = {
    name        = "my-company-app-prod"
    vpc_key     = "main"
    description = "Application instance security group"

    ingress_rules = [
      {
        description = "HTTP from VPC"
        protocol    = "tcp"
        from_port   = 8080
        to_port     = 8080
        cidr_blocks = ["10.0.0.0/16"]
      }
    ]

    tags = {
      Purpose = "app"
    }
  }
}
```

### Allow traffic from another security group

```hcl
ingress_rules = [
  {
    description                  = "HTTP from ALB"
    protocol                     = "tcp"
    from_port                    = 8080
    to_port                      = 8080
    referenced_security_group_id = "sg-0123456789abcdef0"
  }
]
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Security group name prefix | `string` | — | yes |
| `vpc_id` | VPC ID | `string` | — | yes |
| `description` | Description | `string` | auto | no |
| `revoke_rules_on_delete` | Revoke rules on delete | `bool` | `true` | no |
| `ingress_rules` | Ingress rules | `list(object)` | `[]` | no |
| `egress_rules` | Egress rules | `list(object)` | all outbound IPv4 | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

### Rule object fields

| Field | Description |
|-------|-------------|
| `protocol` | `tcp`, `udp`, `icmp`, `icmpv6`, or `-1` |
| `from_port` / `to_port` | Required for `tcp` and `udp` |
| `cidr_blocks` | IPv4 CIDR list (expanded to separate rules) |
| `ipv6_cidr_blocks` | IPv6 CIDR list |
| `prefix_list_ids` | Managed prefix list IDs |
| `referenced_security_group_id` | Source/destination security group |
| `self_reference` | Allow traffic within the same security group |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | Security group ID |
| `security_group_arn` | Security group ARN |
| `security_group_name` | Security group name |
| `ingress_rule_ids` | Ingress rule IDs |
| `egress_rule_ids` | Egress rule IDs |

## Design notes

- **Separate rule resources**: Uses `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` instead of inline rules to avoid rule drift and replacement churn.
- **Rule expansion**: Each CIDR, prefix list, SG reference, or self-reference becomes its own rule resource.
- **Default egress**: Allows all outbound IPv4 (`0.0.0.0/0`) when `egress_rules` is not set. Set `egress_rules = []` for no egress. Add IPv6 egress explicitly if required.
- **VPC integration**: Use `vpc_key` in the environment stack to resolve `vpc_id` from the VPC module.
- **Cross-SG references**: Use `referenced_security_group_id` with SG IDs from `tofu output` (e.g. ALB `security_group_id`).
- **Self-reference**: Set `self_reference = true` on a rule; the module maps it to `referenced_security_group_id` on the same security group (required by the AWS provider API).

## Common workflow

1. Create VPC.
2. Create security groups with `vpc_key = "main"`.
3. Reference `security_group_id` outputs in Lambda `vpc_config`, EC2, RDS, or ALB `security_group_ids`.
