output "user_pool_id" {
  description = "Cognito user pool ID."
  value       = aws_cognito_user_pool.pool.id
}

output "user_pool_arn" {
  description = "Cognito user pool ARN."
  value       = aws_cognito_user_pool.pool.arn
}

output "user_pool_endpoint" {
  description = "Cognito user pool endpoint."
  value       = aws_cognito_user_pool.pool.endpoint
}

output "client_ids" {
  description = "App client IDs keyed by logical name."
  value       = { for key, client in aws_cognito_user_pool_client.client : key => client.id }
}

output "client_secrets" {
  description = "App client secrets keyed by logical name when generate_secret is true."
  value       = { for key, client in aws_cognito_user_pool_client.client : key => client.client_secret }
  sensitive   = true
}

output "domain" {
  description = "Cognito hosted UI domain prefix or custom domain."
  value       = try(aws_cognito_user_pool_domain.domain[0].domain, null)
}

output "hosted_ui_base_url" {
  description = "Base URL for the Cognito hosted UI when a domain is configured."
  value = local.create_domain ? (
    local.domain_prefix != null ? format(
      "https://%s.auth.%s.amazoncognito.com",
      local.domain_prefix,
      data.aws_region.current.region
    ) : format("https://%s", var.domain.custom_domain)
  ) : null
}

output "identity_pool_id" {
  description = "Cognito identity pool ID when configured."
  value       = try(aws_cognito_identity_pool.identity[0].id, null)
}

output "identity_pool_arn" {
  description = "Cognito identity pool ARN when configured."
  value       = try(aws_cognito_identity_pool.identity[0].arn, null)
}
