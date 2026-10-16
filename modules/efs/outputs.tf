output "file_system_id" {
  description = "EFS file system ID."
  value       = aws_efs_file_system.file_system.id
}

output "file_system_arn" {
  description = "EFS file system ARN."
  value       = aws_efs_file_system.file_system.arn
}

output "dns_name" {
  description = "DNS name for mounting the file system."
  value       = aws_efs_file_system.file_system.dns_name
}

output "size_in_bytes" {
  description = "Latest known metered size of the file system in bytes."
  value       = aws_efs_file_system.file_system.size_in_bytes
}

output "mount_target_ids" {
  description = "Mount target IDs keyed by subnet ID."
  value       = { for subnet_id, target in aws_efs_mount_target.mount_target : subnet_id => target.id }
}

output "mount_target_ips" {
  description = "Mount target IP addresses keyed by subnet ID."
  value       = { for subnet_id, target in aws_efs_mount_target.mount_target : subnet_id => target.ip_address }
}

output "access_point_arns" {
  description = "Access point ARNs keyed by logical name."
  value       = { for name, ap in aws_efs_access_point.access_point : name => ap.arn }
}

output "access_point_ids" {
  description = "Access point IDs keyed by logical name."
  value       = { for name, ap in aws_efs_access_point.access_point : name => ap.id }
}
