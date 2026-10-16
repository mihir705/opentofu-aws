output "cluster_arn" {
  description = "MSK cluster ARN."
  value       = aws_msk_cluster.cluster.arn
}

output "cluster_name" {
  description = "MSK cluster name."
  value       = aws_msk_cluster.cluster.cluster_name
}

output "cluster_uuid" {
  description = "MSK cluster UUID."
  value       = aws_msk_cluster.cluster.cluster_uuid
}

output "current_version" {
  description = "Current cluster version."
  value       = aws_msk_cluster.cluster.current_version
}

output "bootstrap_brokers" {
  description = "Plaintext connection host:port pairs."
  value       = aws_msk_cluster.cluster.bootstrap_brokers
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs."
  value       = aws_msk_cluster.cluster.bootstrap_brokers_tls
}

output "bootstrap_brokers_sasl_scram" {
  description = "SASL/SCRAM connection host:port pairs."
  value       = aws_msk_cluster.cluster.bootstrap_brokers_sasl_scram
}

output "bootstrap_brokers_sasl_iam" {
  description = "SASL/IAM connection host:port pairs."
  value       = aws_msk_cluster.cluster.bootstrap_brokers_sasl_iam
}

output "bootstrap_brokers_public_tls" {
  description = "Public TLS connection host:port pairs when public access is enabled."
  value       = aws_msk_cluster.cluster.bootstrap_brokers_public_tls
}

output "zookeeper_connect_string" {
  description = "ZooKeeper connection string."
  value       = aws_msk_cluster.cluster.zookeeper_connect_string
}

output "zookeeper_connect_string_tls" {
  description = "TLS ZooKeeper connection string."
  value       = aws_msk_cluster.cluster.zookeeper_connect_string_tls
}

output "configuration_arn" {
  description = "MSK configuration ARN when created or attached."
  value       = try(aws_msk_configuration.this[0].arn, try(var.configuration.arn, null))
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name when broker logging to CloudWatch is enabled."
  value       = try(local.cloudwatch_log_group_name, null)
}
