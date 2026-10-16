data "aws_caller_identity" "current" {}

locals {
  use_custom_policy = var.key_policy_json != null
  create_replica    = var.multi_region && var.replica_region != null

  aliases = {
    for alias in var.aliases : alias => startswith(alias, "alias/") ? alias : "alias/${alias}"
  }

  service_permissions = {
    s3 = {
      sid     = "AllowS3Service"
      service = "s3.amazonaws.com"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
    }
    secretsmanager = {
      sid     = "AllowSecretsManagerService"
      service = "secretsmanager.amazonaws.com"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:DescribeKey",
      ]
    }
  }
}

check "replica_requires_multi_region" {
  assert {
    condition     = var.replica_region == null || var.multi_region
    error_message = "replica_region requires multi_region = true."
  }
}

check "key_policy_exclusive" {
  assert {
    condition     = var.key_policy_json == null || (length(var.policy_statements) == 0 && length(var.allowed_services) == 0)
    error_message = "key_policy_json cannot be combined with policy_statements or allowed_services."
  }
}

data "aws_iam_policy_document" "key_policy" {
  count = local.use_custom_policy ? 0 : 1

  statement {
    sid    = "EnableRootAccountPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = {
      for service in var.allowed_services : service => local.service_permissions[service]
    }

    content {
      sid    = statement.value.sid
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = [statement.value.service]
      }

      actions   = statement.value.actions
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      principals {
        type        = statement.value.principals.type
        identifiers = statement.value.principals.identifiers
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

locals {
  key_policy = coalesce(var.key_policy_json, data.aws_iam_policy_document.key_policy[0].json)
}

resource "aws_kms_key" "key" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region
  policy                  = local.key_policy

  tags = var.tags
}

resource "aws_kms_replica_key" "replica" {
  count = local.create_replica ? 1 : 0

  provider = aws.replica

  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  primary_key_arn         = aws_kms_key.key.arn
  policy                  = local.key_policy

  tags = var.tags
}

resource "aws_kms_alias" "alias" {
  for_each = local.aliases

  name          = each.value
  target_key_id = aws_kms_key.key.key_id
}
