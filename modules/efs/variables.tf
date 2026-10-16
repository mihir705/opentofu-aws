variable "name" {
  description = "EFS file system name used for tags and creation token."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "name must be between 1 and 64 characters."
  }
}

variable "performance_mode" {
  description = "Performance mode: generalPurpose or maxIO."
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "performance_mode must be generalPurpose or maxIO."
  }
}

variable "throughput_mode" {
  description = "Throughput mode: bursting, provisioned, or elastic."
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "throughput_mode must be bursting, provisioned, or elastic."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiB/s when throughput_mode is provisioned."
  type        = number
  default     = null
}

variable "encrypted" {
  description = "Enable encryption at rest."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN or ID for encryption."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for mount targets (one per AZ)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for mount targets (NFS port 2049)."
  type        = list(string)
}

variable "lifecycle_policy" {
  description = "Lifecycle management policy for the file system."
  type = object({
    transition_to_ia                    = optional(string)
    transition_to_archive               = optional(string)
    transition_to_primary_storage_class = optional(string)
  })
  default = null
}

variable "enable_backup_policy" {
  description = "Manage the AWS Backup policy for the file system."
  type        = bool
  default     = false
}

variable "backup_policy_status" {
  description = "AWS Backup policy status: ENABLED or DISABLED."
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.backup_policy_status)
    error_message = "backup_policy_status must be ENABLED or DISABLED."
  }
}

variable "access_points" {
  description = "EFS access points keyed by logical name."
  type = map(object({
    path = string
    posix_user = optional(object({
      uid = number
      gid = number
    }))
    creation_info = optional(object({
      owner_uid   = number
      owner_gid   = number
      permissions = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to EFS resources."
  type        = map(string)
  default     = {}
}
