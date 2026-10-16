# API Gateway Module

OpenTofu module to create an AWS API Gateway **HTTP API** (API Gateway v2) with integrations, routes, stages, optional JWT/Lambda authorizers, custom domains, and VPC links.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_apigatewayv2_api` | Yes | HTTP or WebSocket API |
| `aws_apigatewayv2_integration` | Yes | One per integration in `integrations` |
| `aws_apigatewayv2_route` | Yes | One per route in `routes` |
| `aws_apigatewayv2_stage` | Yes | One per stage in `stages` |
| `aws_apigatewayv2_authorizer` | No | When `authorizers` is non-empty |
| `aws_apigatewayv2_domain_name` | No | When `domain` is set |
| `aws_apigatewayv2_api_mapping` | No | When `domain` is set |
| `aws_apigatewayv2_vpc_link` | No | When `vpc_link` is set |
| `aws_wafv2_web_acl_association` | No | Per stage when `web_acl_arn` is set |
| `aws_api_gateway_api_key` | No | When `api_keys` is non-empty (shared key resource for HTTP APIs) |
| `aws_lambda_permission` | No | For AWS_PROXY integrations and REQUEST Lambda authorizers |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Lambda proxy API (recommended pattern)

```hcl
api_gateways = {
  public-api = {
    name        = "my-company-public-api-prod"
    description = "Public HTTP API backed by Lambda"

    cors_configuration = {
      allow_methods = ["GET", "POST", "OPTIONS"]
      allow_origins = ["https://app.example.com"]
      allow_headers = ["content-type", "authorization"]
    }

    integrations = {
      lambda = {
        integration_type      = "AWS_PROXY"
        lambda_function_key = "api-handler"
      }
    }

    routes = {
      catch-all = {
        route_key       = "$default"
        integration_key = "lambda"
      }
      health = {
        route_key       = "GET /health"
        integration_key = "lambda"
      }
    }

    stages = {
      default = {
        name = "$default"
      }
    }

    tags = { Purpose = "public-api" }
  }
}
```

When `lambda_function_key` is set, the environment stack resolves `invoke_arn` and `function_name` from the Lambda module and creates the required `aws_lambda_permission`.

### ALB HTTP proxy (private via VPC link)

```hcl
api_gateways = {
  internal-api = {
    name = "my-company-internal-api-prod"

    vpc_link = {
      name        = "internal-alb-link"
      vpc_key     = "main"
      subnet_keys = ["az-a", "az-b"]
      security_group_keys = ["apigw-vpc-link"]
    }

    integrations = {
      alb = {
        integration_type    = "HTTP_PROXY"
        integration_method  = "ANY"
        load_balancer_key   = "public"
        connection_type     = "VPC_LINK"
      }
    }

    routes = {
      proxy = {
        route_key       = "ANY /{proxy+}"
        integration_key = "alb"
      }
    }

    stages = {
      default = { name = "$default" }
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | API name | `string` | — | yes |
| `description` | API description | `string` | `null` | no |
| `protocol_type` | `HTTP` or `WEBSOCKET` | `string` | `HTTP` | no |
| `disable_execute_api_endpoint` | Disable default execute-api endpoint | `bool` | `false` | no |
| `cors_configuration` | CORS settings (HTTP only) | `object` | `null` | no |
| `integrations` | Integrations keyed by logical name | `map(object)` | `{}` | yes |
| `routes` | Routes keyed by logical name | `map(object)` | `{}` | yes |
| `authorizers` | JWT or REQUEST authorizers | `map(object)` | `{}` | no |
| `stages` | Deployment stages | `map(object)` | — | yes |
| `domain` | Custom domain + mapping | `object` | `null` | no |
| `vpc_link` | VPC link for private integrations | `object` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

### Integration object

| Field | Description |
|-------|-------------|
| `integration_type` | `AWS_PROXY`, `HTTP_PROXY`, or `MOCK` |
| `integration_method` | HTTP method for HTTP_PROXY (default `POST`; use `ANY` for catch-all) |
| `integration_uri` | Target URI (required for non-MOCK unless wired via prod keys) |
| `lambda_function_name` | Lambda name for AWS_PROXY permissions |
| `connection_type` | `INTERNET` or `VPC_LINK` |
| `connection_id` | VPC link ID (optional when module creates `vpc_link`) |
| `payload_format_version` | `1.0` or `2.0` for Lambda proxy (default `2.0`) |
| `timeout_milliseconds` | Integration timeout (default 30000) |

### Route object

| Field | Description |
|-------|-------------|
| `route_key` | e.g. `GET /users`, `$default`, `$connect` |
| `integration_key` | Key from `integrations` |
| `authorization_type` | `NONE`, `AWS_IAM`, `JWT`, or `CUSTOM` |
| `authorizer_key` | Required for `JWT` and `CUSTOM` |

## Outputs

| Name | Description |
|------|-------------|
| `api_id` | API ID |
| `api_arn` | API ARN |
| `api_endpoint` | Default invoke URL base |
| `execution_arn` | Execution ARN for IAM/Lambda permissions |
| `stage_invoke_urls` | Invoke URLs per stage logical key |
| `integration_ids` | Integration IDs by key |
| `route_ids` | Route IDs by key |
| `authorizer_ids` | Authorizer IDs by key |
| `vpc_link_id` | VPC link ID when configured |
| `domain_name` | Custom domain when configured |
| `domain_name_target_domain_name` | Route 53 alias target |
| `domain_name_hosted_zone_id` | Route 53 hosted zone ID |

## Validation

The module includes **26 `check` blocks** for:

- Required integrations, routes, and stages
- Valid integration and route references
- Unique `route_key` values
- Authorization type / authorizer consistency
- CORS only on HTTP APIs (with required origins)
- JWT and REQUEST authorizer required fields
- VPC link connection and subnet count (2+ AZs)
- Custom domain stage reference and TLS policy
- Lambda payload format and integration timeouts
- Per-stage route throttling keys
- API key routes require defined keys

## Coverage matrix

| Capability | Supported | Notes |
|------------|-----------|-------|
| HTTP API | Yes | Primary target (API Gateway v2) |
| WebSocket API | Yes | Set `protocol_type = "WEBSOCKET"` |
| Lambda proxy (`AWS_PROXY`) | Yes | Auto `aws_lambda_permission` |
| HTTP proxy (`HTTP_PROXY`) | Yes | ALB/NLB via URI or `load_balancer_key` |
| MOCK integrations | Yes | URI not required |
| VPC link (private backends) | Yes | Min 2 subnets validated |
| JWT authorizers (Cognito/OIDC) | Yes | |
| Lambda REQUEST authorizers | Yes | Auto invoke permission |
| AWS IAM authorization | Yes | On routes |
| CORS | Yes | HTTP only |
| Custom domain + mapping | Yes | Regional ACM certificate |
| Stage throttling / metrics | Yes | Default and per-route |
| Access logging | Yes | Requires pre-created log destination ARN |
| WAF association | Yes | `web_acl_arn` per stage |
| API keys | Yes | `api_keys` + `api_key_required` on routes |
| REST API (v1) | No | Use a separate module if needed |
| Usage plans (REST-style) | No | Not applicable to HTTP APIs |
| Mutual TLS on custom domain | No | Not in scope |

## Environment wiring

In `environments/prod`, use `api_gateways` with cross-module keys:

| Key | Resolves to |
|-----|-------------|
| `lambda_function_key` | Lambda `invoke_arn` + permission `function_name` |
| `load_balancer_key` | ALB DNS name as `https://{dns}` |
| `vpc_link.vpc_key` + `subnet_keys` | Private subnet IDs from VPC module |
| `vpc_link.security_group_keys` | Security group IDs from SG module |

## Notes

- This module targets **HTTP APIs** (v2). For REST APIs (v1), use a separate module.
- Use stage name `$default` with `auto_deploy = true` for the simplest single-stage setup.
- ACM certificate for custom domains must be in the **same region** as the API (regional endpoint).
