variable "function_name" {
  description = "Unique name for the Lambda function."
  type        = string
}

variable "role_name" {
  description = "IAM execution role name. Defaults to {function_name}-role when null."
  type        = string
  default     = null

  validation {
    condition     = var.role_name == null || (length(var.role_name) >= 1 && length(var.role_name) <= 64)
    error_message = "role_name must be between 1 and 64 characters."
  }
}

variable "description" {
  description = "Description of the Lambda function."
  type        = string
  default     = null
}

variable "package_type" {
  description = "Lambda deployment package type. Use Zip or Image."
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be Zip or Image."
  }
}

variable "runtime" {
  description = "Runtime for Zip packages. Required when package_type is Zip."
  type        = string
  default     = null
}

variable "handler" {
  description = "Handler entrypoint for Zip packages. Required when package_type is Zip."
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to a local deployment package for Zip functions."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment package for Zip functions."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment package for Zip functions."
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Optional S3 object version of the deployment package."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the Zip package. Required when using filename to detect code changes."
  type        = string
  default     = null
}

variable "image_uri" {
  description = "Container image URI for Image package type."
  type        = string
  default     = null
}

variable "memory_size" {
  description = "Memory allocated to the function in MB."
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240."
  }
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 3

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900."
  }
}

variable "architectures" {
  description = "Instruction set architectures for the function."
  type        = list(string)
  default     = ["x86_64"]

  validation {
    condition     = length(var.architectures) > 0 && alltrue([for arch in var.architectures : contains(["x86_64", "arm64"], arch)])
    error_message = "architectures must contain one or more of: x86_64, arm64."
  }
}

variable "environment_variables" {
  description = "Environment variables for the function."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting environment variables."
  type        = string
  default     = null
}

variable "layers" {
  description = "List of Lambda layer ARNs."
  type        = list(string)
  default     = []
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage size in MB."
  type        = number
  default     = 512

  validation {
    condition     = var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240
    error_message = "ephemeral_storage_size must be between 512 and 10240."
  }
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions. Set to -1 for unreserved."
  type        = number
  default     = null
}

variable "tracing_mode" {
  description = "X-Ray tracing mode. Use Active or PassThrough."
  type        = string
  default     = "PassThrough"

  validation {
    condition     = contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "tracing_mode must be Active or PassThrough."
  }
}

variable "vpc_config" {
  description = "VPC configuration for the function."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dead_letter_config" {
  description = "Dead letter queue or topic configuration."
  type = object({
    target_arn = string
  })
  default = null
}

variable "create_log_group" {
  description = "Create a CloudWatch log group for the function."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

variable "policy_statements" {
  description = "Additional IAM policy statements attached to the Lambda execution role."
  type = list(object({
    sid       = optional(string)
    effect    = string
    actions   = list(string)
    resources = optional(list(string), ["*"])
  }))
  default = []
}

variable "function_url" {
  description = "Function URL configuration. Set to null to disable."
  type = object({
    authorization_type = optional(string, "AWS_IAM")
    cors = optional(object({
      allow_credentials = optional(bool, false)
      allow_headers     = optional(list(string), [])
      allow_methods     = optional(list(string), [])
      allow_origins     = optional(list(string), [])
      expose_headers    = optional(list(string), [])
      max_age           = optional(number)
    }))
  })
  default = null
}

variable "event_source_mappings" {
  description = "Event source mappings for SQS queues or SNS topics."
  type = list(object({
    name                               = string
    event_source_arn                   = string
    batch_size                         = optional(number, 10)
    enabled                            = optional(bool, true)
    maximum_batching_window_in_seconds = optional(number)
    function_response_types            = optional(list(string), [])
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the Lambda function and IAM role."
  type        = map(string)
  default     = {}
}
