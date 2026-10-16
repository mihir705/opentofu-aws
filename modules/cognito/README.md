# Cognito Module

OpenTofu module to create an Amazon Cognito user pool with app clients, optional hosted UI domain, Lambda triggers, and optional identity pool for AWS credential federation.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_cognito_user_pool` | Yes | User directory and authentication |
| `aws_cognito_user_pool_client` | Yes | One per entry in `clients` |
| `aws_cognito_user_pool_domain` | No | Hosted UI prefix or custom domain |
| `aws_cognito_identity_pool` | No | Federated AWS credentials |
| `aws_cognito_identity_pool_roles_attachment` | No | IAM roles for identity pool |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Email sign-in with hosted UI

```hcl
cognito_user_pools = {
  app = {
    name = "my-company-app-prod"
    domain = {
      prefix = "my-company-app-prod"
    }
    clients = {
      web = {
        allowed_oauth_flows_user_pool_client = true
        allowed_oauth_flows                  = ["code"]
        allowed_oauth_scopes                 = ["email", "openid", "profile"]
        callback_urls                        = ["https://app.example.com/callback"]
        logout_urls                          = ["https://app.example.com/logout"]
      }
    }
  }
}
```

Use outputs for API Gateway JWT authorizers:

```hcl
# issuer = "https://cognito-idp.{region}.amazonaws.com/{user_pool_id}"
# audience = client_ids["web"]
```

### Identity pool with IAM roles

```hcl
iam_roles = {
  cognito-auth = {
    name           = "my-company-cognito-auth-prod"
    trust_services = ["cognito-identity.amazonaws.com"]
    policy_statements = [{
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::my-company-app-data-prod/*"]
    }]
  }
}

cognito_user_pools = {
  app = {
    name = "my-company-app-prod"
    clients = {
      mobile = {}
    }
    identity_pool = {
      name                   = "my-company-app-identity-prod"
      client_key             = "mobile"
      authenticated_role_key = "cognito-auth"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | User pool name | `string` | — | yes |
| `clients` | App clients keyed by logical name | `map(object)` | — | yes |
| `username_attributes` | `email` and/or `phone_number` | `list(string)` | `["email"]` | no |
| `auto_verified_attributes` | Attributes to auto-verify | `list(string)` | `["email"]` | no |
| `deletion_protection` | `ACTIVE` or `INACTIVE` | `string` | `"INACTIVE"` | no |
| `mfa_configuration` | `OFF`, `ON`, or `OPTIONAL` | `string` | `"OFF"` | no |
| `password_policy` | Password complexity rules | `object` | `{}` | no |
| `advanced_security_mode` | `OFF`, `AUDIT`, or `ENFORCED` | `string` | `"OFF"` | no |
| `email_configuration` | SES or Cognito default email | `object` | `null` | no |
| `lambda_config` | Lambda trigger ARNs | `object` | `{}` | no |
| `domain` | Hosted UI prefix or custom domain | `object` | `null` | no |
| `identity_pool` | Cognito identity pool | `object` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `user_pool_id` | Cognito user pool ID |
| `user_pool_arn` | User pool ARN |
| `user_pool_endpoint` | Provider endpoint for identity pools |
| `client_ids` | App client IDs by logical key |
| `client_secrets` | Client secrets (sensitive) |
| `domain` | Domain prefix or custom domain |
| `hosted_ui_base_url` | Hosted UI base URL when domain is set |
| `identity_pool_id` | Identity pool ID when configured |
| `identity_pool_arn` | Identity pool ARN when configured |

## Validation

The module includes `check` blocks for:

- At least one app client
- Domain prefix vs custom domain exclusivity
- Custom domain requires `certificate_arn`
- OAuth clients require `callback_urls`
- Identity pool `client_key` must exist in `clients`
- Supported `explicit_auth_flows` and `allowed_oauth_flows` values
