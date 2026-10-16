output "cluster_id" {
  description = "ECS cluster ID."
  value       = aws_ecs_cluster.cluster.id
}

output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = aws_ecs_cluster.cluster.arn
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.cluster.name
}

output "execution_role_arn" {
  description = "Task execution role ARN used by services."
  value       = local.execution_role_arn
}

output "service_arns" {
  description = "ECS service ARNs keyed by logical name."
  value       = { for name, service in aws_ecs_service.service : name => service.arn }
}

output "service_names" {
  description = "ECS service names keyed by logical name."
  value       = { for name, service in aws_ecs_service.service : name => service.name }
}

output "task_definition_arns" {
  description = "Task definition ARNs keyed by logical name."
  value       = { for name, task in aws_ecs_task_definition.service : name => task.arn }
}

output "task_definition_families" {
  description = "Task definition families keyed by logical name."
  value       = { for name, task in aws_ecs_task_definition.service : name => task.family }
}

output "log_group_names" {
  description = "CloudWatch log group names keyed by service."
  value       = { for name, log_group in aws_cloudwatch_log_group.service : name => log_group.name }
}
