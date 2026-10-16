data "aws_iam_policy_document" "policy" {
  count = var.policy_json == null ? 1 : 0

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid           = try(statement.value.sid, null)
      effect        = statement.value.effect
      actions       = length(statement.value.actions) > 0 ? statement.value.actions : null
      not_actions   = length(statement.value.not_actions) > 0 ? statement.value.not_actions : null
      resources     = length(statement.value.resources) > 0 ? statement.value.resources : null
      not_resources = length(statement.value.not_resources) > 0 ? statement.value.not_resources : null

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
  use_custom_policy = var.policy_json != null
  policy_document   = local.use_custom_policy ? var.policy_json : data.aws_iam_policy_document.policy[0].json
  policy_name_tag = (
    var.name != null ? var.name :
    var.name_prefix != null ? "${var.name_prefix}-policy" :
    "iam-policy"
  )
}

check "name_exclusive" {
  assert {
    condition     = (var.name != null) != (var.name_prefix != null)
    error_message = "Exactly one of name or name_prefix must be set."
  }
}

check "policy_source_exclusive" {
  assert {
    condition     = var.policy_json == null || length(var.policy_statements) == 0
    error_message = "policy_json cannot be combined with policy_statements."
  }
}

check "policy_required" {
  assert {
    condition     = var.policy_json != null || length(var.policy_statements) > 0
    error_message = "Provide policy_json or at least one policy_statements entry."
  }
}

check "policy_statement_effects" {
  assert {
    condition = var.policy_json != null || alltrue([
      for statement in var.policy_statements :
      contains(["Allow", "Deny"], statement.effect)
    ])
    error_message = "Each policy statement effect must be Allow or Deny."
  }
}

check "policy_statement_actions" {
  assert {
    condition = var.policy_json != null || alltrue([
      for statement in var.policy_statements :
      length(statement.actions) > 0 || length(statement.not_actions) > 0
    ])
    error_message = "Each policy statement must define actions or not_actions."
  }
}

check "policy_statement_resources" {
  assert {
    condition = var.policy_json != null || alltrue([
      for statement in var.policy_statements :
      length(statement.resources) > 0 || length(statement.not_resources) > 0
    ])
    error_message = "Each policy statement must define resources or not_resources."
  }
}

resource "aws_iam_policy" "policy" {
  name        = var.name
  name_prefix = var.name_prefix
  description = var.description
  path        = var.path
  policy      = local.policy_document

  tags = merge(var.tags, {
    Name = local.policy_name_tag
  })
}
