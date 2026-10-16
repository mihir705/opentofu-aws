# NLB Module

OpenTofu module to create an AWS Network Load Balancer with target groups, listeners, and optional target attachments.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_lb` | Yes | Network Load Balancer (`load_balancer_type = network`) |
| `aws_lb_target_group` | Yes | One per `target_groups` entry |
| `aws_lb_listener` | Yes | One per `listeners` entry (TCP, UDP, or TLS) |
| `aws_lb_target_group_attachment` | No | Created when `targets` are defined on a target group |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Internet-facing NLB with TCP listener

```hcl
network_load_balancers = {
  public = {
    name    = "my-company-public-nlb-prod"
    vpc_key = "main"

    target_groups = {
      app = {
        port        = 8080
        protocol    = "TCP"
        target_type = "ip"
      }
    }

    listeners = {
      tcp = {
        port             = 8080
        protocol         = "TCP"
        target_group_key = "app"
      }
    }

    tags = {
      Purpose = "public-nlb"
    }
  }
}
```

When `vpc_key` is set, the environment stack automatically resolves `vpc_id` and subnet IDs from the VPC module — **public subnets** for internet-facing NLBs and **private subnets** when `internal = true`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | NLB name | `string` | — | yes |
| `vpc_id` | VPC ID for target groups | `string` | — | yes |
| `subnet_ids` | Subnet IDs (min 2 AZs); omit when using `subnet_mappings` | `list(string)` | `[]` | no |
| `internal` | Internal NLB | `bool` | `false` | no |
| `ip_address_type` | `ipv4` or `dualstack` | `string` | `ipv4` | no |
| `security_group_ids` | Optional NLB security groups | `list(string)` | `[]` | no |
| `enable_cross_zone_load_balancing` | Cross-zone LB | `bool` | `true` | no |
| `subnet_mappings` | Static IP / EIP per subnet | `list(object)` | `[]` | no |
| `target_groups` | Target group map | `map(object)` | — | yes |
| `listeners` | Listener map | `map(object)` | — | yes |
| `access_logs` | S3 access logs | `object` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `load_balancer_arn` | NLB ARN |
| `load_balancer_dns_name` | NLB DNS name |
| `load_balancer_zone_id` | Route 53 zone ID for alias records |
| `target_group_arns` | Target group ARNs keyed by logical name |
| `listener_arns` | Listener ARNs keyed by logical name |

## Notes

- NLB listeners support **TCP**, **UDP**, and **TLS** (TLS requires `certificate_arn`).
- Target group protocols: **TCP**, **UDP**, **TLS**, or **TCP_UDP**.
- Target types: **instance**, **ip**, or **alb** (for chaining to an ALB).
- NLB uses **flow-hash routing** for TCP; `load_balancing_algorithm_type` is an ALB-only setting and is not used here.
- Use `subnet_mappings` instead of `subnet_ids` when you need static private IPs or Elastic IPs per AZ (minimum two mappings).
- NLB security groups are optional; attach via `security_group_ids` when you need L4 filtering.
- Combined NLB name and target group key must be **32 characters or fewer** (AWS target group name limit).
- `instance` target attachments require `availability_zone` on each target.
- HTTP/HTTPS health checks require `health_check_path`.
