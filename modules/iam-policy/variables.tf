variable "name" {
  description = "IAM policy name. Required unless name_prefix is set."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || (length(var.name) >= 1 && length(var.name) <= 128)
    error_message = "name must be between 1 and 128 characters."
  }
}

variable "name_prefix" {
  description = "Creates a unique policy name with the given prefix. Cannot be combined with name."
  type        = string
  default     = null

  validation {
    condition     = var.name_prefix == null || (length(var.name_prefix) >= 1 && length(var.name_prefix) <= 96)
    error_message = "name_prefix must be between 1 and 96 characters."
  }
}

variable "description" {
  description = "IAM policy description."
  type        = string
  default     = null
}

variable "path" {
  description = "IAM path for the policy."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.path, "/") && endswith(var.path, "/")
    error_message = "path must start and end with '/'."
  }
}

variable "policy_json" {
  description = "Full IAM policy JSON. Cannot be combined with policy_statements."
  type        = string
  default     = null
}

variable "policy_statements" {
  description = "IAM policy statements merged into the policy document."
  type = list(object({
    sid           = optional(string)
    effect        = string
    actions       = optional(list(string), [])
    not_actions   = optional(list(string), [])
    resources     = optional(list(string), ["*"])
    not_resources = optional(list(string), [])
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the IAM policy."
  type        = map(string)
  default     = {}
}
