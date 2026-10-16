variable "name" {
  description = "CodeBuild project name."
  type        = string

  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 255
    error_message = "name must be between 2 and 255 characters."
  }
}

variable "description" {
  description = "CodeBuild project description."
  type        = string
  default     = null
}

variable "build_timeout" {
  description = "Build timeout in minutes."
  type        = number
  default     = 60

  validation {
    condition     = var.build_timeout >= 5 && var.build_timeout <= 2160
    error_message = "build_timeout must be between 5 and 2160 minutes."
  }
}

variable "queued_timeout" {
  description = "Queued timeout in minutes. Set to 0 to disable."
  type        = number
  default     = 480

  validation {
    condition     = var.queued_timeout >= 0 && var.queued_timeout <= 480
    error_message = "queued_timeout must be between 0 and 480 minutes."
  }
}

variable "concurrent_build_limit" {
  description = "Maximum concurrent builds for the project."
  type        = number
  default     = null
}

variable "badge_enabled" {
  description = "Enable the build badge for the project."
  type        = bool
  default     = false
}

variable "encryption_key" {
  description = "KMS key ARN for encrypting build artifacts."
  type        = string
  default     = null
}

variable "create_service_role" {
  description = "Create a dedicated IAM service role for CodeBuild."
  type        = bool
  default     = true
}

variable "service_role_arn" {
  description = "Existing IAM role ARN. Required when create_service_role is false."
  type        = string
  default     = null
}

variable "role_name" {
  description = "IAM role name when create_service_role is true."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Additional managed IAM policy ARNs attached to the service role."
  type        = list(string)
  default     = []
}

variable "policy_statements" {
  description = "Additional IAM policy statements attached to the service role."
  type = list(object({
    sid       = optional(string)
    effect    = string
    actions   = list(string)
    resources = optional(list(string), ["*"])
  }))
  default = []
}

variable "create_log_group" {
  description = "Create a CloudWatch log group for CodeBuild logs."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

variable "buildspec" {
  description = "Buildspec definition. Required when source type is NO_SOURCE."
  type        = string
  default     = null
}

variable "source_version" {
  description = "Git branch, tag, or commit to build."
  type        = string
  default     = null
}

variable "source_config" {
  description = "Source configuration for the build."
  type = object({
    type                 = string
    location             = optional(string)
    buildspec            = optional(string)
    git_clone_depth      = optional(number, 1)
    insecure_ssl         = optional(bool, false)
    report_build_status  = optional(bool, false)
    fetch_submodules     = optional(bool, false)
    auth = optional(object({
      type     = string
      resource = optional(string)
    }))
  })
}

variable "artifacts" {
  description = "Artifact output configuration."
  type = object({
    type                   = string
    location               = optional(string)
    path                   = optional(string)
    namespace_type         = optional(string)
    packaging              = optional(string)
    encryption_disabled    = optional(bool, false)
    override_artifact_name = optional(bool, false)
    artifact_identifier    = optional(string)
    name                   = optional(string)
  })
  default = {
    type = "NO_ARTIFACTS"
  }
}

variable "cache" {
  description = "Cache configuration. Set to null to disable."
  type = object({
    type     = string
    location = optional(string)
    modes    = optional(list(string), [])
  })
  default = null
}

variable "environment" {
  description = "Build environment configuration."
  type = object({
    compute_type                = optional(string, "BUILD_GENERAL1_SMALL")
    image                       = string
    type                        = optional(string, "LINUX_CONTAINER")
    privileged_mode             = optional(bool, false)
    image_pull_credentials_type = optional(string, "CODEBUILD")
    certificate                 = optional(string)
    registry_credential = optional(object({
      credential          = string
      credential_provider = string
    }))
    environment_variables = optional(list(object({
      name  = string
      value = string
      type  = optional(string, "PLAINTEXT")
    })), [])
  })
}

variable "logs_config" {
  description = "CloudWatch and S3 logging configuration."
  type = object({
    cloudwatch_logs = optional(object({
      group_name  = optional(string)
      stream_name = optional(string)
      status      = optional(string, "ENABLED")
    }))
    s3_logs = optional(object({
      status              = optional(string, "DISABLED")
      location            = optional(string)
      encryption_disabled = optional(bool, false)
      bucket_owner_access = optional(string)
    }))
  })
  default = {
    cloudwatch_logs = {
      status = "ENABLED"
    }
  }
}

variable "vpc_config" {
  description = "VPC configuration for builds that need private network access."
  type = object({
    vpc_id             = string
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "webhook" {
  description = "Git webhook configuration. Supported for GitHub and Bitbucket sources."
  type = object({
    build_type = optional(string, "BUILD")
    filter_groups = optional(list(list(object({
      type    = string
      pattern = string
      exclude_matched_pattern = optional(bool)
    }))), [])
  })
  default = null
}

variable "file_system_locations" {
  description = "EFS file system locations mounted into the build container."
  type = list(object({
    identifier  = string
    location    = string
    mount_point = string
    type        = optional(string, "EFS")
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to CodeBuild resources."
  type        = map(string)
  default     = {}
}
