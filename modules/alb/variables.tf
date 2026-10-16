variable "name" {
  description = "Name of the Application Load Balancer and related resources."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 32
    error_message = "name must be between 1 and 32 characters (AWS ALB limit)."
  }
}

variable "vpc_id" {
  description = "VPC ID where the ALB and target groups are created."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB. Use at least two public subnets across AZs for internet-facing ALBs."
  type        = list(string)
}

variable "internal" {
  description = "Create an internal load balancer. Set to false for an internet-facing ALB."
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

variable "create_security_group" {
  description = "Create a dedicated security group for the ALB."
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "Existing security group IDs to attach to the ALB. Used when create_security_group is false."
  type        = list(string)
  default     = []
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on HTTP and HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle timeout in seconds for the load balancer."
  type        = number
  default     = 60
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid HTTP header fields."
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enable HTTP/2 on the load balancer."
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

variable "target_groups" {
  description = "Target groups keyed by logical name."
  type = map(object({
    port                             = number
    protocol                         = string
    target_type                      = string
    vpc_id                           = optional(string)
    load_balancing_algorithm_type    = optional(string, "round_robin")
    deregistration_delay             = optional(number, 300)
    slow_start                       = optional(number, 0)
    health_check_enabled             = optional(bool, true)
    health_check_interval            = optional(number, 30)
    health_check_path                = optional(string, "/")
    health_check_port                = optional(string, "traffic-port")
    health_check_protocol            = optional(string, "HTTP")
    health_check_timeout             = optional(number, 5)
    health_check_healthy_threshold   = optional(number, 3)
    health_check_unhealthy_threshold = optional(number, 3)
    health_check_matcher             = optional(string, "200-399")
    stickiness_enabled               = optional(bool, false)
    stickiness_type                  = optional(string, "lb_cookie")
    stickiness_cookie_duration       = optional(number, 86400)
    targets = optional(list(object({
      id               = string
      port             = optional(number)
      availability_zone = optional(string)
    })), [])
  }))
}

variable "listeners" {
  description = "Listeners keyed by logical name."
  type = map(object({
    port            = number
    protocol        = string
    certificate_arn = optional(string)
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    default_action = object({
      type             = string
      target_group_key = optional(string)
      fixed_response = optional(object({
        content_type = string
        message_body = string
        status_code  = string
      }))
      redirect = optional(object({
        port        = string
        protocol    = string
        status_code = string
        host        = optional(string)
        path        = optional(string)
        query       = optional(string)
      }))
    })
    rules = optional(list(object({
      name         = string
      priority     = number
      host_header  = optional(list(string))
      path_pattern = optional(list(string))
      http_header = optional(object({
        name   = string
        values = list(string)
      }))
      action = object({
        type             = string
        target_group_key = optional(string)
        fixed_response = optional(object({
          content_type = string
          message_body = string
          status_code  = string
        }))
        redirect = optional(object({
          port        = string
          protocol    = string
          status_code = string
          host        = optional(string)
          path        = optional(string)
          query       = optional(string)
        }))
      })
    })), [])
  }))
}

variable "tags" {
  description = "Tags applied to ALB resources."
  type        = map(string)
  default     = {}
}
