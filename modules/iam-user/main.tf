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
  default_inline_policy_name = "${var.name}-policy"
  all_policy_statements = concat(
    var.policy_statements,
    flatten([for policy in var.inline_policies : policy.policy_statements])
  )
  managed_policy_attachments = merge(
    { for idx, arn in var.managed_policy_arns : "attached-${idx}" => arn },
    var.managed_policy_key_arns
  )
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

check "login_profile_requires_pgp_or_length" {
  assert {
    condition     = !var.create_login_profile || var.login_profile_pgp_key != null || var.login_profile_password_length >= 14
    error_message = "Console login profiles require login_profile_pgp_key to retrieve the generated password, or a valid password_length."
  }
}

resource "aws_iam_user" "user" {
  name                 = var.name
  path                 = var.path
  permissions_boundary = var.permissions_boundary
  force_destroy        = var.force_destroy

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_iam_user_policy" "inline" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  name   = local.default_inline_policy_name
  user   = aws_iam_user.user.name
  policy = data.aws_iam_policy_document.inline_policy[0].json
}

resource "aws_iam_user_policy" "named_inline" {
  for_each = var.inline_policies

  name   = each.key
  user   = aws_iam_user.user.name
  policy = data.aws_iam_policy_document.named_inline_policy[each.key].json
}

resource "aws_iam_user_policy_attachment" "managed" {
  for_each = local.managed_policy_attachments

  user       = aws_iam_user.user.name
  policy_arn = each.value
}

resource "aws_iam_access_key" "access_key" {
  count = var.create_access_key ? 1 : 0

  user    = aws_iam_user.user.name
  status  = var.access_key_status
  pgp_key = var.access_key_pgp_key
}

resource "aws_iam_user_login_profile" "login_profile" {
  count = var.create_login_profile ? 1 : 0

  user                    = aws_iam_user.user.name
  password_reset_required = var.login_profile_password_reset_required
  password_length         = var.login_profile_password_length
  pgp_key                 = var.login_profile_pgp_key
}
