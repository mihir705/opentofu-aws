variable "name" {
  description = "ECS cluster name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 255
    error_message = "name must be between 1 and 255 characters."
  }
}

variable "subnet_ids" {
  description = "Default subnet IDs for services using awsvpc network mode."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Default security group IDs for services."
  type        = list(string)
  default     = []
}

variable "execution_role_arn" {
  description = "Default task execution role ARN. Created automatically when null."
  type        = string
  default     = null
}

variable "container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster."
  type        = bool
  default     = true
}

variable "capacity_providers" {
  description = "Capacity providers to associate with the cluster."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider" {
  description = "Default capacity provider name for the cluster."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT"], var.default_capacity_provider)
    error_message = "default_capacity_provider must be FARGATE or FARGATE_SPOT."
  }
}

variable "services" {
  description = "ECS services keyed by logical name."
  type = map(object({
    desired_count = number
    launch_type   = optional(string, "FARGATE")
    cpu           = optional(number, 256)
    memory        = optional(number, 512)
    execution_role_arn = optional(string)
    task_role_arn      = optional(string)
    platform_version   = optional(string, "LATEST")
    assign_public_ip   = optional(bool, false)
    enable_execute_command = optional(bool, false)
    deployment_minimum_healthy_percent = optional(number, 100)
    deployment_maximum_percent         = optional(number, 200)
    health_check_grace_period_seconds  = optional(number)
    subnet_ids         = optional(list(string))
    security_group_ids = optional(list(string))
    log_retention_in_days = optional(number, 30)
    containers = map(object({
      image       = string
      essential   = optional(bool, true)
      cpu         = optional(number)
      memory      = optional(number)
      command     = optional(list(string))
      entry_point = optional(list(string))
      environment = optional(map(string), {})
      secrets = optional(list(object({
        name       = string
        value_from = string
      })), [])
      port_mappings = optional(list(object({
        container_port = number
        host_port      = optional(number)
        protocol       = optional(string, "tcp")
      })), [])
    }))
    load_balancers = optional(list(object({
      target_group_arn = string
      container_name   = string
      container_port   = number
    })), [])
  }))
}

variable "tags" {
  description = "Tags applied to ECS resources."
  type        = map(string)
  default     = {}
}
