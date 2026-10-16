data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

locals {
  role_name        = coalesce(var.role_name, "${var.name}-role")
  service_role_arn = var.create_service_role ? aws_iam_role.service[0].arn : var.service_role_arn
  artifact_bucket  = var.artifact_bucket
  artifact_stores = concat(
    [{
      location    = local.artifact_bucket
      region      = try(var.artifact_store_region, null)
      kms_key_arn = var.artifact_kms_key_arn
    }],
    [
      for store in var.secondary_artifact_stores : {
        location    = store.location
        region      = store.region
        kms_key_arn = try(store.kms_key_arn, null)
      }
    ]
  )
  s3_bucket_names = distinct([for store in local.artifact_stores : store.location])
  kms_key_arns = distinct(compact([for store in local.artifact_stores : store.kms_key_arn]))
  action_names = flatten([
    for stage in var.stages : [for action in stage.actions : action.name]
  ])
}

data "aws_iam_policy_document" "service_role" {
  statement {
    sid    = "S3ArtifactStore"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]

    resources = distinct(flatten([
      for bucket in local.s3_bucket_names : [
        "arn:aws:s3:::${bucket}",
        "arn:aws:s3:::${bucket}/*",
      ]
    ]))
  }

  statement {
    sid    = "CodeBuild"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:StopBuild",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CodeStarConnections"
    effect = "Allow"

    actions = [
      "codestar-connections:UseConnection",
    ]

    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(local.kms_key_arns) > 0 ? [1] : []

    content {
      sid    = "KmsArtifactEncryption"
      effect = "Allow"

      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
      ]

      resources = local.kms_key_arns
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

check "stages_required" {
  assert {
    condition     = length(var.stages) >= 2
    error_message = "CodePipeline requires at least two stages."
  }
}

check "stage_actions_required" {
  assert {
    condition = alltrue([
      for stage in var.stages : length(stage.actions) > 0
    ])
    error_message = "Each pipeline stage requires at least one action."
  }
}

check "role_name_length" {
  assert {
    condition     = !var.create_service_role || length(local.role_name) <= 64
    error_message = "IAM role name must be 64 characters or fewer. Set role_name explicitly for long pipeline names."
  }
}

check "trigger_pipeline_type" {
  assert {
    condition     = var.trigger == null || var.pipeline_type == "V2"
    error_message = "trigger is only supported on V2 pipelines."
  }
}

check "action_categories" {
  assert {
    condition = alltrue(flatten([
      for stage in var.stages : [
        for action in stage.actions :
        contains(["Source", "Build", "Deploy", "Test", "Approval", "Invoke"], action.category)
      ]
    ]))
    error_message = "Action category must be Source, Build, Deploy, Test, Approval, or Invoke."
  }
}

check "action_names_unique" {
  assert {
    condition     = length(distinct(local.action_names)) == length(local.action_names)
    error_message = "Pipeline action names must be unique across all stages."
  }
}

check "stage_names_unique" {
  assert {
    condition     = length(distinct([for stage in var.stages : stage.name])) == length(var.stages)
    error_message = "Pipeline stage names must be unique."
  }
}

check "codebuild_project_name" {
  assert {
    condition = alltrue(flatten([
      for stage in var.stages : [
        for action in stage.actions :
        action.provider != "CodeBuild" || try(action.configuration["ProjectName"], null) != null
      ]
    ]))
    error_message = "CodeBuild actions require configuration.ProjectName (use codebuild_project_key in the environment tfvars)."
  }
}

check "variables_pipeline_type" {
  assert {
    condition     = length(var.variables) == 0 || var.pipeline_type == "V2"
    error_message = "Pipeline variables are only supported on V2 pipelines."
  }
}

check "cross_region_artifact_stores" {
  assert {
    condition = length(var.secondary_artifact_stores) == 0 || (
      try(var.artifact_store_region, null) != null &&
      alltrue([for store in var.secondary_artifact_stores : store.region != null && store.region != ""])
    )
    error_message = "Cross-region pipelines require artifact_store_region and region on each secondary artifact store."
  }
}

check "trigger_source_action_exists" {
  assert {
    condition = var.trigger == null || contains(
      local.action_names,
      var.trigger.git_configuration.source_action_name
    )
    error_message = "trigger.git_configuration.source_action_name must match a pipeline action name."
  }
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

resource "aws_codepipeline" "pipeline" {
  name            = var.name
  role_arn        = local.service_role_arn
  pipeline_type   = var.pipeline_type
  execution_mode  = var.pipeline_type == "V2" ? var.execution_mode : null

  dynamic "artifact_store" {
    for_each = local.artifact_stores

    content {
      location = artifact_store.value.location
      type     = "S3"
      region   = try(artifact_store.value.region, null)

      dynamic "encryption_key" {
        for_each = try(artifact_store.value.kms_key_arn, null) != null ? [artifact_store.value.kms_key_arn] : []

        content {
          id   = encryption_key.value
          type = "KMS"
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages

    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions

        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = try(action.value.input_artifacts, [])
          output_artifacts = try(action.value.output_artifacts, [])
          role_arn         = try(action.value.role_arn, null)
          run_order        = try(action.value.run_order, null)
          namespace        = try(action.value.namespace, null)
          configuration    = action.value.configuration
        }
      }
    }
  }

  dynamic "trigger" {
    for_each = var.trigger != null ? [var.trigger] : []

    content {
      provider_type = trigger.value.provider_type

      git_configuration {
        source_action_name = trigger.value.git_configuration.source_action_name

        dynamic "push" {
          for_each = try(trigger.value.git_configuration.push, [])

          content {
            dynamic "branches" {
              for_each = try(push.value.branches, null) != null ? [push.value.branches] : []

              content {
                includes = try(branches.value.includes, null)
                excludes = try(branches.value.excludes, null)
              }
            }

            dynamic "tags" {
              for_each = try(push.value.tags, null) != null ? [push.value.tags] : []

              content {
                includes = try(tags.value.includes, null)
                excludes = try(tags.value.excludes, null)
              }
            }
          }
        }
      }
    }
  }

  dynamic "variable" {
    for_each = var.pipeline_type == "V2" ? { for item in var.variables : item.name => item } : {}

    content {
      name          = variable.value.name
      default_value = variable.value.default_value
      description   = try(variable.value.description, null)
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  depends_on = [aws_iam_role_policy.service]
}
