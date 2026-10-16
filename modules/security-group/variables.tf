variable "name" {
  description = "Name prefix for the security group. AWS appends a unique suffix."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 128
    error_message = "name must be between 1 and 128 characters."
  }
}

variable "vpc_id" {
  description = "VPC ID where the security group is created."
  type        = string
}

variable "description" {
  description = "Security group description."
  type        = string
  default     = null
}

variable "revoke_rules_on_delete" {
  description = "Revoke all attached ingress and egress rules before deleting the security group."
  type        = bool
  default     = true
}

variable "ingress_rules" {
  description = "Ingress rules for the security group."
  type = list(object({
    description                  = optional(string)
    protocol                     = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_blocks                  = optional(list(string), [])
    ipv6_cidr_blocks             = optional(list(string), [])
    prefix_list_ids              = optional(list(string), [])
    referenced_security_group_id = optional(string)
    self_reference               = optional(bool, false)
  }))
  default = []
}

variable "egress_rules" {
  description = "Egress rules for the security group. Defaults to allow all outbound IPv4 traffic."
  type = list(object({
    description                  = optional(string)
    protocol                     = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_blocks                  = optional(list(string), [])
    ipv6_cidr_blocks             = optional(list(string), [])
    prefix_list_ids              = optional(list(string), [])
    referenced_security_group_id = optional(string)
    self_reference               = optional(bool, false)
  }))
  default = null
}

variable "tags" {
  description = "Tags applied to the security group."
  type        = map(string)
  default     = {}
}
