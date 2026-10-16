variable "name" {
  description = "CodePipeline name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 100
    error_message = "name must be between 1 and 100 characters."
  }
}

variable "pipeline_type" {
  description = "Pipeline type. Use V2 for triggers and newer features."
  type        = string
  default     = "V2"

  validation {
    condition     = contains(["V1", "V2"], var.pipeline_type)
    error_message = "pipeline_type must be V1 or V2."
  }
}

variable "execution_mode" {
  description = "Execution mode for V2 pipelines."
  type        = string
  default     = "SUPERSEDED"

  validation {
    condition     = contains(["SUPERSEDED", "QUEUED", "PARALLEL"], var.execution_mode)
    error_message = "execution_mode must be SUPERSEDED, QUEUED, or PARALLEL."
  }
}

variable "artifact_bucket" {
  description = "S3 bucket name for pipeline artifacts."
  type        = string
}

variable "artifact_kms_key_arn" {
  description = "KMS key ARN for encrypting pipeline artifacts in S3."
  type        = string
  default     = null
}

variable "artifact_store_region" {
  description = "AWS region for the artifact store when using a cross-region bucket."
  type        = string
  default     = null
}

variable "secondary_artifact_stores" {
  description = "Additional regional artifact stores."
  type = list(object({
    location = string
    region   = string
    kms_key_arn = optional(string)
  }))
  default = []
}

variable "create_service_role" {
  description = "Create a dedicated IAM service role for CodePipeline."
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

variable "stages" {
  description = "Ordered pipeline stages and actions."
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string
      owner            = string
      provider         = string
      version          = string
      input_artifacts  = optional(list(string), [])
      output_artifacts = optional(list(string), [])
      role_arn         = optional(string)
      run_order        = optional(number)
      namespace        = optional(string)
      configuration    = map(string)
    }))
  }))
}

variable "trigger" {
  description = "V2 pipeline trigger configuration."
  type = object({
    provider_type = string
    git_configuration = object({
      source_action_name = string
      push = optional(list(object({
        branches = optional(object({
          includes = optional(list(string), [])
          excludes = optional(list(string), [])
        }))
        tags = optional(object({
          includes = optional(list(string), [])
          excludes = optional(list(string), [])
        }))
      })), [])
    })
  })
  default = null
}

variable "variables" {
  description = "Pipeline-level variables for V2 pipelines."
  type = list(object({
    name          = string
    default_value = string
    description   = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to CodePipeline resources."
  type        = map(string)
  default     = {}
}
