output "api_id" {
  description = "API Gateway API ID."
  value       = aws_apigatewayv2_api.api.id
}

output "api_arn" {
  description = "API Gateway API ARN."
  value       = aws_apigatewayv2_api.api.arn
}

output "api_endpoint" {
  description = "Default invoke URL for the API."
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "execution_arn" {
  description = "API execution ARN for IAM policies and Lambda permissions."
  value       = aws_apigatewayv2_api.api.execution_arn
}

output "stage_invoke_urls" {
  description = "Invoke URLs keyed by stage logical name."
  value = {
    for key, stage in aws_apigatewayv2_stage.stage :
    key => stage.invoke_url
  }
}

output "stage_ids" {
  description = "Stage IDs keyed by logical name."
  value       = { for key, stage in aws_apigatewayv2_stage.stage : key => stage.id }
}

output "integration_ids" {
  description = "Integration IDs keyed by logical name."
  value       = { for key, integration in aws_apigatewayv2_integration.integration : key => integration.id }
}

output "route_ids" {
  description = "Route IDs keyed by logical name."
  value       = { for key, route in aws_apigatewayv2_route.route : key => route.id }
}

output "authorizer_ids" {
  description = "Authorizer IDs keyed by logical name."
  value       = { for key, authorizer in aws_apigatewayv2_authorizer.authorizer : key => authorizer.id }
}

output "vpc_link_id" {
  description = "VPC link ID when vpc_link is configured."
  value       = try(aws_apigatewayv2_vpc_link.this[0].id, null)
}

output "domain_name" {
  description = "Custom domain name when configured."
  value       = try(aws_apigatewayv2_domain_name.domain[0].domain_name, null)
}

output "domain_name_target_domain_name" {
  description = "Target domain name for Route 53 alias records."
  value       = try(aws_apigatewayv2_domain_name.domain[0].domain_name_configuration[0].target_domain_name, null)
}

output "domain_name_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the custom domain."
  value       = try(aws_apigatewayv2_domain_name.domain[0].domain_name_configuration[0].hosted_zone_id, null)
}

output "api_key_ids" {
  description = "API key IDs keyed by logical name."
  value       = { for key, api_key in aws_api_gateway_api_key.api_key : key => api_key.id }
}

output "api_key_values" {
  description = "API key values keyed by logical name. Treat as sensitive."
  value       = { for key, api_key in aws_api_gateway_api_key.api_key : key => api_key.value }
  sensitive   = true
}
