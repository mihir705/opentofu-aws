output "bucket_id" {
  description = "Name (ID) of the bucket."
  value       = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  description = "ARN of the bucket."
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name."
  value       = aws_s3_bucket.bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Bucket region-specific domain name."
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
}

output "bucket_region" {
  description = "AWS region of the bucket."
  value       = aws_s3_bucket.bucket.region
}

output "access_logging_enabled" {
  description = "Whether server access logging is enabled."
  value       = var.access_logging != null
}

output "access_logging_target_bucket" {
  description = "Target bucket for server access logs. Null when logging is disabled."
  value       = try(var.access_logging.target_bucket, null)
}
