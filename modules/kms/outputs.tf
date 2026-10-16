output "key_id" {
  description = "ID of the KMS key."
  value       = aws_kms_key.key.key_id
}

output "key_arn" {
  description = "ARN of the KMS key."
  value       = aws_kms_key.key.arn
}

output "key_rotation_enabled" {
  description = "Whether automatic key rotation is enabled."
  value       = aws_kms_key.key.enable_key_rotation
}

output "replica_key_arn" {
  description = "ARN of the replica key. Null when no replica is configured."
  value       = try(aws_kms_replica_key.replica[0].arn, null)
}

output "replica_key_id" {
  description = "ID of the replica key. Null when no replica is configured."
  value       = try(aws_kms_replica_key.replica[0].key_id, null)
}

output "alias_names" {
  description = "Map of input alias names to full alias names."
  value       = local.aliases
}

output "alias_arns" {
  description = "Map of input alias names to alias ARNs."
  value       = { for name, alias in aws_kms_alias.alias : name => alias.arn }
}
