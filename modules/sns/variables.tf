variable "name" {
  description = "SNS topic name. Required unless name_prefix is set. FIFO topics must end with .fifo."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || (length(var.name) >= 1 && length(var.name) <= 256)
    error_message = "name must be between 1 and 256 characters."
  }
}

variable "name_prefix" {
  description = "Creates a unique topic name with the given prefix. Cannot be combined with name."
  type        = string
  default     = null
}

variable "display_name" {
  description = "Display name for the topic shown in the AWS console."
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Whether the topic is FIFO. FIFO topic names must end with .fifo."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO topics."
  type        = bool
  default     = false
}

variable "fifo_throughput_scope" {
  description = "FIFO high-throughput scope: Topic or MessageGroup."
  type        = string
  default     = null
}

variable "archive_policy" {
  description = "JSON archive policy for FIFO topics (MessageRetentionPeriod in days)."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ID or ARN for server-side encryption."
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "JSON delivery policy for the topic."
  type        = string
  default     = null
}

variable "policy_json" {
  description = "Full SNS topic policy JSON. Cannot be combined with policy_statements."
  type        = string
  default     = null
}

variable "policy_statements" {
  description = "IAM policy statements merged into the default topic policy."
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

variable "subscriptions" {
  description = "Topic subscriptions keyed by logical name."
  type = map(object({
    protocol                        = string
    endpoint                        = optional(string)
    lambda_function_name            = optional(string)
    endpoint_auto_confirms          = optional(bool, false)
    confirmation_timeout_in_minutes = optional(number)
    raw_message_delivery            = optional(bool, false)
    filter_policy                   = optional(string)
    filter_policy_scope             = optional(string)
    redrive_policy                  = optional(string)
    subscription_role_arn           = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the SNS topic."
  type        = map(string)
  default     = {}
}
