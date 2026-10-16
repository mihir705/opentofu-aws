variable "name" {
  description = "Instance name used for the Name tag."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 256
    error_message = "name must be between 1 and 256 characters."
  }
}

variable "ami" {
  description = "AMI ID. Required unless ami_lookup is set."
  type        = string
  default     = null
}

variable "ami_lookup" {
  description = "AMI lookup configuration. Cannot be combined with ami."
  type = object({
    owners      = optional(list(string), ["amazon"])
    most_recent = optional(bool, true)
    filters     = map(list(string))
  })
  default = null
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string

  validation {
    condition     = length(var.instance_type) > 0
    error_message = "instance_type is required."
  }
}

variable "subnet_id" {
  description = "Subnet ID where the instance is launched."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]+$", var.subnet_id))
    error_message = "subnet_id must be a valid subnet ID."
  }
}

variable "vpc_security_group_ids" {
  description = "Security group IDs attached to the primary network interface."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.vpc_security_group_ids) <= 5
    error_message = "A maximum of 5 security groups can be attached to an instance."
  }
}

variable "key_name" {
  description = "EC2 key pair name for SSH access. Omit or set null to launch without a key pair (use SSM Session Manager instead)."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach to the instance."
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "Availability zone. Usually inferred from subnet_id when omitted."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with the primary network interface."
  type        = bool
  default     = null
}

variable "private_ip" {
  description = "Static private IPv4 address in the subnet."
  type        = string
  default     = null
}

variable "secondary_private_ips" {
  description = "Additional private IPv4 addresses for the primary network interface."
  type        = list(string)
  default     = []
}

variable "source_dest_check" {
  description = "Controls source/destination checking on the primary network interface."
  type        = bool
  default     = null
}

variable "user_data" {
  description = "Plain-text user data script."
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Base64-encoded user data. Cannot be combined with user_data."
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Replace the instance when user data changes."
  type        = bool
  default     = false
}

variable "monitoring" {
  description = "Enable detailed CloudWatch monitoring."
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "Enable EBS optimization. Null uses the instance type default."
  type        = bool
  default     = null
}

variable "disable_api_termination" {
  description = "Enable termination protection."
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior: stop or terminate."
  type        = string
  default     = null

  validation {
    condition = (
      var.instance_initiated_shutdown_behavior == null ||
      contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    )
    error_message = "instance_initiated_shutdown_behavior must be stop or terminate."
  }
}

variable "tenancy" {
  description = "Instance tenancy: default, dedicated, or host."
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.tenancy)
    error_message = "tenancy must be default, dedicated, or host."
  }
}

variable "placement_group" {
  description = "Placement group name."
  type        = string
  default     = null
}

variable "hibernation" {
  description = "Enable instance hibernation. Requires supported instance type, AMI, and root volume."
  type        = bool
  default     = false
}

variable "root_block_device" {
  description = "Root EBS volume overrides. Merged with module defaults (gp3, encrypted, delete_on_termination = true)."
  type = object({
    volume_size           = optional(number)
    volume_type           = optional(string)
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool)
  })
  default = null
}

variable "ebs_block_devices" {
  description = "Additional EBS volumes keyed by logical device name."
  type = map(object({
    device_name           = string
    volume_size           = optional(number)
    volume_type           = optional(string, "gp3")
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool, true)
    snapshot_id           = optional(string)
  }))
  default = {}
}

variable "metadata_options" {
  description = "Instance metadata service (IMDS) configuration."
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "disabled")
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
}

variable "cpu_options" {
  description = "CPU options for Nitro instances."
  type = object({
    core_count       = number
    threads_per_core = number
  })
  default = null
}

variable "credit_specification" {
  description = "Credit specification for burstable instance families."
  type = object({
    cpu_credits = string
  })
  default = null
}

variable "create_eip" {
  description = "Create and associate an Elastic IP with the instance."
  type        = bool
  default     = false
}

variable "eip_domain" {
  description = "EIP domain. Use vpc for VPC instances."
  type        = string
  default     = "vpc"

  validation {
    condition     = var.eip_domain == "vpc"
    error_message = "eip_domain must be vpc for instances launched in a VPC."
  }
}

variable "ignore_ami_changes" {
  description = "Ignore AMI changes after initial creation to avoid unwanted instance replacement."
  type        = bool
  default     = false
}

variable "volume_tags" {
  description = "Additional tags applied to EBS volumes created by the instance."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the instance and optional EIP."
  type        = map(string)
  default     = {}
}
