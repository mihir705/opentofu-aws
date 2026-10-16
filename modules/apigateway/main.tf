locals {
  lambda_integrations = {
    for key, integration in var.integrations :
    key => integration
    if integration.integration_type == "AWS_PROXY" && try(integration.lambda_function_name, null) != null
  }

  lambda_authorizers = {
    for key, authorizer in var.authorizers :
    key => authorizer
    if authorizer.authorizer_type == "REQUEST" && try(authorizer.lambda_function_name, null) != null
  }

  vpc_link_id = try(aws_apigatewayv2_vpc_link.this[0].id, null)
}

check "stages_required" {
  assert {
    condition     = length(var.stages) > 0
    error_message = "At least one stage is required."
  }
}

check "routes_required" {
  assert {
    condition     = length(var.routes) > 0
    error_message = "At least one route is required."
  }
}

check "integrations_required" {
  assert {
    condition     = length(var.integrations) > 0
    error_message = "At least one integration is required."
  }
}

check "route_integration_keys" {
  assert {
    condition = alltrue([
      for route in var.routes :
      contains(keys(var.integrations), route.integration_key)
    ])
    error_message = "Each route must reference a valid integration_key."
  }
}

check "route_authorizer_keys" {
  assert {
    condition = alltrue([
      for route in var.routes :
      try(route.authorizer_key, null) == null || contains(keys(var.authorizers), route.authorizer_key)
    ])
    error_message = "Each route authorizer_key must reference a defined authorizer."
  }
}

check "route_authorization_types" {
  assert {
    condition = alltrue([
      for route in var.routes :
      contains(["NONE", "AWS_IAM", "JWT", "CUSTOM"], route.authorization_type)
    ])
    error_message = "Route authorization_type must be NONE, AWS_IAM, JWT, or CUSTOM."
  }
}

check "route_authorizer_required" {
  assert {
    condition = alltrue([
      for route in var.routes :
      !contains(["JWT", "CUSTOM"], route.authorization_type) || try(route.authorizer_key, null) != null
    ])
    error_message = "JWT and CUSTOM authorization types require authorizer_key."
  }
}

check "integration_types" {
  assert {
    condition = alltrue([
      for integration in var.integrations :
      contains(["AWS_PROXY", "HTTP_PROXY", "MOCK"], integration.integration_type)
    ])
    error_message = "integration_type must be AWS_PROXY, HTTP_PROXY, or MOCK."
  }
}

check "integration_uri_required" {
  assert {
    condition = alltrue([
      for integration in var.integrations :
      integration.integration_type == "MOCK" || try(integration.integration_uri, null) != null
    ])
    error_message = "integration_uri is required for AWS_PROXY and HTTP_PROXY integrations."
  }
}

check "lambda_permission_name_required" {
  assert {
    condition = alltrue([
      for key, integration in var.integrations :
      integration.integration_type != "AWS_PROXY" || try(integration.lambda_function_name, null) != null
    ])
    error_message = "lambda_function_name is required for AWS_PROXY integrations."
  }
}

check "vpc_link_connection" {
  assert {
    condition = alltrue([
      for integration in var.integrations :
      integration.connection_type != "VPC_LINK" || (
        try(integration.connection_id, null) != null || var.vpc_link != null
      )
    ])
    error_message = "VPC_LINK integrations require connection_id or vpc_link configuration."
  }
}

check "cors_http_only" {
  assert {
    condition     = var.cors_configuration == null || var.protocol_type == "HTTP"
    error_message = "cors_configuration is only supported for HTTP APIs."
  }
}

check "authorizer_types" {
  assert {
    condition = alltrue([
      for authorizer in var.authorizers :
      contains(["JWT", "REQUEST"], authorizer.authorizer_type)
    ])
    error_message = "authorizer_type must be JWT or REQUEST."
  }
}

check "jwt_authorizer_configuration" {
  assert {
    condition = alltrue([
      for authorizer in var.authorizers :
      authorizer.authorizer_type != "JWT" || try(authorizer.jwt_configuration, null) != null
    ])
    error_message = "jwt_configuration is required for JWT authorizers."
  }
}

check "request_authorizer_configuration" {
  assert {
    condition = alltrue([
      for authorizer in var.authorizers :
      authorizer.authorizer_type != "REQUEST" || try(authorizer.authorizer_uri, null) != null
    ])
    error_message = "authorizer_uri is required for REQUEST authorizers."
  }
}

check "domain_stage_key" {
  assert {
    condition     = var.domain == null || contains(keys(var.stages), var.domain.stage_key)
    error_message = "domain.stage_key must reference a defined stage."
  }
}

check "route_keys_unique" {
  assert {
    condition = length(distinct([for route in var.routes : route.route_key])) == length(var.routes)
    error_message = "Each route must have a unique route_key."
  }
}

check "connection_types" {
  assert {
    condition = alltrue([
      for integration in var.integrations :
      contains(["INTERNET", "VPC_LINK"], integration.connection_type)
    ])
    error_message = "connection_type must be INTERNET or VPC_LINK."
  }
}

check "payload_format_versions" {
  assert {
    condition = alltrue([
      for integration in var.integrations :
      integration.integration_type != "AWS_PROXY" ||
      contains(["1.0", "2.0"], try(integration.payload_format_version, "2.0"))
    ])
    error_message = "AWS_PROXY payload_format_version must be 1.0 or 2.0."
  }
}

check "integration_timeouts" {
  assert {
    condition = alltrue([
      for integration in var.integrations :
      integration.timeout_milliseconds >= 50 && integration.timeout_milliseconds <= 30000
    ])
    error_message = "timeout_milliseconds must be between 50 and 30000."
  }
}

check "vpc_link_subnet_count" {
  assert {
    condition     = var.vpc_link == null || length(var.vpc_link.subnet_ids) >= 2
    error_message = "vpc_link requires at least two subnet_ids across different Availability Zones."
  }
}

check "route_settings_keys" {
  assert {
    condition = alltrue([
      for stage in var.stages :
      alltrue([
        for route_key in keys(coalesce(try(stage.route_settings, null), {})) :
        contains([for route in var.routes : route.route_key], route_key)
      ])
    ])
    error_message = "stage route_settings keys must match defined route route_key values."
  }
}

check "domain_security_policy" {
  assert {
    condition = var.domain == null || contains(
      ["TLS_1_2", "TLS_1_0"],
      var.domain.security_policy
    )
    error_message = "domain.security_policy must be TLS_1_2 or TLS_1_0."
  }
}

check "request_authorizer_lambda_name" {
  assert {
    condition = alltrue([
      for authorizer in var.authorizers :
      authorizer.authorizer_type != "REQUEST" ||
      try(authorizer.lambda_function_name, null) != null ||
      !can(regex("^arn:aws:lambda:", coalesce(try(authorizer.authorizer_uri, ""), "")))
    ])
    error_message = "REQUEST Lambda authorizers require lambda_function_name for invoke permissions."
  }
}

check "cors_origins_required" {
  assert {
    condition = var.cors_configuration == null || length(var.cors_configuration.allow_origins) > 0
    error_message = "cors_configuration.allow_origins must contain at least one origin when CORS is enabled."
  }
}

check "api_key_routes_require_keys" {
  assert {
    condition = alltrue([
      for route in var.routes :
      !route.api_key_required || length(var.api_keys) > 0
    ])
    error_message = "Routes with api_key_required = true require at least one entry in api_keys."
  }
}

resource "aws_apigatewayv2_api" "api" {
  name          = var.name
  protocol_type = var.protocol_type
  description   = var.description
  disable_execute_api_endpoint = var.disable_execute_api_endpoint

  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []

    content {
      allow_credentials = cors_configuration.value.allow_credentials
      allow_headers     = cors_configuration.value.allow_headers
      allow_methods     = cors_configuration.value.allow_methods
      allow_origins     = cors_configuration.value.allow_origins
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = try(cors_configuration.value.max_age, null)
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_apigatewayv2_vpc_link" "this" {
  count = var.vpc_link != null ? 1 : 0

  name               = var.vpc_link.name
  subnet_ids         = var.vpc_link.subnet_ids
  security_group_ids = try(var.vpc_link.security_group_ids, [])

  tags = merge(var.tags, {
    Name = var.vpc_link.name
  })
}

resource "aws_apigatewayv2_integration" "integration" {
  for_each = var.integrations

  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = each.value.integration_type
  integration_method = each.value.integration_method
  integration_uri    = try(each.value.integration_uri, null)
  connection_type    = each.value.connection_type
  connection_id = each.value.connection_type == "VPC_LINK" ? coalesce(
    try(each.value.connection_id, null),
    local.vpc_link_id
  ) : try(each.value.connection_id, null)
  payload_format_version = try(each.value.payload_format_version, null)
  timeout_milliseconds   = each.value.timeout_milliseconds
  credentials_arn        = try(each.value.credentials_arn, null)
  request_parameters     = try(each.value.request_parameters, null)

  dynamic "tls_config" {
    for_each = try(each.value.tls_config, null) != null ? [each.value.tls_config] : []

    content {
      server_name_to_verify = try(tls_config.value.server_name_to_verify, null)
    }
  }
}

resource "aws_apigatewayv2_authorizer" "authorizer" {
  for_each = var.authorizers

  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = each.value.authorizer_type
  identity_sources = each.value.identity_sources
  name             = coalesce(try(each.value.name, null), each.key)

  authorizer_uri                   = try(each.value.authorizer_uri, null)
  authorizer_payload_format_version = try(each.value.authorizer_payload_format_version, null)
  authorizer_result_ttl_in_seconds = try(each.value.authorizer_result_ttl_in_seconds, null)
  enable_simple_responses          = try(each.value.enable_simple_responses, null)

  dynamic "jwt_configuration" {
    for_each = try(each.value.jwt_configuration, null) != null ? [each.value.jwt_configuration] : []

    content {
      audience = jwt_configuration.value.audience
      issuer   = jwt_configuration.value.issuer
    }
  }
}

resource "aws_apigatewayv2_route" "route" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.api.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.integration[each.value.integration_key].id}"

  authorization_type = each.value.authorization_type
  authorizer_id = (
    try(each.value.authorizer_key, null) != null ?
    aws_apigatewayv2_authorizer.authorizer[each.value.authorizer_key].id :
    null
  )
  authorization_scopes       = try(each.value.authorization_scopes, null)
  api_key_required           = each.value.api_key_required
  operation_name             = try(each.value.operation_name, null)
  model_selection_expression = try(each.value.model_selection_expression, null)
}

resource "aws_apigatewayv2_stage" "stage" {
  for_each = var.stages

  api_id      = aws_apigatewayv2_api.api.id
  name        = each.value.name
  auto_deploy = each.value.auto_deploy
  description = try(each.value.description, null)

  dynamic "access_log_settings" {
    for_each = try(each.value.access_log_settings, null) != null ? [each.value.access_log_settings] : []

    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }

  dynamic "default_route_settings" {
    for_each = try(each.value.default_route_settings, null) != null ? [each.value.default_route_settings] : []

    content {
      detailed_metrics_enabled = default_route_settings.value.detailed_metrics_enabled
      throttling_burst_limit   = try(default_route_settings.value.throttling_burst_limit, null)
      throttling_rate_limit    = try(default_route_settings.value.throttling_rate_limit, null)
    }
  }

  dynamic "route_settings" {
    for_each = coalesce(try(each.value.route_settings, null), {})

    content {
      route_key                = route_settings.key
      detailed_metrics_enabled = route_settings.value.detailed_metrics_enabled
      throttling_burst_limit   = try(route_settings.value.throttling_burst_limit, null)
      throttling_rate_limit    = try(route_settings.value.throttling_rate_limit, null)
    }
  }

  stage_variables = try(each.value.variables, {})

  tags = merge(var.tags, {
    # Use logical stage key — AWS stage names like $default contain $ which is invalid in tag values.
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_wafv2_web_acl_association" "stage" {
  for_each = {
    for key, stage in var.stages : key => stage
    if try(stage.web_acl_arn, null) != null
  }

  resource_arn = aws_apigatewayv2_stage.stage[each.key].arn
  web_acl_arn  = each.value.web_acl_arn
}

resource "aws_api_gateway_api_key" "api_key" {
  for_each = var.api_keys

  name        = coalesce(try(each.value.name, null), each.key)
  description = try(each.value.description, null)
  enabled     = true

  tags = merge(var.tags, {
    Name = coalesce(try(each.value.name, null), each.key)
  })
}

resource "aws_apigatewayv2_domain_name" "domain" {
  count = var.domain != null ? 1 : 0

  domain_name = var.domain.domain_name

  domain_name_configuration {
    certificate_arn = var.domain.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = var.domain.security_policy
  }

  tags = merge(var.tags, {
    Name = var.domain.domain_name
  })
}

resource "aws_apigatewayv2_api_mapping" "domain" {
  count = var.domain != null ? 1 : 0

  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.domain[0].domain_name
  stage       = aws_apigatewayv2_stage.stage[var.domain.stage_key].id
  api_mapping_key = try(var.domain.mapping_key, null)
}

resource "aws_lambda_permission" "apigw_integration" {
  for_each = local.lambda_integrations

  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_authorizer" {
  for_each = local.lambda_authorizers

  statement_id  = "AllowAuthorizerFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.authorizer[each.key].id}"
}
