variable "identifier" {
  description = "RDS instance identifier."
  type        = string

  validation {
    condition     = length(var.identifier) >= 1 && length(var.identifier) <= 63
    error_message = "identifier must be between 1 and 63 characters."
  }
}

variable "engine" {
  description = "Database engine. Supported values: mysql, postgres, mariadb, sqlserver-ex, sqlserver-se, sqlserver-ee, sqlserver-web, oracle-ee, oracle-se2."
  type        = string

  validation {
    condition = contains([
      "mysql",
      "postgres",
      "mariadb",
      "sqlserver-ex",
      "sqlserver-se",
      "sqlserver-ee",
      "sqlserver-web",
      "oracle-ee",
      "oracle-se2",
    ], var.engine)
    error_message = "engine must be a supported RDS engine."
  }
}

variable "engine_version" {
  description = "Engine version to run. Required unless engine_version_lookup is set."
  type        = string
  default     = null
}

variable "engine_version_lookup" {
  description = "Resolve engine version from the current AWS region. Cannot be combined with engine_version."
  type = object({
    version = string
    latest  = optional(bool, true)
  })
  default = null
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GiB."
  type        = number

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling. Set to 0 to disable."
  type        = number
  default     = 0

  validation {
    condition     = var.max_allocated_storage == 0 || var.max_allocated_storage >= var.allocated_storage
    error_message = "max_allocated_storage must be greater than or equal to allocated_storage when enabled."
  }
}

variable "storage_type" {
  description = "Storage type: gp2, gp3, io1, or standard."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "standard"], var.storage_type)
    error_message = "storage_type must be gp2, gp3, io1, or standard."
  }
}

variable "iops" {
  description = "Provisioned IOPS for io1/gp3 storage."
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Storage throughput for gp3."
  type        = number
  default     = null
}

variable "db_name" {
  description = "Initial database name. Not supported for all engines."
  type        = string
  default     = null
}

variable "username" {
  description = "Master username."
  type        = string
}

variable "password" {
  description = "Master password. Omit when using manage_master_user_password or generate_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master password in AWS Secrets Manager."
  type        = bool
  default     = false
}

variable "generate_password" {
  description = "Generate a random master password in Terraform. Cannot be combined with password or manage_master_user_password."
  type = object({
    length           = optional(number, 32)
    special          = optional(bool, true)
    override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
  })
  default = null
}

variable "port" {
  description = "Database port. Defaults to the engine default when omitted."
  type        = number
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group. Requires at least two subnets in different AZs."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for subnet_id in var.subnet_ids :
      can(regex("^subnet-[0-9a-f]+$", subnet_id))
    ])
    error_message = "Each subnet_id must be a valid subnet ID."
  }
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs attached to the RDS instance."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.vpc_security_group_ids) <= 5
    error_message = "A maximum of 5 security groups can be attached to an RDS instance."
  }
}

variable "db_subnet_group_name" {
  description = "Existing DB subnet group name. Required when create_db_subnet_group is false."
  type        = string
  default     = null
}

variable "create_db_subnet_group" {
  description = "Create a DB subnet group from subnet_ids."
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Existing DB parameter group name."
  type        = string
  default     = null
}

variable "create_parameter_group" {
  description = "Create a DB parameter group from parameters."
  type        = bool
  default     = false
}

variable "parameter_group_family" {
  description = "Parameter group family. Required when create_parameter_group is true."
  type        = string
  default     = null
}

variable "parameters" {
  description = "DB parameters applied when create_parameter_group is true."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the instance is publicly accessible."
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Enable storage encryption."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN or ID for storage encryption."
  type        = string
  default     = null

  validation {
    condition = (
      var.kms_key_id == null ||
      can(regex("^arn:aws:kms:", var.kms_key_id)) ||
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.kms_key_id))
    )
    error_message = "kms_key_id must be a valid KMS key ARN or key ID."
  }
}

variable "backup_retention_period" {
  description = "Backup retention period in days."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35."
  }
}

variable "backup_window" {
  description = "Preferred backup window."
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "Preferred maintenance window."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier when skip_final_snapshot is false."
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Apply changes immediately."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor engine version upgrades."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. Set to 0 to disable."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for enhanced monitoring."
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch."
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ARN or ID for Performance Insights."
  type        = string
  default     = null

  validation {
    condition = (
      var.performance_insights_kms_key_id == null ||
      can(regex("^arn:aws:kms:", var.performance_insights_kms_key_id)) ||
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.performance_insights_kms_key_id))
    )
    error_message = "performance_insights_kms_key_id must be a valid KMS key ARN or key ID."
  }
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days."
  type        = number
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy instance tags to snapshots."
  type        = bool
  default     = true
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication."
  type        = bool
  default     = false
}

variable "ca_cert_identifier" {
  description = "CA certificate identifier for the DB instance."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to RDS resources."
  type        = map(string)
  default     = {}
}
