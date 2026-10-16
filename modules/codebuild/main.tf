data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

locals {
  role_name         = coalesce(var.role_name, "${var.name}-role")
  service_role_arn  = var.create_service_role ? aws_iam_role.service[0].arn : var.service_role_arn
  log_group_name    = coalesce(try(var.logs_config.cloudwatch_logs.group_name, null), "/aws/codebuild/${var.name}")
  uses_s3_artifacts = var.artifacts.type == "S3"
  uses_s3_cache     = try(var.cache.type, null) == "S3"
  uses_s3_source    = var.source_config.type == "S3"
  s3_locations = distinct(compact([
    var.artifacts.type == "S3" ? try(var.artifacts.location, null) : null,
    try(var.cache.type, null) == "S3" ? try(var.cache.location, null) : null,
    var.source_config.type == "S3" ? try(var.source_config.location, null) : null,
    try(var.logs_config.s3_logs.status, "DISABLED") == "ENABLED" ? try(var.logs_config.s3_logs.location, null) : null,
  ]))
  s3_bucket_names = distinct([
    for location in local.s3_locations : split("/", location)[0]
  ])

  artifact_fields = var.artifacts.type == "S3" ? {
    location               = try(var.artifacts.location, null)
    path                   = try(var.artifacts.path, null)
    namespace_type         = try(var.artifacts.namespace_type, "NONE")
    packaging              = try(var.artifacts.packaging, "NONE")
    encryption_disabled    = try(var.artifacts.encryption_disabled, null)
    override_artifact_name = try(var.artifacts.override_artifact_name, null)
    name                   = try(var.artifacts.name, null)
    artifact_identifier    = try(var.artifacts.artifact_identifier, null)
    } : {
    location               = null
    path                   = null
    namespace_type         = null
    packaging              = null
    encryption_disabled    = null
    override_artifact_name = null
    name                   = null
    artifact_identifier    = try(var.artifacts.artifact_identifier, null)
  }

  resolved_buildspec = try(var.source_config.buildspec, null) != null ? var.source_config.buildspec : try(var.buildspec, null)
}

data "aws_iam_policy_document" "service_role" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}:*",
    ]
  }

  dynamic "statement" {
    for_each = length(local.s3_bucket_names) > 0 ? [1] : []

    content {
      sid    = "S3Access"
      effect = "Allow"

      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:ListBucket",
      ]

      resources = distinct(flatten([
        for bucket in local.s3_bucket_names : [
          "arn:aws:s3:::${bucket}",
          "arn:aws:s3:::${bucket}/*",
        ]
      ]))
    }
  }

  dynamic "statement" {
    for_each = var.vpc_config != null ? [1] : []

    content {
      sid    = "VpcNetworkInterfaces"
      effect = "Allow"

      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.vpc_config != null ? [1] : []

    content {
      sid    = "VpcNetworkInterfacesTag"
      effect = "Allow"

      actions = [
        "ec2:CreateNetworkInterfacePermission",
      ]

      resources = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "ec2:AuthorizedService"
        values   = ["codebuild.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.encryption_key != null ? [1] : []

    content {
      sid    = "KmsArtifactEncryption"
      effect = "Allow"

      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
      ]

      resources = [var.encryption_key]
    }
  }

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

check "service_role_source" {
  assert {
    condition     = var.create_service_role || try(var.service_role_arn, null) != null
    error_message = "Provide service_role_arn when create_service_role is false."
  }
}

check "source_location_required" {
  assert {
    condition = contains(["NO_SOURCE", "CODEPIPELINE"], var.source_config.type) || (
      try(var.source_config.location, null) != null && var.source_config.location != ""
    )
    error_message = "source_config.location is required unless source_config.type is NO_SOURCE or CODEPIPELINE."
  }
}

check "buildspec_required" {
  assert {
    condition = var.source_config.type != "NO_SOURCE" || (
      try(local.resolved_buildspec, null) != null && local.resolved_buildspec != ""
    )
    error_message = "buildspec is required when source_config.type is NO_SOURCE (set buildspec or source.buildspec)."
  }
}

check "artifacts_s3_location" {
  assert {
    condition = var.artifacts.type != "S3" || (
      try(var.artifacts.location, null) != null && var.artifacts.location != ""
    )
    error_message = "artifacts.location is required when artifacts.type is S3."
  }
}

check "cache_s3_location" {
  assert {
    condition = try(var.cache.type, null) != "S3" || (
      try(var.cache.location, null) != null && var.cache.location != ""
    )
    error_message = "cache.location is required when cache.type is S3."
  }
}

check "vpc_config_complete" {
  assert {
    condition = var.vpc_config == null || (
      length(var.vpc_config.subnet_ids) > 0 &&
      length(var.vpc_config.security_group_ids) > 0
    )
    error_message = "vpc_config requires at least one subnet_id and one security_group_id."
  }
}

check "webhook_source_types" {
  assert {
    condition = var.webhook == null || contains(
      ["GITHUB", "GITHUB_ENTERPRISE", "BITBUCKET"],
      var.source_config.type
    )
    error_message = "webhook is only supported for GITHUB, GITHUB_ENTERPRISE, or BITBUCKET sources."
  }
}

check "source_types" {
  assert {
    condition = contains([
      "CODECOMMIT",
      "CODEPIPELINE",
      "GITHUB",
      "GITHUB_ENTERPRISE",
      "GITLAB",
      "GITLAB_SELF_MANAGED",
      "BITBUCKET",
      "S3",
      "NO_SOURCE",
    ], var.source_config.type)
    error_message = "source_config.type must be a supported CodeBuild source type."
  }
}

check "artifact_types" {
  assert {
    condition     = contains(["CODEPIPELINE", "NO_ARTIFACTS", "S3"], var.artifacts.type)
    error_message = "artifacts.type must be CODEPIPELINE, NO_ARTIFACTS, or S3."
  }
}

check "cache_types" {
  assert {
    condition     = var.cache == null || contains(["NO_CACHE", "S3", "LOCAL"], var.cache.type)
    error_message = "cache.type must be NO_CACHE, S3, or LOCAL."
  }
}

check "local_cache_modes" {
  assert {
    condition = try(var.cache.type, null) != "LOCAL" || length(try(var.cache.modes, [])) > 0
    error_message = "cache.modes is required when cache.type is LOCAL."
  }
}

check "s3_logs_location" {
  assert {
    condition = try(var.logs_config.s3_logs.status, "DISABLED") != "ENABLED" || (
      try(var.logs_config.s3_logs.location, null) != null && var.logs_config.s3_logs.location != ""
    )
    error_message = "logs_config.s3_logs.location is required when s3_logs status is ENABLED."
  }
}

check "environment_variable_types" {
  assert {
    condition = alltrue([
      for env_var in var.environment.environment_variables :
      contains(["PLAINTEXT", "PARAMETER_STORE", "SECRETS_MANAGER"], env_var.type)
    ])
    error_message = "environment variable type must be PLAINTEXT, PARAMETER_STORE, or SECRETS_MANAGER."
  }
}

check "environment_variable_names_unique" {
  assert {
    condition = length(distinct([for env_var in var.environment.environment_variables : env_var.name])) == length(var.environment.environment_variables)
    error_message = "environment variable names must be unique."
  }
}

check "compute_types" {
  assert {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM",
      "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_XLARGE",
      "BUILD_GENERAL1_2XLARGE",
      "BUILD_LAMBDA_1GB",
      "BUILD_LAMBDA_2GB",
      "BUILD_LAMBDA_4GB",
      "BUILD_LAMBDA_8GB",
      "BUILD_LAMBDA_10GB",
    ], var.environment.compute_type)
    error_message = "environment.compute_type must be a supported CodeBuild compute type."
  }
}

check "environment_types" {
  assert {
    condition = contains([
      "LINUX_CONTAINER",
      "LINUX_GPU_CONTAINER",
      "WINDOWS_SERVER_2019_CONTAINER",
      "WINDOWS_SERVER_2022_CONTAINER",
      "ARM_CONTAINER",
      "LINUX_LAMBDA_CONTAINER",
      "ARM_LAMBDA_CONTAINER",
    ], var.environment.type)
    error_message = "environment.type must be a supported CodeBuild environment type."
  }
}

check "role_name_length" {
  assert {
    condition     = !var.create_service_role || length(local.role_name) <= 64
    error_message = "IAM role name must be 64 characters or fewer. Set role_name explicitly for long project names."
  }
}

check "vpc_subnet_count" {
  assert {
    condition     = var.vpc_config == null || length(var.vpc_config.subnet_ids) >= 1
    error_message = "vpc_config requires at least one subnet_id."
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  count = var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_iam_role" "service" {
  count = var.create_service_role ? 1 : 0

  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "service" {
  count = var.create_service_role ? 1 : 0

  name   = "${var.name}-policy"
  role   = aws_iam_role.service[0].id
  policy = data.aws_iam_policy_document.service_role.json
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.create_service_role ? toset(var.managed_policy_arns) : toset([])

  role       = aws_iam_role.service[0].name
  policy_arn = each.value
}

resource "aws_codebuild_project" "project" {
  name                   = var.name
  description            = var.description
  build_timeout          = var.build_timeout
  queued_timeout         = var.queued_timeout
  service_role           = local.service_role_arn
  badge_enabled          = var.badge_enabled
  concurrent_build_limit = var.concurrent_build_limit
  encryption_key         = var.encryption_key
  source_version         = var.source_version

  artifacts {
    type                   = var.artifacts.type
    location               = local.artifact_fields.location
    path                   = local.artifact_fields.path
    namespace_type         = local.artifact_fields.namespace_type
    packaging              = local.artifact_fields.packaging
    encryption_disabled    = local.artifact_fields.encryption_disabled
    override_artifact_name = local.artifact_fields.override_artifact_name
    artifact_identifier    = local.artifact_fields.artifact_identifier
    name                   = local.artifact_fields.name
  }

  dynamic "cache" {
    for_each = var.cache != null ? [var.cache] : []

    content {
      type     = cache.value.type
      location = try(cache.value.location, null)
      modes    = try(cache.value.modes, null)
    }
  }

  environment {
    compute_type                = var.environment.compute_type
    image                       = var.environment.image
    type                        = var.environment.type
    privileged_mode             = var.environment.privileged_mode
    image_pull_credentials_type = var.environment.image_pull_credentials_type
    certificate                 = try(var.environment.certificate, null)

    dynamic "registry_credential" {
      for_each = try(var.environment.registry_credential, null) != null ? [var.environment.registry_credential] : []

      content {
        credential          = registry_credential.value.credential
        credential_provider = registry_credential.value.credential_provider
      }
    }

    dynamic "environment_variable" {
      for_each = var.environment.environment_variables

      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type                = var.source_config.type
    location            = try(var.source_config.location, null)
    buildspec           = local.resolved_buildspec
    git_clone_depth     = try(var.source_config.git_clone_depth, null)
    insecure_ssl        = try(var.source_config.insecure_ssl, null)
    report_build_status = try(var.source_config.report_build_status, null)

    dynamic "git_submodules_config" {
      for_each = try(var.source_config.fetch_submodules, false) ? [1] : []

      content {
        fetch_submodules = true
      }
    }

    dynamic "auth" {
      for_each = try(var.source_config.auth, null) != null ? [var.source_config.auth] : []

      content {
        type     = auth.value.type
        resource = try(auth.value.resource, null)
      }
    }
  }

  dynamic "logs_config" {
    for_each = var.logs_config != null ? [var.logs_config] : []

    content {
      dynamic "cloudwatch_logs" {
        for_each = try(logs_config.value.cloudwatch_logs, null) != null ? [logs_config.value.cloudwatch_logs] : []

        content {
          group_name  = coalesce(try(cloudwatch_logs.value.group_name, null), local.log_group_name)
          stream_name = try(cloudwatch_logs.value.stream_name, null)
          status      = cloudwatch_logs.value.status
        }
      }

      dynamic "s3_logs" {
        for_each = try(logs_config.value.s3_logs, null) != null ? [logs_config.value.s3_logs] : []

        content {
          status              = s3_logs.value.status
          location            = try(s3_logs.value.location, null)
          encryption_disabled = try(s3_logs.value.encryption_disabled, null)
          bucket_owner_access = try(s3_logs.value.bucket_owner_access, null)
        }
      }
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []

    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "file_system_locations" {
    for_each = var.file_system_locations

    content {
      identifier  = file_system_locations.value.identifier
      location    = file_system_locations.value.location
      mount_point = file_system_locations.value.mount_point
      type        = file_system_locations.value.type
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  depends_on = [
    aws_iam_role_policy.service,
    aws_cloudwatch_log_group.logs,
  ]
}

resource "aws_codebuild_webhook" "webhook" {
  count = var.webhook != null ? 1 : 0

  project_name = aws_codebuild_project.project.name
  build_type   = var.webhook.build_type

  dynamic "filter_group" {
    for_each = try(var.webhook.filter_groups, [])

    content {
      dynamic "filter" {
        for_each = filter_group.value

        content {
          type                    = filter.value.type
          pattern                 = filter.value.pattern
          exclude_matched_pattern = try(filter.value.exclude_matched_pattern, null)
        }
      }
    }
  }
}
