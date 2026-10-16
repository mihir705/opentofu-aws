locals {
  use_custom_policy = var.policy_json != null

  queue_name_tag = (
    var.name != null ? var.name :
    var.name_prefix != null ? "${var.name_prefix}-queue" :
    "sqs-queue"
  )

  dlq_name = (
    var.dlq_name != null ? var.dlq_name :
    var.name != null ? (
      var.fifo_queue ? replace(var.name, ".fifo", "-dlq.fifo") : "${var.name}-dlq"
    ) : null
  )

  redrive_policy = (
    var.redrive_policy != null ? var.redrive_policy :
    var.create_dlq ? jsonencode({
      deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
      maxReceiveCount     = var.max_receive_count
    }) : null
  )

  sns_policy_statements = [
    for arn in var.allowed_sns_topic_arns : {
      sid    = "AllowSNSTopic-${replace(replace(arn, ":", "-"), "/", "-")}"
      effect = "Allow"
      actions = [
        "sqs:SendMessage",
      ]
      resources = []
      principals = {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }
      conditions = [{
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [arn]
      }]
    }
  ]

  merged_policy_statements = concat(local.sns_policy_statements, var.policy_statements)

  create_queue_policy = (
    local.use_custom_policy ||
    length(local.merged_policy_statements) > 0
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
      var.fifo_queue == endswith(var.name, ".fifo")
    )
    error_message = "FIFO queues require a name ending with .fifo; standard queues must not use the .fifo suffix."
  }
}

check "content_based_deduplication_fifo_only" {
  assert {
    condition     = !var.content_based_deduplication || var.fifo_queue
    error_message = "content_based_deduplication is only supported for FIFO queues."
  }
}

check "deduplication_scope_values" {
  assert {
    condition = !var.fifo_queue || (
      try(var.deduplication_scope, null) == null ||
      contains(["messageGroup", "queue"], var.deduplication_scope)
    )
    error_message = "deduplication_scope must be messageGroup or queue for FIFO queues."
  }
}

check "fifo_throughput_limit_values" {
  assert {
    condition = !var.fifo_queue || (
      try(var.fifo_throughput_limit, null) == null ||
      contains(["perQueue", "perMessageGroupId"], var.fifo_throughput_limit)
    )
    error_message = "fifo_throughput_limit must be perQueue or perMessageGroupId for FIFO queues."
  }
}

check "delay_seconds_range" {
  assert {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900
    error_message = "delay_seconds must be between 0 and 900."
  }
}

check "max_message_size_range" {
  assert {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "max_message_size must be between 1024 and 262144."
  }
}

check "message_retention_range" {
  assert {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds must be between 60 and 1209600."
  }
}

check "receive_wait_time_range" {
  assert {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "receive_wait_time_seconds must be between 0 and 20."
  }
}

check "visibility_timeout_range" {
  assert {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds must be between 0 and 43200."
  }
}

check "kms_data_key_reuse_period_range" {
  assert {
    condition = var.kms_data_key_reuse_period_seconds == null || (
      var.kms_data_key_reuse_period_seconds >= 60 && var.kms_data_key_reuse_period_seconds <= 86400
    )
    error_message = "kms_data_key_reuse_period_seconds must be between 60 and 86400."
  }
}

check "redrive_source_exclusive" {
  assert {
    condition     = var.redrive_policy == null || !var.create_dlq
    error_message = "redrive_policy cannot be combined with create_dlq."
  }
}

check "max_receive_count_range" {
  assert {
    condition     = !var.create_dlq || (var.max_receive_count >= 1 && var.max_receive_count <= 1000)
    error_message = "max_receive_count must be between 1 and 1000 when create_dlq is true."
  }
}

check "create_dlq_requires_name" {
  assert {
    condition     = !var.create_dlq || var.name != null
    error_message = "create_dlq requires an explicit queue name."
  }
}

check "dlq_fifo_name_suffix" {
  assert {
    condition = !var.create_dlq || local.dlq_name == null || (
      var.fifo_queue == endswith(local.dlq_name, ".fifo")
    )
    error_message = "FIFO dead-letter queue names must end with .fifo."
  }
}

check "high_throughput_mode_consistency" {
  assert {
    condition = !var.fifo_queue || (
      try(var.deduplication_scope, null) != "messageGroup" ||
      try(var.fifo_throughput_limit, null) == "perMessageGroupId"
    )
    error_message = "High-throughput FIFO requires fifo_throughput_limit = perMessageGroupId when deduplication_scope = messageGroup."
  }
}

check "policy_source_exclusive" {
  assert {
    condition     = var.policy_json == null || length(var.policy_statements) == 0
    error_message = "policy_json cannot be combined with policy_statements."
  }
}

check "policy_json_sns_exclusive" {
  assert {
    condition     = var.policy_json == null || length(var.allowed_sns_topic_arns) == 0
    error_message = "policy_json cannot be combined with allowed_sns_topic_arns."
  }
}

check "encryption_source_exclusive" {
  assert {
    condition     = var.kms_key_id == null || !var.sqs_managed_sse_enabled
    error_message = "kms_key_id cannot be combined with sqs_managed_sse_enabled = true. Set sqs_managed_sse_enabled = false when using KMS."
  }
}

data "aws_iam_policy_document" "queue_policy" {
  count = local.use_custom_policy || !local.create_queue_policy ? 0 : 1

  dynamic "statement" {
    for_each = local.merged_policy_statements

    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = length(statement.value.resources) > 0 ? statement.value.resources : [aws_sqs_queue.queue.arn]

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

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                        = local.dlq_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  kms_master_key_id           = var.kms_key_id
  sqs_managed_sse_enabled     = var.kms_key_id == null ? var.sqs_managed_sse_enabled : null
  message_retention_seconds   = var.message_retention_seconds

  tags = merge(var.tags, {
    Name = local.dlq_name
  })
}

resource "aws_sqs_queue" "queue" {
  name                        = var.name
  name_prefix                 = var.name_prefix
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  deduplication_scope         = var.fifo_queue ? try(var.deduplication_scope, null) : null
  fifo_throughput_limit       = var.fifo_queue ? try(var.fifo_throughput_limit, null) : null
  delay_seconds               = var.delay_seconds
  max_message_size            = var.max_message_size
  message_retention_seconds   = var.message_retention_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  kms_master_key_id           = var.kms_key_id
  sqs_managed_sse_enabled     = var.kms_key_id == null ? var.sqs_managed_sse_enabled : null
  kms_data_key_reuse_period_seconds = var.kms_key_id != null ? try(var.kms_data_key_reuse_period_seconds, null) : null
  redrive_policy              = local.redrive_policy
  redrive_allow_policy        = try(var.redrive_allow_policy, null)

  tags = merge(var.tags, {
    Name = local.queue_name_tag
  })
}

resource "aws_sqs_queue_policy" "policy" {
  count = local.create_queue_policy ? 1 : 0

  queue_url = aws_sqs_queue.queue.id
  policy    = local.use_custom_policy ? var.policy_json : data.aws_iam_policy_document.queue_policy[0].json
}
