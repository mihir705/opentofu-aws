variable "name" {
  description = "Fixed name of the secret. Use name_prefix when AWS should append a random suffix."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Name prefix for the secret. AWS appends a random suffix. Mutually exclusive with name."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the secret."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ID or ARN for encrypting the secret. Uses the AWS managed key when null."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days AWS waits before deleting the secret. Use 0 for immediate deletion (no recovery)."
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 or between 7 and 30."
  }
}

variable "secret_string" {
  description = "Secret value as a UTF-8 string. Mutually exclusive with secret_binary and generate_random_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_binary" {
  description = "Secret value as base64-encoded binary data. Mutually exclusive with secret_string and generate_random_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "generate_random_password" {
  description = "Generate a random password and store it as the secret value. Mutually exclusive with secret_string and secret_binary."
  type = object({
    length           = optional(number, 32)
    special          = optional(bool, true)
    override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
    username         = optional(string, null)
  })
  default = null
}

variable "ignore_secret_changes" {
  description = "Ignore changes to secret values after initial creation. Useful when values are rotated outside Terraform."
  type        = bool
  default     = false
}

variable "rotation" {
  description = "Automatic rotation configuration. Requires a secret value. Set to null to disable."
  type = object({
    lambda_arn               = string
    automatically_after_days = optional(number, 30)
  })
  default = null
}

variable "resource_policy_json" {
  description = "Optional JSON resource policy attached to the secret."
  type        = string
  default     = null
}

variable "replica_regions" {
  description = "Regions where read replicas of the secret are created."
  type = list(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the secret."
  type        = map(string)
  default     = {}
}
