output "load_balancer_id" {
  description = "NLB ID."
  value       = aws_lb.load_balancer.id
}

output "load_balancer_arn" {
  description = "NLB ARN."
  value       = aws_lb.load_balancer.arn
}

output "load_balancer_arn_suffix" {
  description = "NLB ARN suffix for CloudWatch metrics."
  value       = aws_lb.load_balancer.arn_suffix
}

output "load_balancer_dns_name" {
  description = "NLB DNS name."
  value       = aws_lb.load_balancer.dns_name
}

output "load_balancer_zone_id" {
  description = "Route 53 zone ID for the NLB DNS name."
  value       = aws_lb.load_balancer.zone_id
}

output "target_group_arns" {
  description = "Target group ARNs keyed by logical name."
  value       = { for key, tg in aws_lb_target_group.target_group : key => tg.arn }
}

output "target_group_names" {
  description = "Target group names keyed by logical name."
  value       = { for key, tg in aws_lb_target_group.target_group : key => tg.name }
}

output "listener_arns" {
  description = "Listener ARNs keyed by logical name."
  value       = { for key, listener in aws_lb_listener.listener : key => listener.arn }
}

output "cross_zone_load_balancing_enabled" {
  description = "Whether cross-zone load balancing is enabled."
  value       = var.enable_cross_zone_load_balancing
}
