variable "name" {
  description = "SQS queue name. Required unless name_prefix is set. FIFO queues must end with .fifo."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || (length(var.name) >= 1 && length(var.name) <= 80)
    error_message = "name must be between 1 and 80 characters."
  }
}

variable "name_prefix" {
  description = "Creates a unique queue name with the given prefix. Cannot be combined with name."
  type        = string
  default     = null
}

variable "fifo_queue" {
  description = "Whether the queue is FIFO. FIFO queue names must end with .fifo."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO queues."
  type        = bool
  default     = false
}

variable "deduplication_scope" {
  description = "FIFO deduplication scope: messageGroup or queue."
  type        = string
  default     = null
}

variable "fifo_throughput_limit" {
  description = "FIFO throughput limit: perQueue or perMessageGroupId."
  type        = string
  default     = null
}

variable "delay_seconds" {
  description = "Delay before messages become available (0–900)."
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024–262144)."
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "Message retention in seconds (60–1209600)."
  type        = number
  default     = 345600
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time in seconds (0–20)."
  type        = number
  default     = 0
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds (0–43200)."
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ID or ARN for server-side encryption."
  type        = string
  default     = null
}

variable "sqs_managed_sse_enabled" {
  description = "Enable SQS-managed server-side encryption (SSE-SQS). Ignored when kms_key_id is set."
  type        = bool
  default     = true
}

variable "kms_data_key_reuse_period_seconds" {
  description = "KMS data key reuse period in seconds (60–86400)."
  type        = number
  default     = null
}

variable "create_dlq" {
  description = "Create a dead-letter queue and attach a redrive policy."
  type        = bool
  default     = false
}

variable "dlq_name" {
  description = "Dead-letter queue name. Auto-derived from name when create_dlq is true."
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "Max receives before a message is sent to the DLQ."
  type        = number
  default     = 3
}

variable "redrive_policy" {
  description = "Custom redrive policy JSON. Cannot be combined with create_dlq."
  type        = string
  default     = null
}

variable "redrive_allow_policy" {
  description = "JSON redrive allow policy for use as a dead-letter target."
  type        = string
  default     = null
}

variable "policy_json" {
  description = "Full queue policy JSON. Cannot be combined with policy_statements."
  type        = string
  default     = null
}

variable "policy_statements" {
  description = "IAM policy statements merged into the default queue policy."
  type = list(object({
    sid       = optional(string)
    effect    = string
    actions   = list(string)
    resources = optional(list(string), [])
    principals = object({
      type        = string
      identifiers = list(string)
    })
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []
}

variable "allowed_sns_topic_arns" {
  description = "SNS topic ARNs allowed to send messages to this queue."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the queue."
  type        = map(string)
  default     = {}
}
