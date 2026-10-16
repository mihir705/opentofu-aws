output "security_group_id" {
  description = "Security group ID."
  value       = aws_security_group.security_group.id
}

output "security_group_arn" {
  description = "Security group ARN."
  value       = aws_security_group.security_group.arn
}

output "security_group_name" {
  description = "Security group name."
  value       = aws_security_group.security_group.name
}

output "security_group_vpc_id" {
  description = "VPC ID the security group belongs to."
  value       = aws_security_group.security_group.vpc_id
}

output "ingress_rule_ids" {
  description = "Ingress rule IDs keyed by generated rule key."
  value       = { for key, rule in aws_vpc_security_group_ingress_rule.ingress : key => rule.id }
}

output "egress_rule_ids" {
  description = "Egress rule IDs keyed by generated rule key."
  value       = { for key, rule in aws_vpc_security_group_egress_rule.egress : key => rule.id }
}
