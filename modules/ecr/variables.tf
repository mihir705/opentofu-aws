variable "name" {
  description = "ECR repository name."
  type        = string

  validation {
    condition = (
      length(var.name) >= 2 && length(var.name) <= 256 &&
      can(regex("^[a-z0-9][a-z0-9._/-]*$", var.name))
    )
    error_message = "name must be 2-256 characters, lowercase, and start with a letter or number."
  }
}

variable "image_tag_mutability" {
  description = "Image tag mutability: MUTABLE or IMMUTABLE."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "Delete the repository even when it contains images."
  type        = bool
  default     = false
}

variable "encryption_type" {
  description = "Encryption type: AES256 or KMS."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "kms_key_id" {
  description = "KMS key ARN or ID for KMS encryption."
  type        = string
  default     = null
}

variable "scan_on_push" {
  description = "Enable image scanning on push."
  type        = bool
  default     = true
}

variable "policy_json" {
  description = "Full repository policy JSON. Cannot be combined with policy_statements."
  type        = string
  default     = null
}

variable "policy_statements" {
  description = "IAM policy statements merged into the repository policy."
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

variable "lifecycle_policy_json" {
  description = "Full lifecycle policy JSON. Cannot be combined with lifecycle_rules."
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Structured lifecycle rules."
  type = list(object({
    rule_priority   = number
    description     = optional(string)
    tag_status      = optional(string, "any")
    tag_prefix_list = optional(list(string), [])
    count_type      = string
    count_unit      = optional(string)
    count_number    = number
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the ECR repository."
  type        = map(string)
  default     = {}
}
