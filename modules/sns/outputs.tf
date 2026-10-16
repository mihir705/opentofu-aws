output "topic_id" {
  description = "SNS topic ID."
  value       = aws_sns_topic.topic.id
}

output "topic_arn" {
  description = "SNS topic ARN."
  value       = aws_sns_topic.topic.arn
}

output "topic_name" {
  description = "SNS topic name."
  value       = aws_sns_topic.topic.name
}

output "display_name" {
  description = "SNS topic display name."
  value       = aws_sns_topic.topic.display_name
}

output "fifo_topic" {
  description = "Whether the topic is FIFO."
  value       = aws_sns_topic.topic.fifo_topic
}

output "subscription_arns" {
  description = "Subscription ARNs keyed by logical name."
  value       = { for key, subscription in aws_sns_topic_subscription.subscription : key => subscription.arn }
}

output "subscription_ids" {
  description = "Subscription IDs keyed by logical name."
  value       = { for key, subscription in aws_sns_topic_subscription.subscription : key => subscription.id }
}

output "owner" {
  description = "AWS account ID that owns the topic."
  value       = aws_sns_topic.topic.owner
}
