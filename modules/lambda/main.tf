data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "role_policy" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

locals {
  has_local_zip   = var.filename != null
  has_s3_zip      = var.s3_bucket != null && var.s3_key != null
  has_zip_package = local.has_local_zip || local.has_s3_zip
  role_name       = coalesce(var.role_name, "${var.function_name}-role")

  event_source_mappings = {
    for mapping in var.event_source_mappings : mapping.name => mapping
  }
}

check "zip_package_requirements" {
  assert {
    condition = var.package_type != "Zip" || (
      var.runtime != null &&
      var.handler != null &&
      local.has_zip_package
    )
    error_message = "Zip functions require runtime, handler, and either filename or s3_bucket with s3_key."
  }
}

check "zip_package_source_exclusive" {
  assert {
    condition     = var.package_type != "Zip" || !(local.has_local_zip && local.has_s3_zip)
    error_message = "Zip functions must use either filename or s3_bucket with s3_key, not both."
  }
}

check "source_code_hash_for_local_zip" {
  assert {
    condition     = var.package_type != "Zip" || !local.has_local_zip || var.source_code_hash != null
    error_message = "source_code_hash is required when deploying a Zip package from filename."
  }
}

check "image_package_requirements" {
  assert {
    condition     = var.package_type != "Image" || var.image_uri != null
    error_message = "Image functions require image_uri."
  }
}

check "function_url_authorization" {
  assert {
    condition     = var.function_url == null || contains(["AWS_IAM", "NONE"], try(var.function_url.authorization_type, "AWS_IAM"))
    error_message = "function_url.authorization_type must be AWS_IAM or NONE."
  }
}

data "aws_region" "current" {}

data "aws_s3_bucket" "artifact" {
  count  = local.has_s3_zip ? 1 : 0
  bucket = var.s3_bucket
}

check "s3_bucket_same_region" {
  assert {
    condition     = !local.has_s3_zip || data.aws_s3_bucket.artifact[0].region == data.aws_region.current.name
    error_message = "S3 deployment bucket must be in the same region as the Lambda function. Bucket '${var.s3_bucket}' is in ${try(data.aws_s3_bucket.artifact[0].region, "unknown")}, but Lambda is in ${data.aws_region.current.name}."
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_iam_role" "execution" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_execution" {
  count = var.vpc_config != null ? 1 : 0

  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "custom" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  name   = "${var.function_name}-policy"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.role_policy[0].json
}

resource "aws_lambda_function" "function" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.execution.arn
  package_type  = var.package_type
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = var.architectures
  layers        = var.layers
  kms_key_arn   = var.kms_key_arn

  runtime = var.package_type == "Zip" ? var.runtime : null
  handler = var.package_type == "Zip" ? var.handler : null

  filename          = var.package_type == "Zip" ? var.filename : null
  s3_bucket         = var.package_type == "Zip" ? var.s3_bucket : null
  s3_key            = var.package_type == "Zip" ? var.s3_key : null
  s3_object_version = var.package_type == "Zip" ? var.s3_object_version : null
  source_code_hash  = var.package_type == "Zip" ? var.source_code_hash : null
  image_uri         = var.package_type == "Image" ? var.image_uri : null

  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [var.environment_variables] : []

    content {
      variables = environment.value
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size != 512 ? [var.ephemeral_storage_size] : []

    content {
      size = ephemeral_storage.value
    }
  }

  tracing_config {
    mode = var.tracing_mode
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []

    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []

    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.vpc_execution,
    aws_cloudwatch_log_group.logs,
  ]
}

resource "aws_lambda_function_url" "url" {
  count = var.function_url != null ? 1 : 0

  function_name      = aws_lambda_function.function.function_name
  authorization_type = var.function_url.authorization_type

  dynamic "cors" {
    for_each = try(var.function_url.cors, null) != null ? [var.function_url.cors] : []

    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age           = try(cors.value.max_age, null)
    }
  }
}

resource "aws_lambda_event_source_mapping" "source" {
  for_each = local.event_source_mappings

  function_name    = aws_lambda_function.function.arn
  event_source_arn = each.value.event_source_arn
  batch_size       = each.value.batch_size
  enabled          = each.value.enabled

  maximum_batching_window_in_seconds = try(each.value.maximum_batching_window_in_seconds, null)
  function_response_types            = length(each.value.function_response_types) > 0 ? each.value.function_response_types : null
}
