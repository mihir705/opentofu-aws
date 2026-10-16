output "load_balancer_id" {
  description = "ALB ID."
  value       = aws_lb.load_balancer.id
}

output "load_balancer_arn" {
  description = "ALB ARN."
  value       = aws_lb.load_balancer.arn
}

output "load_balancer_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics."
  value       = aws_lb.load_balancer.arn_suffix
}

output "load_balancer_dns_name" {
  description = "ALB DNS name."
  value       = aws_lb.load_balancer.dns_name
}

output "load_balancer_zone_id" {
  description = "Route 53 zone ID for the ALB DNS name."
  value       = aws_lb.load_balancer.zone_id
}

output "security_group_id" {
  description = "ALB security group ID. Null when create_security_group is false."
  value       = try(aws_security_group.alb[0].id, null)
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

output "listener_rule_arns" {
  description = "Listener rule ARNs keyed by listener-rule name."
  value       = { for key, rule in aws_lb_listener_rule.rule : key => rule.arn }
}
