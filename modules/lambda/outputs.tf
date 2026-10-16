output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.function.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.function.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function."
  value       = aws_lambda_function.function.invoke_arn
}

output "qualified_arn" {
  description = "Qualified ARN including published version."
  value       = aws_lambda_function.function.qualified_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.execution.arn
}

output "role_name" {
  description = "Name of the Lambda execution role."
  value       = aws_iam_role.execution.name
}

output "log_group_name" {
  description = "CloudWatch log group name. Null when log group creation is disabled."
  value       = try(aws_cloudwatch_log_group.logs[0].name, null)
}

output "function_url" {
  description = "Function URL. Null when function URL is disabled."
  value       = try(aws_lambda_function_url.url[0].function_url, null)
}

output "event_source_mapping_uuids" {
  description = "Map of event source mapping names to UUIDs."
  value       = { for name, mapping in aws_lambda_event_source_mapping.source : name => mapping.uuid }
}
