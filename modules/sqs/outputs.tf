output "queue_id" {
  description = "SQS queue URL (ID)."
  value       = aws_sqs_queue.queue.id
}

output "queue_arn" {
  description = "SQS queue ARN."
  value       = aws_sqs_queue.queue.arn
}

output "queue_name" {
  description = "SQS queue name."
  value       = aws_sqs_queue.queue.name
}

output "queue_url" {
  description = "SQS queue URL."
  value       = aws_sqs_queue.queue.url
}

output "fifo_queue" {
  description = "Whether the queue is FIFO."
  value       = aws_sqs_queue.queue.fifo_queue
}

output "dlq_arn" {
  description = "Dead-letter queue ARN when create_dlq is true."
  value       = try(aws_sqs_queue.dlq[0].arn, null)
}

output "dlq_url" {
  description = "Dead-letter queue URL when create_dlq is true."
  value       = try(aws_sqs_queue.dlq[0].url, null)
}

output "dlq_name" {
  description = "Dead-letter queue name when create_dlq is true."
  value       = try(aws_sqs_queue.dlq[0].name, null)
}
