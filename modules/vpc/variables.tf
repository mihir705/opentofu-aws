variable "name" {
  description = "Name prefix applied to VPC resources and Name tags."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "Public subnets keyed by logical name. Typically two subnets across two AZs."
  type = map(object({
    availability_zone       = string
    cidr_block              = string
    map_public_ip_on_launch = optional(bool, true)
  }))
}

variable "private_subnets" {
  description = "Private subnets keyed by logical name. Typically two subnets across two AZs."
  type = map(object({
    availability_zone = string
    cidr_block        = string
  }))
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) for private subnet egress."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway in the first public subnet. Lower cost, single AZ egress dependency."
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT gateway per availability zone used by public subnets. Higher availability."
  type        = bool
  default     = false
}

variable "create_public_nacl" {
  description = "Create a dedicated Network ACL for public subnets."
  type        = bool
  default     = true
}

variable "create_private_nacl" {
  description = "Create a dedicated Network ACL for private subnets."
  type        = bool
  default     = true
}

variable "public_nacl_ingress_rules" {
  description = "Ingress rules for the public Network ACL."
  type = list(object({
    rule_number = number
    protocol    = string
    action      = string
    cidr_block  = string
    from_port   = optional(number)
    to_port     = optional(number)
    icmp_type   = optional(number)
    icmp_code   = optional(number)
  }))
  default = [
    {
      rule_number = 100
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
    },
    {
      rule_number = 110
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
    },
    {
      rule_number = 120
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 1024
      to_port     = 65535
    },
    {
      rule_number = 130
      protocol    = "udp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 1024
      to_port     = 65535
    }
  ]
}

variable "public_nacl_egress_rules" {
  description = "Egress rules for the public Network ACL."
  type = list(object({
    rule_number = number
    protocol    = string
    action      = string
    cidr_block  = string
    from_port   = optional(number)
    to_port     = optional(number)
    icmp_type   = optional(number)
    icmp_code   = optional(number)
  }))
  default = [
    {
      rule_number = 100
      protocol    = "-1"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
    }
  ]
}

variable "private_nacl_ingress_rules" {
  description = "Ingress rules for the private Network ACL. Defaults to allow all traffic from the VPC CIDR."
  type = list(object({
    rule_number = number
    protocol    = string
    action      = string
    cidr_block  = string
    from_port   = optional(number)
    to_port     = optional(number)
    icmp_type   = optional(number)
    icmp_code   = optional(number)
  }))
  default = null
}

variable "private_nacl_egress_rules" {
  description = "Egress rules for the private Network ACL."
  type = list(object({
    rule_number = number
    protocol    = string
    action      = string
    cidr_block  = string
    from_port   = optional(number)
    to_port     = optional(number)
    icmp_type   = optional(number)
    icmp_code   = optional(number)
  }))
  default = [
    {
      rule_number = 100
      protocol    = "-1"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
    }
  ]
}

variable "tags" {
  description = "Tags applied to all VPC resources."
  type        = map(string)
  default     = {}
}
