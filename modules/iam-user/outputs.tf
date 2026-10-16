output "user_name" {
  description = "IAM user name."
  value       = aws_iam_user.user.name
}

output "user_arn" {
  description = "IAM user ARN."
  value       = aws_iam_user.user.arn
}

output "user_unique_id" {
  description = "Stable unique ID for the IAM user."
  value       = aws_iam_user.user.unique_id
}

output "managed_policy_arns" {
  description = "Managed policy ARNs attached to the user."
  value       = values(local.managed_policy_attachments)
}

output "inline_policy_names" {
  description = "Inline policy names attached to the user."
  value = concat(
    length(var.policy_statements) > 0 ? [local.default_inline_policy_name] : [],
    keys(var.inline_policies)
  )
}

output "access_key_id" {
  description = "Access key ID when create_access_key is true."
  value       = try(aws_iam_access_key.access_key[0].id, null)
}

output "secret_access_key" {
  description = "Access key secret when create_access_key is true."
  value       = try(aws_iam_access_key.access_key[0].secret, null)
  sensitive   = true
}

output "encrypted_secret_access_key" {
  description = "PGP-encrypted access key secret when access_key_pgp_key is set."
  value       = try(aws_iam_access_key.access_key[0].encrypted_secret, null)
  sensitive   = true
}

output "login_profile_encrypted_password" {
  description = "PGP-encrypted console password when login_profile_pgp_key is set."
  value       = try(aws_iam_user_login_profile.login_profile[0].encrypted_password, null)
  sensitive   = true
}
