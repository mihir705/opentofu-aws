output "repository_name" {
  description = "ECR repository name."
  value       = aws_ecr_repository.repository.name
}

output "repository_arn" {
  description = "ECR repository ARN."
  value       = aws_ecr_repository.repository.arn
}

output "repository_url" {
  description = "ECR repository URL for docker push/pull."
  value       = aws_ecr_repository.repository.repository_url
}

output "registry_id" {
  description = "AWS account ID that owns the repository."
  value       = aws_ecr_repository.repository.registry_id
}

output "image_tag_mutability" {
  description = "Image tag mutability setting."
  value       = aws_ecr_repository.repository.image_tag_mutability
}

output "scan_on_push" {
  description = "Whether image scanning on push is enabled."
  value       = aws_ecr_repository.repository.image_scanning_configuration[0].scan_on_push
}

output "encryption_type" {
  description = "Repository encryption type."
  value       = aws_ecr_repository.repository.encryption_configuration[0].encryption_type
}
