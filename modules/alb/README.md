# ALB Module

OpenTofu module to create an AWS Application Load Balancer with security group, target groups, listeners, and optional listener rules.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_lb` | Yes | Application Load Balancer |
| `aws_security_group` | No | Created when `create_security_group = true` |
| `aws_lb_target_group` | Yes | One per `target_groups` entry |
| `aws_lb_listener` | Yes | One per `listeners` entry |
| `aws_lb_listener_rule` | No | Created from optional `listeners.*.rules` |
| `aws_lb_target_group_attachment` | No | Created when `targets` are defined on a target group |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Internet-facing ALB with VPC module integration

```hcl
load_balancers = {
  public = {
    name    = "my-company-public-alb-prod"
    vpc_key = "main"

    target_groups = {
      app = {
        port              = 80
        protocol          = "HTTP"
        target_type       = "ip"
        health_check_path = "/health"
      }
    }

    listeners = {
      http = {
        port     = 80
        protocol = "HTTP"
        default_action = {
          type             = "forward"
          target_group_key = "app"
        }
      }
    }

    tags = {
      Purpose = "public-alb"
    }
  }
}
```

When `vpc_key` is set, the environment stack automatically resolves `vpc_id` and public `subnet_ids` from the VPC module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | ALB name | `string` | — | yes |
| `vpc_id` | VPC ID | `string` | — | yes |
| `subnet_ids` | Subnet IDs (min 2 AZs) | `list(string)` | — | yes |
| `internal` | Internal ALB | `bool` | `false` | no |
| `create_security_group` | Create ALB security group | `bool` | `true` | no |
| `security_group_ids` | Existing security groups | `list(string)` | `[]` | no |
| `allowed_ingress_cidrs` | Allowed HTTP/HTTPS CIDRs | `list(string)` | `["0.0.0.0/0"]` | no |
| `target_groups` | Target group map | `map(object)` | — | yes |
| `listeners` | Listener map | `map(object)` | — | yes |
| `access_logs` | S3 access logs | `object` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `load_balancer_arn` | ALB ARN |
| `load_balancer_dns_name` | ALB DNS name |
| `load_balancer_zone_id` | Route 53 alias zone ID |
| `security_group_id` | ALB security group ID |
| `target_group_arns` | Target group ARNs by key |
| `listener_arns` | Listener ARNs by key |

## Design notes

- **Multi-AZ**: Requires at least two subnets (validated via `check` blocks).
- **Security group**: Defaults to HTTP/HTTPS inbound from `allowed_ingress_cidrs`.
- **VPC integration**: Use `vpc_key` in the environment stack to wire subnets from the VPC module.
- **Target types**: Supports `ip`, `instance`, `lambda`, and `alb` target types.
- **Listener actions**: `forward`, `redirect`, and `fixed-response` on default actions and rules.
- **Lambda targets**: Register Lambda as a target outside this module (requires `aws_lambda_permission`). Lambda target groups omit `vpc_id` automatically.
- **Target group names**: Truncated to 32 characters (AWS limit). Keep `name` + target group key short.
- **Security group**: Uses `name_prefix` with `create_before_destroy` for safer replacements.

## Common workflow

1. Apply VPC module first.
2. Apply ALB with `vpc_key = "main"`.
3. Register targets (EC2, ECS, IP) via `targets` or attach autoscaling separately.
4. Point Route 53 alias record to `load_balancer_dns_name`.
