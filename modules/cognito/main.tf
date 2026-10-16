data "aws_region" "current" {}

locals {
  create_domain = var.domain != null && (
    try(var.domain.prefix, null) != null || try(var.domain.custom_domain, null) != null
  )
  domain_prefix = try(var.domain.prefix, null)

  password_policy = {
    minimum_length                   = try(var.password_policy.minimum_length, 12)
    require_lowercase                = try(var.password_policy.require_lowercase, true)
    require_numbers                  = try(var.password_policy.require_numbers, true)
    require_symbols                  = try(var.password_policy.require_symbols, true)
    require_uppercase                = try(var.password_policy.require_uppercase, true)
    temporary_password_validity_days = try(var.password_policy.temporary_password_validity_days, 7)
  }

  clients = {
    for key, client in var.clients : key => {
      name                                 = coalesce(try(client.name, null), "${var.name}-${key}")
      generate_secret                      = try(client.generate_secret, false)
      explicit_auth_flows                  = try(client.explicit_auth_flows, ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
      allowed_oauth_flows                  = try(client.allowed_oauth_flows, [])
      allowed_oauth_flows_user_pool_client = try(client.allowed_oauth_flows_user_pool_client, false)
      allowed_oauth_scopes                 = try(client.allowed_oauth_scopes, [])
      callback_urls                        = try(client.callback_urls, [])
      logout_urls                          = try(client.logout_urls, [])
      default_redirect_uri                 = try(client.default_redirect_uri, null)
      supported_identity_providers         = try(client.supported_identity_providers, ["COGNITO"])
      prevent_user_existence_errors        = try(client.prevent_user_existence_errors, "ENABLED")
      access_token_validity                = try(client.access_token_validity, 60)
      id_token_validity                    = try(client.id_token_validity, 60)
      refresh_token_validity               = try(client.refresh_token_validity, 30)
      access_token_unit                    = try(client.access_token_unit, "minutes")
      id_token_unit                        = try(client.id_token_unit, "minutes")
      refresh_token_unit                   = try(client.refresh_token_unit, "days")
    }
  }
}

check "clients_required" {
  assert {
    condition     = length(var.clients) > 0
    error_message = "At least one app client is required."
  }
}

check "domain_source_exclusive" {
  assert {
    condition = var.domain == null || (
      (try(var.domain.prefix, null) != null) != (try(var.domain.custom_domain, null) != null)
    )
    error_message = "Domain must set exactly one of prefix or custom_domain."
  }
}

check "custom_domain_certificate" {
  assert {
    condition = var.domain == null || (
      try(var.domain.custom_domain, null) == null || try(var.domain.certificate_arn, null) != null
    )
    error_message = "custom_domain requires certificate_arn."
  }
}

check "oauth_callback_urls" {
  assert {
    condition = alltrue([
      for key, client in var.clients :
      !coalesce(try(client.allowed_oauth_flows_user_pool_client, false), false) ||
      length(coalesce(try(client.callback_urls, null), [])) > 0
    ])
    error_message = "OAuth-enabled clients require at least one callback_url."
  }
}

check "identity_pool_client_key" {
  assert {
    condition = var.identity_pool == null || contains(keys(var.clients), var.identity_pool.client_key)
    error_message = "identity_pool.client_key must exist in clients."
  }
}

check "explicit_auth_flow_values" {
  assert {
    condition = alltrue([
      for client in var.clients : alltrue([
        for flow in coalesce(try(client.explicit_auth_flows, null), []) :
        contains([
          "ALLOW_ADMIN_USER_PASSWORD_AUTH",
          "ALLOW_CUSTOM_AUTH",
          "ALLOW_USER_PASSWORD_AUTH",
          "ALLOW_USER_SRP_AUTH",
          "ALLOW_REFRESH_TOKEN_AUTH",
        ], flow)
      ])
    ])
    error_message = "explicit_auth_flows contains an unsupported value."
  }
}

check "oauth_flow_values" {
  assert {
    condition = alltrue([
      for client in var.clients : alltrue([
        for flow in coalesce(try(client.allowed_oauth_flows, null), []) :
        contains(["code", "implicit", "client_credentials"], flow)
      ])
    ])
    error_message = "allowed_oauth_flows must be code, implicit, or client_credentials."
  }
}

resource "aws_cognito_user_pool" "pool" {
  name = var.name

  username_attributes      = var.username_attributes
  auto_verified_attributes = var.auto_verified_attributes
  deletion_protection      = var.deletion_protection
  mfa_configuration        = var.mfa_configuration

  password_policy {
    minimum_length                   = local.password_policy.minimum_length
    require_lowercase                = local.password_policy.require_lowercase
    require_numbers                  = local.password_policy.require_numbers
    require_symbols                  = local.password_policy.require_symbols
    require_uppercase                = local.password_policy.require_uppercase
    temporary_password_validity_days = local.password_policy.temporary_password_validity_days
  }

  dynamic "account_recovery_setting" {
    for_each = length(var.account_recovery_mechanisms) > 0 ? [1] : []

    content {
      dynamic "recovery_mechanism" {
        for_each = var.account_recovery_mechanisms

        content {
          name     = recovery_mechanism.value.name
          priority = recovery_mechanism.value.priority
        }
      }
    }
  }

  dynamic "email_configuration" {
    for_each = var.email_configuration != null ? [var.email_configuration] : []

    content {
      email_sending_account  = email_configuration.value.email_sending_account
      source_arn             = try(email_configuration.value.source_arn, null)
      from_email_address     = try(email_configuration.value.from_email_address, null)
      reply_to_email_address = try(email_configuration.value.reply_to_email_address, null)
    }
  }

  dynamic "lambda_config" {
    for_each = length(compact([
      var.lambda_config.pre_sign_up,
      var.lambda_config.custom_message,
      var.lambda_config.post_confirmation,
      var.lambda_config.pre_authentication,
      var.lambda_config.post_authentication,
      var.lambda_config.define_auth_challenge,
      var.lambda_config.create_auth_challenge,
      var.lambda_config.verify_auth_challenge_response,
      var.lambda_config.user_migration,
    ])) > 0 ? [var.lambda_config] : []

    content {
      pre_sign_up                    = try(lambda_config.value.pre_sign_up, null)
      custom_message                 = try(lambda_config.value.custom_message, null)
      post_confirmation            = try(lambda_config.value.post_confirmation, null)
      pre_authentication           = try(lambda_config.value.pre_authentication, null)
      post_authentication          = try(lambda_config.value.post_authentication, null)
      define_auth_challenge          = try(lambda_config.value.define_auth_challenge, null)
      create_auth_challenge          = try(lambda_config.value.create_auth_challenge, null)
      verify_auth_challenge_response = try(lambda_config.value.verify_auth_challenge_response, null)
      user_migration                 = try(lambda_config.value.user_migration, null)
    }
  }

  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_cognito_user_pool_client" "client" {
  for_each = local.clients

  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret                      = each.value.generate_secret
  explicit_auth_flows                  = each.value.explicit_auth_flows
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = each.value.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls
  default_redirect_uri                 = try(each.value.default_redirect_uri, null)
  supported_identity_providers         = each.value.supported_identity_providers
  prevent_user_existence_errors        = each.value.prevent_user_existence_errors

  access_token_validity  = each.value.access_token_validity
  id_token_validity      = each.value.id_token_validity
  refresh_token_validity = each.value.refresh_token_validity

  token_validity_units {
    access_token  = each.value.access_token_unit
    id_token      = each.value.id_token_unit
    refresh_token = each.value.refresh_token_unit
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  count = local.create_domain ? 1 : 0

  domain          = coalesce(local.domain_prefix, var.domain.custom_domain)
  user_pool_id    = aws_cognito_user_pool.pool.id
  certificate_arn = try(var.domain.custom_domain, null) != null ? var.domain.certificate_arn : null
}

resource "aws_cognito_identity_pool" "identity" {
  count = var.identity_pool != null ? 1 : 0

  identity_pool_name               = var.identity_pool.name
  allow_unauthenticated_identities = var.identity_pool.allow_unauthenticated_identities

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client[var.identity_pool.client_key].id
    provider_name           = aws_cognito_user_pool.pool.endpoint
    server_side_token_check = true
  }

  tags = merge(var.tags, {
    Name = var.identity_pool.name
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "roles" {
  count = var.identity_pool != null && (
    try(var.identity_pool.authenticated_role_arn, null) != null ||
    try(var.identity_pool.unauthenticated_role_arn, null) != null
  ) ? 1 : 0

  identity_pool_id = aws_cognito_identity_pool.identity[0].id

  roles = merge(
    try(var.identity_pool.authenticated_role_arn, null) != null ? {
      authenticated = var.identity_pool.authenticated_role_arn
    } : {},
    try(var.identity_pool.unauthenticated_role_arn, null) != null ? {
      unauthenticated = var.identity_pool.unauthenticated_role_arn
    } : {}
  )
}
