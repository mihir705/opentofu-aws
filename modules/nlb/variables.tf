variable "name" {
  description = "Name of the Network Load Balancer and related resources."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 32
    error_message = "name must be between 1 and 32 characters (AWS load balancer limit)."
  }
}

variable "vpc_id" {
  description = "VPC ID where target groups are created."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the NLB. Required unless subnet_mappings is configured."
  type        = list(string)
  default     = []
}

variable "internal" {
  description = "Create an internal load balancer. Set to false for an internet-facing NLB."
  type        = bool
  default     = false
}

variable "ip_address_type" {
  description = "IP address type for the load balancer."
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "ip_address_type must be ipv4 or dualstack."
  }
}

variable "security_group_ids" {
  description = "Optional security group IDs to attach to the NLB."
  type        = list(string)
  default     = []
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer."
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing for the NLB."
  type        = bool
  default     = true
}

variable "access_logs" {
  description = "Access logging configuration. Set to null to disable."
  type = object({
    bucket  = string
    prefix  = optional(string, "")
    enabled = optional(bool, true)
  })
  default = null
}

variable "subnet_mappings" {
  description = "Optional static IP or Elastic IP allocation per subnet."
  type = list(object({
    subnet_id     = string
    allocation_id = optional(string)
    private_ipv4_address = optional(string)
    ipv6_address         = optional(string)
  }))
  default = []
}

variable "target_groups" {
  description = "Target groups keyed by logical name."
  type = map(object({
    port                             = number
    protocol                         = string
    target_type                      = string
    vpc_id                           = optional(string)
    deregistration_delay             = optional(number, 300)
    preserve_client_ip               = optional(bool)
    connection_termination           = optional(bool)
    proxy_protocol_v2                = optional(bool, false)
    health_check_enabled             = optional(bool, true)
    health_check_interval            = optional(number, 30)
    health_check_port                = optional(string, "traffic-port")
    health_check_protocol            = optional(string, "TCP")
    health_check_path                = optional(string)
    health_check_timeout             = optional(number, 10)
    health_check_healthy_threshold   = optional(number, 3)
    health_check_unhealthy_threshold = optional(number, 3)
    health_check_matcher             = optional(string)
    stickiness_enabled               = optional(bool, false)
    stickiness_type                  = optional(string, "source_ip")
    targets = optional(list(object({
      id                = string
      port              = optional(number)
      availability_zone = optional(string)
    })), [])
  }))
}

variable "listeners" {
  description = "Listeners keyed by logical name."
  type = map(object({
    port              = number
    protocol          = string
    certificate_arn   = optional(string)
    ssl_policy        = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    alpn_policy       = optional(string)
    target_group_key  = string
  }))
}

variable "tags" {
  description = "Tags applied to NLB resources."
  type        = map(string)
  default     = {}
}
