output "project_name" {
  description = "CodeBuild project name."
  value       = aws_codebuild_project.project.name
}

output "project_arn" {
  description = "CodeBuild project ARN."
  value       = aws_codebuild_project.project.arn
}

output "project_id" {
  description = "CodeBuild project ID."
  value       = aws_codebuild_project.project.id
}

output "service_role_arn" {
  description = "IAM service role ARN used by CodeBuild."
  value       = local.service_role_arn
}

output "service_role_name" {
  description = "IAM service role name when created by this module."
  value       = try(aws_iam_role.service[0].name, null)
}

output "log_group_name" {
  description = "CloudWatch log group name for build logs."
  value       = try(aws_cloudwatch_log_group.logs[0].name, local.log_group_name)
}

output "log_group_arn" {
  description = "CloudWatch log group ARN when created by this module."
  value       = try(aws_cloudwatch_log_group.logs[0].arn, null)
}

output "badge_url" {
  description = "Build badge URL when badge_enabled is true."
  value       = var.badge_enabled ? aws_codebuild_project.project.badge_url : null
}

output "webhook_url" {
  description = "Webhook URL when a webhook is configured."
  value       = try(aws_codebuild_webhook.webhook[0].payload_url, null)
}

output "webhook_secret" {
  description = "Webhook secret when a webhook is configured."
  value       = try(aws_codebuild_webhook.webhook[0].secret, null)
  sensitive   = true
}
