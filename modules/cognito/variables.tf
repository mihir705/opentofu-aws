variable "name" {
  description = "Cognito user pool name."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 128
    error_message = "name must be between 1 and 128 characters."
  }
}

variable "username_attributes" {
  description = "Username attributes: email, phone_number, or both."
  type        = list(string)
  default     = ["email"]

  validation {
    condition = length([
      for attr in var.username_attributes :
      attr if contains(["email", "phone_number"], attr)
    ]) == length(var.username_attributes)
    error_message = "username_attributes may only contain email and/or phone_number."
  }
}

variable "auto_verified_attributes" {
  description = "Attributes to auto-verify."
  type        = list(string)
  default     = ["email"]

  validation {
    condition = length([
      for attr in var.auto_verified_attributes :
      attr if contains(["email", "phone_number"], attr)
    ]) == length(var.auto_verified_attributes)
    error_message = "auto_verified_attributes may only contain email and/or phone_number."
  }
}

variable "deletion_protection" {
  description = "Deletion protection: ACTIVE or INACTIVE."
  type        = string
  default     = "INACTIVE"

  validation {
    condition     = contains(["ACTIVE", "INACTIVE"], var.deletion_protection)
    error_message = "deletion_protection must be ACTIVE or INACTIVE."
  }
}

variable "mfa_configuration" {
  description = "MFA configuration: OFF, ON, or OPTIONAL."
  type        = string
  default     = "OFF"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be OFF, ON, or OPTIONAL."
  }
}

variable "password_policy" {
  description = "Password policy for the user pool."
  type = object({
    minimum_length                   = optional(number, 12)
    require_lowercase                = optional(bool, true)
    require_numbers                  = optional(bool, true)
    require_symbols                  = optional(bool, true)
    require_uppercase                = optional(bool, true)
    temporary_password_validity_days = optional(number, 7)
  })
  default = {}
}

variable "account_recovery_mechanisms" {
  description = "Account recovery mechanisms in priority order."
  type = list(object({
    name     = string
    priority = number
  }))
  default = [
    {
      name     = "verified_email"
      priority = 1
    }
  ]
}

variable "advanced_security_mode" {
  description = "Advanced security mode: OFF, AUDIT, or ENFORCED."
  type        = string
  default     = "OFF"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "advanced_security_mode must be OFF, AUDIT, or ENFORCED."
  }
}

variable "email_configuration" {
  description = "Email delivery configuration. Omit to use Cognito default email."
  type = object({
    email_sending_account  = optional(string, "COGNITO_DEFAULT")
    source_arn             = optional(string)
    from_email_address     = optional(string)
    reply_to_email_address = optional(string)
  })
  default = null
}

variable "lambda_config" {
  description = "Lambda trigger ARNs keyed by trigger name."
  type = object({
    pre_sign_up                    = optional(string)
    custom_message                 = optional(string)
    post_confirmation            = optional(string)
    pre_authentication           = optional(string)
    post_authentication          = optional(string)
    define_auth_challenge          = optional(string)
    create_auth_challenge          = optional(string)
    verify_auth_challenge_response = optional(string)
    user_migration                 = optional(string)
  })
  default = {}
}

variable "domain" {
  description = "Cognito hosted UI domain prefix or custom domain."
  type = object({
    prefix          = optional(string)
    custom_domain   = optional(string)
    certificate_arn = optional(string)
  })
  default = null
}

variable "clients" {
  description = "User pool app clients keyed by logical name."
  type = map(object({
    name                                 = optional(string)
    generate_secret                      = optional(bool, false)
    explicit_auth_flows                  = optional(list(string), ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
    allowed_oauth_flows                  = optional(list(string), [])
    allowed_oauth_flows_user_pool_client = optional(bool, false)
    allowed_oauth_scopes                 = optional(list(string), [])
    callback_urls                        = optional(list(string), [])
    logout_urls                          = optional(list(string), [])
    default_redirect_uri                 = optional(string)
    supported_identity_providers         = optional(list(string), ["COGNITO"])
    prevent_user_existence_errors        = optional(string, "ENABLED")
    access_token_validity                = optional(number, 60)
    id_token_validity                    = optional(number, 60)
    refresh_token_validity               = optional(number, 30)
    access_token_unit                    = optional(string, "minutes")
    id_token_unit                        = optional(string, "minutes")
    refresh_token_unit                   = optional(string, "days")
  }))
}

variable "identity_pool" {
  description = "Optional Cognito identity pool for AWS credential federation."
  type = object({
    name                           = string
    allow_unauthenticated_identities = optional(bool, false)
    client_key                     = string
    authenticated_role_arn         = optional(string)
    unauthenticated_role_arn       = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags applied to Cognito resources."
  type        = map(string)
  default     = {}
}
