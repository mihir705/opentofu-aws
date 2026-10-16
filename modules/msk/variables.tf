variable "name" {
  description = "MSK cluster name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "name must be between 1 and 64 characters."
  }
}

variable "kafka_version" {
  description = "Kafka version for the cluster."
  type        = string
  default     = "3.6.0"
}

variable "number_of_broker_nodes" {
  description = "Number of broker nodes. Must be a multiple of the number of client subnets (AZs)."
  type        = number
  default     = 3

  validation {
    condition     = var.number_of_broker_nodes >= 1
    error_message = "number_of_broker_nodes must be at least 1."
  }
}

variable "broker_instance_type" {
  description = "Broker instance type, e.g. kafka.m5.large."
  type        = string
  default     = "kafka.m5.large"
}

variable "subnet_ids" {
  description = "Subnet IDs for broker nodes (typically private subnets, one per AZ)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for broker ENIs."
  type        = list(string)
}

variable "ebs_volume_size" {
  description = "EBS volume size per broker in GiB."
  type        = number
  default     = 100

  validation {
    condition     = var.ebs_volume_size >= 1 && var.ebs_volume_size <= 16384
    error_message = "ebs_volume_size must be between 1 and 16384 GiB."
  }
}

variable "ebs_provisioned_throughput" {
  description = "Provisioned EBS throughput for broker storage."
  type = object({
    enabled           = optional(bool, false)
    volume_throughput = optional(number)
  })
  default = null
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption at rest. Omit to use the AWS managed key."
  type        = string
  default     = null
}

variable "encryption_in_transit" {
  description = "Encryption in transit settings between clients and brokers."
  type = object({
    client_broker = optional(string, "TLS")
    in_cluster    = optional(bool, true)
  })
  default = {}
}

variable "client_authentication" {
  description = "Client authentication mechanisms."
  type = object({
    unauthenticated = optional(bool, false)
    sasl = optional(object({
      scram = optional(bool, false)
      iam   = optional(bool, false)
    }))
    tls = optional(object({
      certificate_authority_arns = optional(list(string), [])
    }))
  })
  default = {}
}

variable "public_access" {
  description = "Public access to brokers: DISABLED or SERVICE_PROVIDED_E2E."
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["DISABLED", "SERVICE_PROVIDED_E2E"], var.public_access)
    error_message = "public_access must be DISABLED or SERVICE_PROVIDED_E2E."
  }
}

variable "configuration" {
  description = "MSK configuration revision. Create a new configuration or attach an existing one."
  type = object({
    create            = optional(bool, false)
    name              = optional(string)
    server_properties = optional(map(string), {})
    arn               = optional(string)
    revision          = optional(number)
  })
  default = null
}

variable "logging" {
  description = "Broker log delivery destinations."
  type = object({
    cloudwatch = optional(object({
      enabled           = optional(bool, false)
      log_group_name    = optional(string)
      retention_in_days = optional(number, 30)
    }))
    s3 = optional(object({
      enabled = optional(bool, false)
      bucket  = optional(string)
      prefix  = optional(string, "")
    }))
    firehose = optional(object({
      enabled         = optional(bool, false)
      delivery_stream = optional(string)
    }))
  })
  default = null
}

variable "open_monitoring" {
  description = "Prometheus open monitoring for brokers."
  type = object({
    jmx_exporter_enabled  = optional(bool, false)
    node_exporter_enabled = optional(bool, false)
  })
  default = null
}

variable "enhanced_monitoring" {
  description = "Enhanced CloudWatch monitoring level."
  type        = string
  default     = "DEFAULT"

  validation {
    condition = contains([
      "DEFAULT",
      "PER_BROKER",
      "PER_TOPIC_PER_BROKER",
      "PER_TOPIC_PER_PARTITION",
    ], var.enhanced_monitoring)
    error_message = "enhanced_monitoring must be DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, or PER_TOPIC_PER_PARTITION."
  }
}

variable "storage_mode" {
  description = "Cluster storage mode: LOCAL or TIERED."
  type        = string
  default     = "LOCAL"

  validation {
    condition     = contains(["LOCAL", "TIERED"], var.storage_mode)
    error_message = "storage_mode must be LOCAL or TIERED."
  }
}

variable "scram_secret_arns" {
  description = "Secrets Manager secret ARNs to associate for SASL/SCRAM authentication."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to MSK resources."
  type        = map(string)
  default     = {}
}
