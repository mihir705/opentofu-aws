data "aws_iam_policy_document" "assume_role" {
  count = var.assume_role_policy_json == null ? 1 : 0

  dynamic "statement" {
    for_each = length(var.trust_services) > 0 ? [1] : []

    content {
      effect  = "Allow"
      actions = var.assume_role_actions

      principals {
        type        = "Service"
        identifiers = var.trust_services
      }

      dynamic "condition" {
        for_each = var.assume_role_conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.trust_principals

    content {
      effect  = "Allow"
      actions = var.assume_role_actions

      principals {
        type        = statement.value.type
        identifiers = statement.value.identifiers
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

data "aws_iam_policy_document" "inline_policy" {
  count = length(var.policy_statements) > 0 ? 1 : 0

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

data "aws_iam_policy_document" "named_inline_policy" {
  for_each = var.inline_policies

  dynamic "statement" {
    for_each = each.value.policy_statements

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
  assume_role_policy      = coalesce(var.assume_role_policy_json, try(data.aws_iam_policy_document.assume_role[0].json, null))
  default_inline_policy_name = "${var.name}-policy"
  instance_profile_name   = coalesce(var.instance_profile_name, var.name)
  all_policy_statements = concat(
    var.policy_statements,
    flatten([for policy in var.inline_policies : policy.policy_statements])
  )
  managed_policy_attachments = merge(
    { for idx, arn in var.managed_policy_arns : "attached-${idx}" => arn },
    var.managed_policy_key_arns
  )
}

check "trust_policy_required" {
  assert {
    condition = var.assume_role_policy_json != null || (
      length(var.trust_services) > 0 || length(var.trust_principals) > 0
    )
    error_message = "Provide assume_role_policy_json or at least one trust_services/trust_principals entry."
  }
}

check "trust_policy_source_exclusive" {
  assert {
    condition = var.assume_role_policy_json == null || (
      length(var.trust_services) == 0 &&
      length(var.trust_principals) == 0 &&
      length(var.assume_role_conditions) == 0
    )
    error_message = "When assume_role_policy_json is set, omit trust_services, trust_principals, and assume_role_conditions."
  }
}

check "instance_profile_name_length" {
  assert {
    condition     = !var.create_instance_profile || length(local.instance_profile_name) <= 128
    error_message = "instance_profile_name must be 128 characters or fewer."
  }
}

check "inline_policy_name_collision" {
  assert {
    condition     = !contains(keys(var.inline_policies), local.default_inline_policy_name)
    error_message = "inline_policies cannot include a key matching the default inline policy name (${local.default_inline_policy_name})."
  }
}

check "inline_policy_name_length" {
  assert {
    condition = alltrue([
      for policy_name in keys(var.inline_policies) : length(policy_name) <= 128
    ])
    error_message = "Each inline_policies key must be 128 characters or fewer."
  }
}

check "policy_statement_effects" {
  assert {
    condition = alltrue([
      for statement in local.all_policy_statements :
      contains(["Allow", "Deny"], statement.effect)
    ])
    error_message = "Each policy statement effect must be Allow or Deny."
  }
}

check "policy_statement_actions" {
  assert {
    condition = alltrue([
      for statement in local.all_policy_statements :
      length(statement.actions) > 0 || length(statement.not_actions) > 0
    ])
    error_message = "Each policy statement must define actions or not_actions."
  }
}

check "policy_statement_resources" {
  assert {
    condition = alltrue([
      for statement in local.all_policy_statements :
      length(statement.resources) > 0 || length(statement.not_resources) > 0
    ])
    error_message = "Each policy statement must define resources or not_resources."
  }
}

resource "aws_iam_role" "role" {
  name                  = var.name
  description           = var.description
  path                  = var.path
  max_session_duration  = var.max_session_duration
  permissions_boundary  = var.permissions_boundary
  force_detach_policies = var.force_detach_policies
  assume_role_policy    = local.assume_role_policy

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "inline" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  name   = local.default_inline_policy_name
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.inline_policy[0].json
}

resource "aws_iam_role_policy" "named_inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.named_inline_policy[each.key].json
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.managed_policy_attachments

  role       = aws_iam_role.role.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "profile" {
  count = var.create_instance_profile ? 1 : 0

  name = local.instance_profile_name
  path = var.path
  role = aws_iam_role.role.name

  tags = merge(var.tags, {
    Name = local.instance_profile_name
  })
}
