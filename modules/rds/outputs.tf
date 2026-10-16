output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.instance.id
}

output "db_instance_arn" {
  description = "RDS instance ARN."
  value       = aws_db_instance.instance.arn
}

output "db_instance_endpoint" {
  description = "Connection endpoint hostname."
  value       = aws_db_instance.instance.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.instance.address
}

output "db_instance_port" {
  description = "Database port."
  value       = aws_db_instance.instance.port
}

output "db_instance_resource_id" {
  description = "RDS resource ID."
  value       = aws_db_instance.instance.resource_id
}

output "db_name" {
  description = "Database name."
  value       = aws_db_instance.instance.db_name
}

output "master_username" {
  description = "Master username."
  value       = aws_db_instance.instance.username
}

output "db_subnet_group_name" {
  description = "DB subnet group name."
  value       = local.db_subnet_group_name
}

output "parameter_group_name" {
  description = "DB parameter group name when created or referenced."
  value       = local.parameter_group_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master password when enabled."
  value       = try(aws_db_instance.instance.master_user_secret[0].secret_arn, null)
}

output "generated_password" {
  description = "Terraform-generated master password when generate_password is used."
  value       = try(random_password.master[0].result, null)
  sensitive   = true
}
