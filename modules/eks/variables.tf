variable "name" {
  description = "EKS cluster name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 100
    error_message = "name must be between 1 and 100 characters."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster control plane."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the cluster and node groups (minimum two AZs)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Additional security group IDs attached to the cluster cross-account ENI."
  type        = list(string)
  default     = []
}

variable "cluster_role_arn" {
  description = "Existing IAM role ARN for the EKS cluster. Created automatically when null."
  type        = string
  default     = null
}

variable "node_role_arn" {
  description = "Existing IAM role ARN for managed node groups. Created automatically when null."
  type        = string
  default     = null
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "Control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "cloudwatch_log_retention_in_days" {
  description = "CloudWatch log retention for control plane logs."
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ARN for encrypting Kubernetes secrets at rest."
  type        = string
  default     = null
}

variable "authentication_mode" {
  description = "Cluster authentication mode: API, CONFIG_MAP, or API_AND_CONFIG_MAP."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster-creator admin permissions in the EKS access API."
  type        = bool
  default     = true
}

variable "create_oidc_provider" {
  description = "Create an IAM OIDC provider for IRSA."
  type        = bool
  default     = true
}

variable "node_groups" {
  description = "Managed node groups keyed by logical name."
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    ami_type       = optional(string)
    disk_size      = optional(number, 20)
    desired_size   = number
    min_size       = number
    max_size       = number
    subnet_ids     = optional(list(string))
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    max_unavailable            = optional(number)
    max_unavailable_percentage = optional(number)
    release_version            = optional(string)
  }))
}

variable "addons" {
  description = "EKS add-ons keyed by add-on name."
  type = map(object({
    addon_version               = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string)
    configuration_values        = optional(string)
  }))
  default = {
    vpc-cni = {}
    coredns = {}
    kube-proxy = {}
  }
}

variable "tags" {
  description = "Tags applied to EKS resources."
  type        = map(string)
  default     = {}
}
