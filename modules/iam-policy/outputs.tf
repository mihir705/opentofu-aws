output "policy_id" {
  description = "IAM policy ID."
  value       = aws_iam_policy.policy.id
}

output "policy_arn" {
  description = "IAM policy ARN."
  value       = aws_iam_policy.policy.arn
}

output "policy_name" {
  description = "IAM policy name."
  value       = aws_iam_policy.policy.name
}

output "policy_document" {
  description = "IAM policy JSON document."
  value       = aws_iam_policy.policy.policy
}
