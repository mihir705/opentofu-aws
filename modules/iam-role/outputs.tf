output "role_name" {
  description = "IAM role name."
  value       = aws_iam_role.role.name
}

output "role_arn" {
  description = "IAM role ARN."
  value       = aws_iam_role.role.arn
}

output "role_id" {
  description = "IAM role ID."
  value       = aws_iam_role.role.id
}

output "role_unique_id" {
  description = "Stable unique ID for the IAM role."
  value       = aws_iam_role.role.unique_id
}

output "instance_profile_name" {
  description = "Instance profile name when create_instance_profile is true."
  value       = try(aws_iam_instance_profile.profile[0].name, null)
}

output "instance_profile_arn" {
  description = "Instance profile ARN when create_instance_profile is true."
  value       = try(aws_iam_instance_profile.profile[0].arn, null)
}

output "managed_policy_arns" {
  description = "Managed policy ARNs attached to the role."
  value       = values(local.managed_policy_attachments)
}

output "inline_policy_names" {
  description = "Inline policy names attached to the role."
  value = concat(
    length(var.policy_statements) > 0 ? [local.default_inline_policy_name] : [],
    keys(var.inline_policies)
  )
}
