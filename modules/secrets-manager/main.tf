locals {
  create_random_password = var.generate_random_password != null
  create_version         = var.secret_string != null || var.secret_binary != null || local.create_random_password

  secret_string_value = local.create_random_password ? (
    try(var.generate_random_password.username, null) != null ? jsonencode({
      username = var.generate_random_password.username
      password = random_password.secret[0].result
    }) : random_password.secret[0].result
  ) : var.secret_string

  secret_binary_value = local.create_random_password ? null : var.secret_binary
}

check "name_exclusive" {
  assert {
    condition     = (var.name != null) != (var.name_prefix != null)
    error_message = "Exactly one of name or name_prefix must be set."
  }
}

check "secret_value_exclusive" {
  assert {
    condition = (
      (var.secret_string == null ? 0 : 1) +
      (var.secret_binary == null ? 0 : 1) +
      (var.generate_random_password == null ? 0 : 1)
    ) <= 1
    error_message = "Only one of secret_string, secret_binary, or generate_random_password may be set."
  }
}

check "rotation_requires_version" {
  assert {
    condition     = var.rotation == null || local.create_version
    error_message = "rotation requires a secret value via secret_string, secret_binary, or generate_random_password."
  }
}

resource "random_password" "secret" {
  count = local.create_random_password ? 1 : 0

  length           = var.generate_random_password.length
  special          = var.generate_random_password.special
  override_special = var.generate_random_password.override_special
}

resource "aws_secretsmanager_secret" "secret" {
  name                    = var.name
  name_prefix             = var.name_prefix
  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days

  dynamic "replica" {
    for_each = var.replica_regions

    content {
      region     = replica.value.region
      kms_key_id = try(replica.value.kms_key_id, null)
    }
  }

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "version" {
  count = local.create_version && !var.ignore_secret_changes ? 1 : 0

  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = local.secret_string_value
  secret_binary = local.secret_binary_value
}

resource "aws_secretsmanager_secret_version" "version_external" {
  count = local.create_version && var.ignore_secret_changes ? 1 : 0

  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = local.secret_string_value
  secret_binary = local.secret_binary_value

  lifecycle {
    ignore_changes = [secret_string, secret_binary]
  }
}

resource "aws_secretsmanager_secret_rotation" "rotation" {
  count = var.rotation != null ? 1 : 0

  secret_id           = aws_secretsmanager_secret.secret.id
  rotation_lambda_arn = var.rotation.lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation.automatically_after_days
  }

  depends_on = [
    aws_secretsmanager_secret_version.version,
    aws_secretsmanager_secret_version.version_external,
  ]
}

resource "aws_secretsmanager_secret_policy" "policy" {
  count = var.resource_policy_json != null ? 1 : 0

  secret_arn = aws_secretsmanager_secret.secret.arn
  policy     = var.resource_policy_json
}
