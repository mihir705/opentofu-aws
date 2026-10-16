variable "description" {
  description = "Description of the KMS key."
  type        = string
  default     = null
}

variable "deletion_window_in_days" {
  description = "Waiting period before the key is deleted. Must be between 7 and 30."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation."
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Create a multi-Region primary key."
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "Region for a KMS replica key. Requires multi_region = true and the aws.replica provider."
  type        = string
  default     = null
}

variable "key_policy_json" {
  description = "Full custom KMS key policy JSON. Cannot be combined with policy_statements or allowed_services."
  type        = string
  default     = null
}

variable "allowed_services" {
  description = "AWS services to grant standard KMS usage. Supported values: s3, secretsmanager."
  type        = list(string)
  default     = []

  validation {
    condition     = length([for service in var.allowed_services : service if !contains(["s3", "secretsmanager"], service)]) == 0
    error_message = "allowed_services only supports: s3, secretsmanager."
  }
}

variable "policy_statements" {
  description = "Additional IAM policy statements merged into the default key policy."
  type = list(object({
    sid       = optional(string)
    effect    = string
    actions   = list(string)
    resources = optional(list(string), ["*"])
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

variable "aliases" {
  description = "Key aliases without the alias/ prefix."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the KMS key."
  type        = map(string)
  default     = {}
}
