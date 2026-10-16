data "aws_s3_bucket" "existing_origin" {
  count  = !var.create_origin_bucket ? 1 : 0
  bucket = var.existing_origin_bucket_id
}

locals {
  origin_bucket_id          = var.create_origin_bucket ? aws_s3_bucket.origin[0].id : var.existing_origin_bucket_id
  origin_bucket_arn         = var.create_origin_bucket ? aws_s3_bucket.origin[0].arn : var.existing_origin_bucket_arn
  origin_bucket_domain_name = var.create_origin_bucket ? aws_s3_bucket.origin[0].bucket_regional_domain_name : var.existing_origin_bucket_regional_domain_name
  origin_id                 = coalesce(var.origin_id, replace(local.origin_bucket_id, ".", "-"))
  manage_origin_bucket_policy = coalesce(var.manage_origin_bucket_policy, var.create_origin_bucket)
  use_custom_certificate    = length(var.aliases) > 0
  use_managed_cache_policy  = var.cache_policy_id != null

  spa_error_responses = var.spa_fallback && var.default_root_object != null ? [
    {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/${var.default_root_object}"
      error_caching_min_ttl = null
    },
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/${var.default_root_object}"
      error_caching_min_ttl = null
    },
  ] : []

  user_error_codes = toset([for response in var.custom_error_responses : response.error_code])

  spa_error_responses_filtered = [
    for response in local.spa_error_responses : response
    if !contains(local.user_error_codes, response.error_code)
  ]

  custom_error_responses = concat(local.spa_error_responses_filtered, var.custom_error_responses)
}

check "origin_bucket_name_required" {
  assert {
    condition     = !var.create_origin_bucket || (var.origin_bucket_name != null && var.origin_bucket_name != "")
    error_message = "origin_bucket_name is required when create_origin_bucket is true."
  }
}

check "existing_origin_bucket_required" {
  assert {
    condition = var.create_origin_bucket || (
      var.existing_origin_bucket_id != null &&
      var.existing_origin_bucket_arn != null &&
      var.existing_origin_bucket_regional_domain_name != null
    )
    error_message = "existing_origin_bucket_id, existing_origin_bucket_arn, and existing_origin_bucket_regional_domain_name are required when create_origin_bucket is false."
  }
}

check "custom_certificate_required" {
  assert {
    condition     = !local.use_custom_certificate || var.acm_certificate_arn != null
    error_message = "acm_certificate_arn is required when aliases are configured."
  }
}

check "geo_restriction_locations" {
  assert {
    condition     = var.geo_restriction_type == "none" || length(var.geo_restriction_locations) > 0
    error_message = "geo_restriction_locations must be non-empty when geo_restriction_type is whitelist or blacklist."
  }
}

check "forwarded_cookie_names" {
  assert {
    condition     = var.forward_cookies != "whitelist" || length(var.forwarded_cookie_names) > 0
    error_message = "forwarded_cookie_names is required when forward_cookies is whitelist."
  }
}

check "cached_methods_subset" {
  assert {
    condition = alltrue([
      for method in var.cached_methods : contains(var.allowed_methods, method)
    ])
    error_message = "cached_methods must be a subset of allowed_methods for the default cache behavior."
  }
}

check "ordered_cache_behaviors_cookies" {
  assert {
    condition = alltrue([
      for behavior in var.ordered_cache_behaviors :
      behavior.forward_cookies != "whitelist" || length(behavior.forwarded_cookie_names) > 0
    ])
    error_message = "forwarded_cookie_names is required when ordered_cache_behaviors.forward_cookies is whitelist."
  }
}

check "ordered_cache_behaviors_methods" {
  assert {
    condition = alltrue([
      for behavior in var.ordered_cache_behaviors :
      alltrue([for method in behavior.cached_methods : contains(behavior.allowed_methods, method)])
    ])
    error_message = "cached_methods must be a subset of allowed_methods for each ordered cache behavior."
  }
}

check "existing_origin_bucket_consistency" {
  assert {
    condition = var.create_origin_bucket || (
      data.aws_s3_bucket.existing_origin[0].arn == var.existing_origin_bucket_arn &&
      data.aws_s3_bucket.existing_origin[0].bucket_regional_domain_name == var.existing_origin_bucket_regional_domain_name
    )
    error_message = "existing_origin_bucket_arn and existing_origin_bucket_regional_domain_name must match the bucket referenced by existing_origin_bucket_id."
  }
}

check "spa_fallback_requires_root_object" {
  assert {
    condition     = !var.spa_fallback || (var.default_root_object != null && var.default_root_object != "")
    error_message = "spa_fallback requires default_root_object to be set."
  }
}

resource "aws_s3_bucket" "origin" {
  count = var.create_origin_bucket ? 1 : 0

  bucket        = var.origin_bucket_name
  force_destroy = var.origin_bucket_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "origin" {
  count = var.create_origin_bucket ? 1 : 0

  bucket = aws_s3_bucket.origin[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "origin" {
  count = var.create_origin_bucket ? 1 : 0

  bucket = aws_s3_bucket.origin[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket_public_access_block.origin]
}

resource "aws_s3_bucket_versioning" "origin" {
  count = var.create_origin_bucket ? 1 : 0

  bucket = aws_s3_bucket.origin[0].id

  versioning_configuration {
    status = var.origin_bucket_versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "origin" {
  count = var.create_origin_bucket ? 1 : 0

  bucket = aws_s3_bucket.origin[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.origin_sse_algorithm
      kms_master_key_id = var.origin_sse_algorithm == "aws:kms" ? var.origin_kms_key_arn : null
    }

    bucket_key_enabled = var.origin_sse_algorithm == "aws:kms" ? var.origin_bucket_key_enabled : null
  }
}

resource "aws_cloudfront_origin_access_control" "origin" {
  name                              = substr(replace("${local.origin_id}-oac", ".", "-"), 0, 64)
  description                       = "OAC for ${local.origin_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = var.enabled
  comment             = var.distribution_comment
  default_root_object = var.default_root_object
  price_class         = var.price_class
  aliases             = var.aliases
  web_acl_id          = var.web_acl_id
  http_version        = var.http_version
  is_ipv6_enabled     = var.is_ipv6_enabled
  wait_for_deployment = var.wait_for_deployment

  origin {
    domain_name              = local.origin_bucket_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.origin.id
    origin_path              = var.origin_path != "" ? var.origin_path : null
  }

  default_cache_behavior {
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    target_origin_id       = local.origin_id
    viewer_protocol_policy = var.viewer_protocol_policy
    compress               = local.use_managed_cache_policy ? null : var.compress
    cache_policy_id            = local.use_managed_cache_policy ? var.cache_policy_id : null
    origin_request_policy_id   = local.use_managed_cache_policy ? var.origin_request_policy_id : null
    response_headers_policy_id = var.response_headers_policy_id

    dynamic "forwarded_values" {
      for_each = local.use_managed_cache_policy ? [] : [1]

      content {
        query_string = var.forward_query_string

        cookies {
          forward           = var.forward_cookies
          whitelisted_names = var.forward_cookies == "whitelist" ? var.forwarded_cookie_names : null
        }

        headers = var.forward_headers
      }
    }

    min_ttl     = local.use_managed_cache_policy ? null : var.min_ttl
    default_ttl = local.use_managed_cache_policy ? null : var.default_ttl
    max_ttl     = local.use_managed_cache_policy ? null : var.max_ttl

    dynamic "function_association" {
      for_each = {
        for association in var.function_associations : association.event_type => association
      }

      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors

    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      target_origin_id       = coalesce(ordered_cache_behavior.value.target_origin_id, local.origin_id)
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      compress = ordered_cache_behavior.value.cache_policy_id != null ? null : ordered_cache_behavior.value.compress
      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id

      dynamic "forwarded_values" {
        for_each = ordered_cache_behavior.value.cache_policy_id != null ? [] : [1]

        content {
          query_string = ordered_cache_behavior.value.forward_query_string

          cookies {
            forward           = ordered_cache_behavior.value.forward_cookies
            whitelisted_names = ordered_cache_behavior.value.forward_cookies == "whitelist" ? ordered_cache_behavior.value.forwarded_cookie_names : null
          }

          headers = ordered_cache_behavior.value.forward_headers
        }
      }

      min_ttl     = ordered_cache_behavior.value.cache_policy_id != null ? null : ordered_cache_behavior.value.min_ttl
      default_ttl = ordered_cache_behavior.value.cache_policy_id != null ? null : ordered_cache_behavior.value.default_ttl
      max_ttl     = ordered_cache_behavior.value.cache_policy_id != null ? null : ordered_cache_behavior.value.max_ttl
    }
  }

  dynamic "custom_error_response" {
    for_each = local.custom_error_responses

    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_type == "none" ? [] : var.geo_restriction_locations
    }
  }

  dynamic "logging_config" {
    for_each = var.logging_config != null ? [var.logging_config] : []

    content {
      bucket          = logging_config.value.bucket
      prefix          = logging_config.value.prefix
      include_cookies = logging_config.value.include_cookies
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.use_custom_certificate
    acm_certificate_arn            = local.use_custom_certificate ? var.acm_certificate_arn : null
    ssl_support_method             = local.use_custom_certificate ? var.ssl_support_method : null
    minimum_protocol_version       = local.use_custom_certificate ? var.minimum_protocol_version : null
  }

  tags = var.tags
}

data "aws_iam_policy_document" "origin_bucket" {
  count = local.manage_origin_bucket_policy ? 1 : 0

  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${local.origin_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }

  dynamic "statement" {
    for_each = var.origin_bucket_policy_statements

    content {
      sid    = try(statement.value.sid, null)
      effect = statement.value.effect
      actions = statement.value.actions
      resources = coalesce(
        statement.value.resources,
        ["${local.origin_bucket_arn}/*"]
      )

      dynamic "principals" {
        for_each = statement.value.principals != null ? [statement.value.principals] : []

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_s3_bucket_policy" "origin" {
  count = local.manage_origin_bucket_policy ? 1 : 0

  bucket = local.origin_bucket_id
  policy = data.aws_iam_policy_document.origin_bucket[0].json

  depends_on = [
    aws_cloudfront_distribution.distribution,
    aws_s3_bucket_public_access_block.origin,
    aws_s3_bucket_ownership_controls.origin,
  ]
}
