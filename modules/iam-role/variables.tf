variable "name" {
  description = "IAM role name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "name must be between 1 and 64 characters."
  }
}

variable "description" {
  description = "IAM role description."
  type        = string
  default     = null
}

variable "path" {
  description = "IAM path for the role and optional instance profile."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.path, "/") && endswith(var.path, "/")
    error_message = "path must start and end with '/'."
  }
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
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

variable "force_detach_policies" {
  description = "Detach managed policies before deleting the role."
  type        = bool
  default     = false
}

variable "assume_role_policy_json" {
  description = "Full assume-role policy JSON. Cannot be combined with trust_services, trust_principals, or assume_role_conditions."
  type        = string
  default     = null
}

variable "trust_services" {
  description = "AWS service principals allowed to assume the role (e.g. lambda.amazonaws.com)."
  type        = list(string)
  default     = []
}

variable "trust_principals" {
  description = "Custom principal blocks for the trust policy."
  type = list(object({
    type        = string
    identifiers = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for principal in var.trust_principals :
      contains(["AWS", "Service", "Federated", "CanonicalUser"], principal.type)
    ])
    error_message = "trust_principals.type must be one of: AWS, Service, Federated, CanonicalUser."
  }
}

variable "assume_role_actions" {
  description = "STS actions allowed in the trust policy."
  type        = list(string)
  default     = ["sts:AssumeRole"]

  validation {
    condition     = length(var.assume_role_actions) > 0
    error_message = "assume_role_actions must contain at least one action."
  }
}

variable "assume_role_conditions" {
  description = "Conditions applied to the trust_services statement only."
  type = list(object({
    test     = string
    variable = string
    values   = list(string)
  }))
  default = []
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
  description = "Inline policy statements for the default role policy."
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

variable "create_instance_profile" {
  description = "Create an IAM instance profile for EC2 instances."
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "Instance profile name. Defaults to the role name."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
