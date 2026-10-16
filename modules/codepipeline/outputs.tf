output "pipeline_name" {
  description = "CodePipeline name."
  value       = aws_codepipeline.pipeline.name
}

output "pipeline_arn" {
  description = "CodePipeline ARN."
  value       = aws_codepipeline.pipeline.arn
}

output "pipeline_id" {
  description = "CodePipeline ID."
  value       = aws_codepipeline.pipeline.id
}

output "service_role_arn" {
  description = "IAM service role ARN used by CodePipeline."
  value       = local.service_role_arn
}

output "service_role_name" {
  description = "IAM service role name when created by this module."
  value       = try(aws_iam_role.service[0].name, null)
}

output "artifact_bucket" {
  description = "S3 bucket used for pipeline artifacts."
  value       = local.artifact_bucket
}
