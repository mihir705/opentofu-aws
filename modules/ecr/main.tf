data "aws_caller_identity" "current" {}

locals {
  use_custom_policy = var.policy_json != null
  create_repository_policy = (
    local.use_custom_policy ||
    length(var.policy_statements) > 0
  )

  lifecycle_policy = (
    var.lifecycle_policy_json != null ? var.lifecycle_policy_json :
    length(var.lifecycle_rules) > 0 ? jsonencode({
      rules = [
        for rule in var.lifecycle_rules : {
          rulePriority = rule.rule_priority
          description  = coalesce(
            try(rule.description, null),
            "Lifecycle rule ${rule.rule_priority}"
          )
          selection = merge(
            {
              tagStatus   = rule.tag_status
              countType   = rule.count_type
              countNumber = rule.count_number
            },
            rule.tag_status == "tagged" ? { tagPrefixList = rule.tag_prefix_list } : {},
            rule.count_type == "sinceImagePushed" ? { countUnit = rule.count_unit } : {}
          )
          action = { type = "expire" }
        }
      ]
    }) : null
  )
}

check "kms_key_required" {
  assert {
    condition     = var.encryption_type != "KMS" || var.kms_key_id != null
    error_message = "kms_key_id is required when encryption_type is KMS."
  }
}

check "kms_key_exclusive" {
  assert {
    condition     = var.encryption_type == "KMS" || var.kms_key_id == null
    error_message = "kms_key_id is only supported when encryption_type is KMS."
  }
}

check "policy_source_exclusive" {
  assert {
    condition     = var.policy_json == null || length(var.policy_statements) == 0
    error_message = "policy_json cannot be combined with policy_statements."
  }
}

check "lifecycle_policy_source_exclusive" {
  assert {
    condition     = var.lifecycle_policy_json == null || length(var.lifecycle_rules) == 0
    error_message = "lifecycle_policy_json cannot be combined with lifecycle_rules."
  }
}

check "policy_statement_effects" {
  assert {
    condition = length(var.policy_statements) == 0 || alltrue([
      for statement in var.policy_statements :
      contains(["Allow", "Deny"], statement.effect)
    ])
    error_message = "Each policy statement effect must be Allow or Deny."
  }
}

check "policy_principal_types" {
  assert {
    condition = length(var.policy_statements) == 0 || alltrue([
      for statement in var.policy_statements :
      contains(["AWS", "Service"], statement.principals.type)
    ])
    error_message = "policy_statements.principals.type must be AWS or Service."
  }
}

check "lifecycle_rule_priorities" {
  assert {
    condition = length(var.lifecycle_rules) == 0 || alltrue([
      for rule in var.lifecycle_rules :
      rule.rule_priority >= 1 && rule.rule_priority <= 1000
    ])
    error_message = "Each lifecycle rule_priority must be between 1 and 1000."
  }
}

check "lifecycle_rule_tag_status" {
  assert {
    condition = length(var.lifecycle_rules) == 0 || alltrue([
      for rule in var.lifecycle_rules :
      contains(["tagged", "untagged", "any"], rule.tag_status)
    ])
    error_message = "lifecycle_rules.tag_status must be tagged, untagged, or any."
  }
}

check "lifecycle_rule_tag_prefix" {
  assert {
    condition = length(var.lifecycle_rules) == 0 || alltrue([
      for rule in var.lifecycle_rules :
      rule.tag_status != "tagged" || length(rule.tag_prefix_list) > 0
    ])
    error_message = "lifecycle_rules with tag_status = tagged require tag_prefix_list."
  }
}

check "lifecycle_rule_count_type" {
  assert {
    condition = length(var.lifecycle_rules) == 0 || alltrue([
      for rule in var.lifecycle_rules :
      contains(["imageCountMoreThan", "sinceImagePushed"], rule.count_type)
    ])
    error_message = "lifecycle_rules.count_type must be imageCountMoreThan or sinceImagePushed."
  }
}

check "lifecycle_rule_count_unit" {
  assert {
    condition = length(var.lifecycle_rules) == 0 || alltrue([
      for rule in var.lifecycle_rules :
      rule.count_type != "sinceImagePushed" || try(rule.count_unit, null) != null
    ])
    error_message = "lifecycle_rules with count_type = sinceImagePushed require count_unit."
  }
}

check "lifecycle_rule_count_number" {
  assert {
    condition = length(var.lifecycle_rules) == 0 || alltrue([
      for rule in var.lifecycle_rules :
      rule.count_number >= 1
    ])
    error_message = "Each lifecycle_rules.count_number must be at least 1."
  }
}

data "aws_iam_policy_document" "repository_policy" {
  count = local.use_custom_policy || length(var.policy_statements) == 0 ? 0 : 1

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = length(statement.value.resources) > 0 ? statement.value.resources : [aws_ecr_repository.repository.arn]

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

resource "aws_ecr_repository" "repository" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_id : null
  }

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_ecr_repository_policy" "policy" {
  count = local.create_repository_policy ? 1 : 0

  repository = aws_ecr_repository.repository.name
  policy = (
    local.use_custom_policy ?
    var.policy_json :
    data.aws_iam_policy_document.repository_policy[0].json
  )
}

resource "aws_ecr_lifecycle_policy" "lifecycle" {
  count = local.lifecycle_policy != null ? 1 : 0

  repository = aws_ecr_repository.repository.name
  policy     = local.lifecycle_policy
}
