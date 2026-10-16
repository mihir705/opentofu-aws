data "aws_caller_identity" "current" {}

locals {
  use_custom_policy = var.policy_json != null

  lambda_subscriptions = {
    for key, subscription in var.subscriptions :
    key => subscription
    if subscription.protocol == "lambda" && try(subscription.lambda_function_name, null) != null
  }

  topic_name_tag = (
    var.name != null ? var.name :
    var.name_prefix != null ? "${var.name_prefix}-topic" :
    "sns-topic"
  )
}

check "name_exclusive" {
  assert {
    condition     = (var.name != null) != (var.name_prefix != null)
    error_message = "Exactly one of name or name_prefix must be set."
  }
}

check "fifo_name_suffix" {
  assert {
    condition = var.name == null || (
      var.fifo_topic == endswith(var.name, ".fifo")
    )
    error_message = "FIFO topics require a name ending with .fifo; standard topics must not use the .fifo suffix."
  }
}

check "fifo_throughput_scope_values" {
  assert {
    condition = !var.fifo_topic || (
      try(var.fifo_throughput_scope, null) == null ||
      contains(["Topic", "MessageGroup"], var.fifo_throughput_scope)
    )
    error_message = "fifo_throughput_scope must be Topic or MessageGroup for FIFO topics."
  }
}

check "archive_policy_fifo_only" {
  assert {
    condition     = var.archive_policy == null || var.fifo_topic
    error_message = "archive_policy is only supported for FIFO topics."
  }
}

check "content_based_deduplication_fifo_only" {
  assert {
    condition     = !var.content_based_deduplication || var.fifo_topic
    error_message = "content_based_deduplication is only supported for FIFO topics."
  }
}

check "fifo_subscription_protocols" {
  assert {
    condition = !var.fifo_topic || alltrue([
      for subscription in var.subscriptions :
      !contains(["email", "email-json", "sms", "http", "https"], subscription.protocol)
    ])
    error_message = "FIFO topics cannot use email, email-json, sms, http, or https subscriptions."
  }
}

check "policy_source_exclusive" {
  assert {
    condition     = var.policy_json == null || length(var.policy_statements) == 0
    error_message = "policy_json cannot be combined with policy_statements."
  }
}

check "subscription_protocols" {
  assert {
    condition = alltrue([
      for subscription in var.subscriptions :
      contains([
        "sqs",
        "lambda",
        "email",
        "email-json",
        "sms",
        "application",
        "http",
        "https",
        "firehose",
      ], subscription.protocol)
    ])
    error_message = "subscription protocol must be sqs, lambda, email, email-json, sms, application, http, https, or firehose."
  }
}

check "subscription_endpoints" {
  assert {
    condition = alltrue([
      for subscription in var.subscriptions :
      try(subscription.endpoint, null) != null || (
        subscription.protocol == "lambda" && try(subscription.lambda_function_name, null) != null
      )
    ])
    error_message = "Each subscription requires endpoint or lambda_function_name for lambda protocol."
  }
}

check "lambda_subscription_names" {
  assert {
    condition = alltrue([
      for subscription in var.subscriptions :
      subscription.protocol != "lambda" || try(subscription.lambda_function_name, null) != null
    ])
    error_message = "lambda subscriptions require lambda_function_name for invoke permissions."
  }
}

check "filter_policy_scope_values" {
  assert {
    condition = alltrue([
      for subscription in var.subscriptions :
      try(subscription.filter_policy_scope, null) == null ||
      contains(["MessageAttributes", "MessageBody"], subscription.filter_policy_scope)
    ])
    error_message = "filter_policy_scope must be MessageAttributes or MessageBody."
  }
}

check "http_auto_confirm_protocols" {
  assert {
    condition = alltrue([
      for subscription in var.subscriptions :
      !subscription.endpoint_auto_confirms || contains(["http", "https"], subscription.protocol)
    ])
    error_message = "endpoint_auto_confirms is only supported for http and https subscriptions."
  }
}

data "aws_iam_policy_document" "topic_policy" {
  count = local.use_custom_policy || length(var.policy_statements) == 0 ? 0 : 1

  statement {
    sid    = "EnableAccountOwner"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "SNS:Subscribe",
      "SNS:Receive",
    ]

    resources = [aws_sns_topic.topic.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = length(statement.value.resources) > 0 ? statement.value.resources : [aws_sns_topic.topic.arn]

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

resource "aws_sns_topic" "topic" {
  name                        = var.name
  name_prefix                 = var.name_prefix
  display_name                = var.display_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null
  fifo_throughput_scope       = var.fifo_topic ? try(var.fifo_throughput_scope, null) : null
  kms_master_key_id           = var.kms_key_id
  delivery_policy             = var.delivery_policy
  archive_policy              = var.fifo_topic ? try(var.archive_policy, null) : null

  tags = merge(var.tags, {
    Name = local.topic_name_tag
  })
}

resource "aws_sns_topic_policy" "policy" {
  count = local.use_custom_policy || length(var.policy_statements) > 0 ? 1 : 0

  arn    = aws_sns_topic.topic.arn
  policy = local.use_custom_policy ? var.policy_json : data.aws_iam_policy_document.topic_policy[0].json
}

resource "aws_sns_topic_subscription" "subscription" {
  for_each = var.subscriptions

  topic_arn = aws_sns_topic.topic.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint

  endpoint_auto_confirms          = try(each.value.endpoint_auto_confirms, false)
  confirmation_timeout_in_minutes = try(each.value.confirmation_timeout_in_minutes, null)
  raw_message_delivery            = try(each.value.raw_message_delivery, false)
  filter_policy                   = try(each.value.filter_policy, null)
  filter_policy_scope             = try(each.value.filter_policy_scope, null)
  redrive_policy                  = try(each.value.redrive_policy, null)
  subscription_role_arn           = try(each.value.subscription_role_arn, null)

  depends_on = [aws_lambda_permission.sns]
}

resource "aws_lambda_permission" "sns" {
  for_each = local.lambda_subscriptions

  statement_id  = "AllowExecutionFromSNS-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.topic.arn
}
