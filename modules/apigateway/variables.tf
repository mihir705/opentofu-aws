variable "name" {
  description = "API Gateway API name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 128
    error_message = "name must be between 1 and 128 characters."
  }
}

variable "description" {
  description = "API description."
  type        = string
  default     = null
}

variable "protocol_type" {
  description = "API protocol type: HTTP or WEBSOCKET."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "WEBSOCKET"], var.protocol_type)
    error_message = "protocol_type must be HTTP or WEBSOCKET."
  }
}

variable "disable_execute_api_endpoint" {
  description = "Disable the default execute-api.amazonaws.com endpoint."
  type        = bool
  default     = false
}

variable "cors_configuration" {
  description = "CORS configuration for HTTP APIs."
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string), [])
    allow_methods     = optional(list(string), [])
    allow_origins     = optional(list(string), [])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number)
  })
  default = null
}

variable "integrations" {
  description = "API integrations keyed by logical name."
  type = map(object({
    integration_type       = string
    integration_method     = optional(string, "POST")
    integration_uri        = optional(string)
    connection_type        = optional(string, "INTERNET")
    connection_id          = optional(string)
    payload_format_version = optional(string, "2.0")
    timeout_milliseconds   = optional(number, 30000)
    credentials_arn        = optional(string)
    request_parameters     = optional(map(string), {})
    lambda_function_name   = optional(string)
    tls_config = optional(object({
      server_name_to_verify = optional(string)
    }))
  }))
  default = {}
}

variable "routes" {
  description = "API routes keyed by logical name."
  type = map(object({
    route_key                = string
    integration_key          = string
    authorization_type       = optional(string, "NONE")
    authorizer_key           = optional(string)
    authorization_scopes     = optional(list(string), [])
    api_key_required         = optional(bool, false)
    operation_name           = optional(string)
    model_selection_expression = optional(string)
  }))
  default = {}
}

variable "authorizers" {
  description = "API authorizers keyed by logical name."
  type = map(object({
    authorizer_type  = string
    identity_sources = optional(list(string), [])
    name             = optional(string)
    jwt_configuration = optional(object({
      audience = list(string)
      issuer   = string
    }))
    authorizer_uri                   = optional(string)
    lambda_function_name             = optional(string)
    authorizer_payload_format_version = optional(string, "2.0")
    authorizer_result_ttl_in_seconds = optional(number, 300)
    enable_simple_responses          = optional(bool, false)
  }))
  default = {}
}

variable "stages" {
  description = "API stages keyed by logical name."
  type = map(object({
    name        = string
    auto_deploy = optional(bool, true)
    description = optional(string)
    access_log_settings = optional(object({
      destination_arn = string
      format          = string
    }))
    default_route_settings = optional(object({
      detailed_metrics_enabled = optional(bool, false)
      throttling_burst_limit   = optional(number)
      throttling_rate_limit    = optional(number)
    }))
    route_settings = optional(map(object({
      detailed_metrics_enabled = optional(bool, false)
      throttling_burst_limit   = optional(number)
      throttling_rate_limit    = optional(number)
    })), {})
    variables   = optional(map(string), {})
    web_acl_arn = optional(string)
  }))
}

variable "api_keys" {
  description = "API keys for routes with api_key_required. Clients send the key in the x-api-key header."
  type = map(object({
    name        = optional(string)
    description = optional(string)
  }))
  default = {}
}

variable "domain" {
  description = "Custom domain configuration."
  type = object({
    domain_name     = string
    certificate_arn = string
    security_policy = optional(string, "TLS_1_2")
    stage_key       = string
    mapping_key     = optional(string)
  })
  default = null

  validation {
    condition     = var.domain == null || contains(["TLS_1_2", "TLS_1_0"], var.domain.security_policy)
    error_message = "domain.security_policy must be TLS_1_2 or TLS_1_0."
  }
}

variable "vpc_link" {
  description = "VPC link for private HTTP integrations."
  type = object({
    name               = string
    subnet_ids         = list(string)
    security_group_ids = optional(list(string), [])
  })
  default = null
}

variable "tags" {
  description = "Tags applied to API Gateway resources."
  type        = map(string)
  default     = {}
}
