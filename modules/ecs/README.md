# ECS Module

OpenTofu module to create an AWS ECS cluster with Fargate services, task definitions, CloudWatch logging, and optional ALB integration.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_ecs_cluster` | Yes | ECS cluster |
| `aws_ecs_cluster_capacity_providers` | No | When capacity providers are configured |
| `aws_cloudwatch_log_group` | Yes | One per service |
| `aws_ecs_task_definition` | Yes | One per service |
| `aws_ecs_service` | Yes | One per service |
| `aws_iam_role` | No | Execution role when `execution_role_arn` is null |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Fargate service with ECR image

```hcl
ecr_repositories = {
  api = { name = "my-company-api-prod" }
}

ecs_clusters = {
  main = {
    name                = "my-company-prod"
    vpc_key             = "main"
    subnet_keys         = ["az-a", "az-b"]
    security_group_keys = ["app"]

    services = {
      api = {
        desired_count = 2
        cpu           = 512
        memory        = 1024

        containers = {
          api = {
            ecr_repository_key = "api"
            image_tag          = "latest"
            port_mappings      = [{ container_port = 8080 }]
          }
        }
      }
    }
  }
}
```

### Service behind ALB

```hcl
services = {
  api = {
    desired_count = 2
    containers = {
      api = {
        ecr_repository_key = "api"
        port_mappings      = [{ container_port = 8080 }]
      }
    }
    target_group_attachments = [{
      alb_key          = "api"
      target_group_key = "api"
      container_name   = "api"
      container_port   = 8080
    }]
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Cluster name | `string` | — | yes |
| `subnet_ids` | Default service subnets | `list(string)` | `[]` | no |
| `security_group_ids` | Default service security groups | `list(string)` | `[]` | no |
| `execution_role_arn` | Task execution role ARN | `string` | `null` | no |
| `container_insights` | Enable Container Insights | `bool` | `true` | no |
| `capacity_providers` | Cluster capacity providers | `list(string)` | `["FARGATE", "FARGATE_SPOT"]` | no |
| `default_capacity_provider` | Default capacity provider | `string` | `"FARGATE"` | no |
| `services` | ECS services map | `map(object)` | — | yes |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ECS cluster ID |
| `cluster_arn` | ECS cluster ARN |
| `cluster_name` | ECS cluster name |
| `execution_role_arn` | Task execution role ARN |
| `service_arns` | Service ARNs by logical name |
| `service_names` | Service names by logical name |
| `task_definition_arns` | Task definition ARNs |
| `log_group_names` | CloudWatch log groups |

## Validation

The module includes check blocks for:

- At least one service
- Subnets and security groups per service
- Valid launch types and Fargate CPU/memory minimums
- Container images and load balancer container references
- Execution role name length when auto-created

## Environment wiring

In `environments/prod`, configure `ecs_clusters` with:

- `vpc_key` + `subnet_keys` for private subnets
- `security_group_keys` for task security groups
- `ecr_repository_key` on containers for image URLs
- `task_role_key` / `execution_role_key` for IAM roles
- `target_group_attachments` for ALB integration

## Related modules

- [ecr](../ecr/) — Container images
- [vpc](../vpc/) — Networking
- [security-group](../security-group/) — Task security groups
- [alb](../alb/) — Load balancer target groups
- [iam-role](../iam-role/) — Task and execution roles
- [eks](../eks/) — Alternative Kubernetes orchestration
