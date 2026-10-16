variable "name" {
  description = "IAM user name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "name must be between 1 and 64 characters."
  }
}

variable "path" {
  description = "IAM path for the user."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.path, "/") && endswith(var.path, "/")
    error_message = "path must start and end with '/'."
  }
}

variable "permissions_boundary" {
  description = "ARN of the permissions boundary policy."
  type        = string
  default     = null

  validation {
    condition = (
      var.permissions_boundary == null ||
      can(regex("^arn:aws:iam::[0-9]{12}:policy/", var.permissions_boundary))
    )
    error_message = "permissions_boundary must be a valid IAM customer-managed policy ARN."
  }
}

variable "force_destroy" {
  description = "Delete the user even when non-Terraform-managed access keys or inline policies exist."
  type        = bool
  default     = false
}

variable "managed_policy_arns" {
  description = "AWS managed or customer-managed policy ARNs to attach."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.managed_policy_arns :
      can(regex("^arn:aws:iam::(aws|[0-9]{12}):policy/", arn))
    ])
    error_message = "Each managed_policy_arns entry must be a valid IAM policy ARN."
  }
}

variable "managed_policy_key_arns" {
  description = "Customer-managed policy ARNs keyed by stable identifier (e.g. iam_policies map key). Values may be unknown until apply."
  type        = map(string)
  default     = {}
}

variable "policy_statements" {
  description = "Inline policy statements for the default user policy."
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

variable "inline_policies" {
  description = "Additional named inline policies keyed by policy name."
  type = map(object({
    policy_statements = list(object({
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
  }))
  default = {}
}

variable "create_access_key" {
  description = "Create an IAM access key for programmatic access."
  type        = bool
  default     = false
}

variable "access_key_status" {
  description = "Access key status: Active or Inactive."
  type        = string
  default     = "Active"

  validation {
    condition     = contains(["Active", "Inactive"], var.access_key_status)
    error_message = "access_key_status must be Active or Inactive."
  }
}

variable "access_key_pgp_key" {
  description = "PGP public key for encrypting the access key secret at creation."
  type        = string
  default     = null
}

variable "create_login_profile" {
  description = "Create a console login profile for the user."
  type        = bool
  default     = false
}

variable "login_profile_password_reset_required" {
  description = "Require password reset on first console sign-in."
  type        = bool
  default     = true
}

variable "login_profile_password_length" {
  description = "Generated console password length."
  type        = number
  default     = 20

  validation {
    condition     = var.login_profile_password_length >= 14 && var.login_profile_password_length <= 128
    error_message = "login_profile_password_length must be between 14 and 128."
  }
}

variable "login_profile_pgp_key" {
  description = "PGP public key for encrypting the generated console password."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
