output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.distribution.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.distribution.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.distribution.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the CloudFront distribution."
  value       = aws_cloudfront_distribution.distribution.hosted_zone_id
}

output "distribution_status" {
  description = "CloudFront distribution deployment status."
  value       = aws_cloudfront_distribution.distribution.status
}

output "origin_access_control_id" {
  description = "Origin Access Control ID attached to the S3 origin."
  value       = aws_cloudfront_origin_access_control.origin.id
}

output "origin_bucket_id" {
  description = "S3 origin bucket ID."
  value       = local.origin_bucket_id
}

output "origin_bucket_arn" {
  description = "S3 origin bucket ARN."
  value       = local.origin_bucket_arn
}

output "origin_bucket_regional_domain_name" {
  description = "S3 origin bucket regional domain name."
  value       = local.origin_bucket_domain_name
}

output "origin_bucket_created" {
  description = "Whether this module created the origin bucket."
  value       = var.create_origin_bucket
}

output "origin_id" {
  description = "Origin ID used by the CloudFront distribution."
  value       = local.origin_id
}

output "spa_fallback_enabled" {
  description = "Whether SPA fallback error responses were applied."
  value       = var.spa_fallback
}

output "origin_bucket_policy_managed" {
  description = "Whether this module attached the CloudFront OAC bucket policy."
  value       = local.manage_origin_bucket_policy
}
