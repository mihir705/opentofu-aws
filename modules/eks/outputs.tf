output "cluster_id" {
  description = "EKS cluster ID."
  value       = aws_eks_cluster.cluster.id
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.cluster.arn
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_version" {
  description = "Kubernetes control plane version."
  value       = aws_eks_cluster.cluster.version
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data."
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Cluster security group ID created by EKS."
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA."
  value       = try(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, null)
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN when create_oidc_provider is true."
  value       = try(aws_iam_openid_connect_provider.cluster[0].arn, null)
}

output "cluster_role_arn" {
  description = "IAM role ARN used by the EKS cluster."
  value       = local.cluster_role_arn
}

output "node_role_arn" {
  description = "IAM role ARN used by managed node groups."
  value       = local.node_role_arn
}

output "node_group_arns" {
  description = "Managed node group ARNs keyed by logical name."
  value       = { for key, group in aws_eks_node_group.node_group : key => group.arn }
}

output "node_group_statuses" {
  description = "Managed node group statuses keyed by logical name."
  value       = { for key, group in aws_eks_node_group.node_group : key => group.status }
}

output "addon_arns" {
  description = "EKS add-on ARNs keyed by add-on name."
  value       = { for key, addon in aws_eks_addon.addon : key => addon.arn }
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group for control plane logs."
  value       = try(aws_cloudwatch_log_group.cluster[0].name, null)
}
