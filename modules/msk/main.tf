data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)

  id = each.value
}

locals {
  subnet_availability_zones = distinct([
    for subnet in data.aws_subnet.selected : subnet.availability_zone
  ])

  encryption_in_transit = {
    client_broker = try(var.encryption_in_transit.client_broker, "TLS")
    in_cluster    = try(var.encryption_in_transit.in_cluster, true)
  }

  client_authentication = {
    unauthenticated = try(var.client_authentication.unauthenticated, false)
    sasl = {
      scram = try(var.client_authentication.sasl.scram, false)
      iam   = try(var.client_authentication.sasl.iam, false)
    }
    tls = {
      certificate_authority_arns = coalesce(try(var.client_authentication.tls.certificate_authority_arns, null), [])
    }
  }

  create_configuration = try(var.configuration.create, false)
  use_configuration = local.create_configuration || (
    try(var.configuration.arn, null) != null && try(var.configuration.revision, null) != null
  )

  cloudwatch_logging_enabled = try(var.logging.cloudwatch.enabled, false)
  cloudwatch_log_group_name = local.cloudwatch_logging_enabled ? coalesce(
    try(var.logging.cloudwatch.log_group_name, null),
    try(aws_cloudwatch_log_group.msk[0].name, null)
  ) : null

  logging_enabled = var.logging != null && (
    local.cloudwatch_logging_enabled ||
    try(var.logging.s3.enabled, false) ||
    try(var.logging.firehose.enabled, false)
  )

  open_monitoring_enabled = var.open_monitoring != null && (
    try(var.open_monitoring.jmx_exporter_enabled, false) ||
    try(var.open_monitoring.node_exporter_enabled, false)
  )

  ebs_provisioned_throughput_enabled = try(var.ebs_provisioned_throughput.enabled, false)

  server_properties = join("\n", [
    for key, value in try(var.configuration.server_properties, {}) : "${key}=${value}"
  ])
}

check "subnet_ids_required" {
  assert {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet_ids are required for MSK broker placement."
  }
}

check "security_group_ids_required" {
  assert {
    condition     = length(var.security_group_ids) > 0
    error_message = "At least one security_group_id is required."
  }
}

check "broker_nodes_multiple_of_subnets" {
  assert {
    condition     = var.number_of_broker_nodes % length(var.subnet_ids) == 0
    error_message = "number_of_broker_nodes must be a multiple of the number of subnet_ids."
  }
}

check "subnet_availability_zones" {
  assert {
    condition     = length(local.subnet_availability_zones) >= 2
    error_message = "subnet_ids must span at least two availability zones."
  }
}

check "encryption_in_transit_client_broker" {
  assert {
    condition     = contains(["TLS", "PLAINTEXT", "TLS_PLAINTEXT"], local.encryption_in_transit.client_broker)
    error_message = "encryption_in_transit.client_broker must be TLS, PLAINTEXT, or TLS_PLAINTEXT."
  }
}

check "configuration_source_exclusive" {
  assert {
    condition = var.configuration == null || !(
      try(var.configuration.create, false) &&
      try(var.configuration.arn, null) != null
    )
    error_message = "Use either configuration.create or configuration.arn, not both."
  }
}

check "configuration_create_requires_properties" {
  assert {
    condition = var.configuration == null || !try(var.configuration.create, false) || (
      length(try(var.configuration.server_properties, {})) > 0
    )
    error_message = "configuration.server_properties is required when configuration.create is true."
  }
}

check "configuration_attach_requires_revision" {
  assert {
    condition = var.configuration == null || try(var.configuration.arn, null) == null || (
      try(var.configuration.revision, null) != null
    )
    error_message = "configuration.revision is required when configuration.arn is set."
  }
}

check "scram_secrets_required" {
  assert {
    condition     = !local.client_authentication.sasl.scram || length(var.scram_secret_arns) > 0
    error_message = "scram_secret_arns is required when SASL/SCRAM authentication is enabled."
  }
}

check "s3_logging_requires_bucket" {
  assert {
    condition = var.logging == null || !try(var.logging.s3.enabled, false) || (
      try(var.logging.s3.bucket, null) != null && var.logging.s3.bucket != ""
    )
    error_message = "logging.s3.bucket is required when S3 logging is enabled."
  }
}

check "firehose_logging_requires_stream" {
  assert {
    condition = var.logging == null || !try(var.logging.firehose.enabled, false) || (
      try(var.logging.firehose.delivery_stream, null) != null && var.logging.firehose.delivery_stream != ""
    )
    error_message = "logging.firehose.delivery_stream is required when Firehose logging is enabled."
  }
}

check "ebs_provisioned_throughput_required" {
  assert {
    condition = !local.ebs_provisioned_throughput_enabled || (
      try(var.ebs_provisioned_throughput.volume_throughput, null) != null
    )
    error_message = "ebs_provisioned_throughput.volume_throughput is required when provisioned throughput is enabled."
  }
}

resource "aws_cloudwatch_log_group" "msk" {
  count = local.cloudwatch_logging_enabled && try(var.logging.cloudwatch.log_group_name, null) == null ? 1 : 0

  name              = "/aws/msk/${var.name}"
  retention_in_days = try(var.logging.cloudwatch.retention_in_days, 30)

  tags = merge(var.tags, {
    Name = "${var.name}-broker-logs"
  })
}

resource "aws_msk_configuration" "this" {
  count = local.create_configuration ? 1 : 0

  name              = coalesce(try(var.configuration.name, null), "${var.name}-config")
  kafka_versions    = [var.kafka_version]
  server_properties = local.server_properties

  description = "MSK configuration for ${var.name}"
}

resource "aws_msk_cluster" "cluster" {
  cluster_name           = var.name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes
  enhanced_monitoring    = var.enhanced_monitoring
  storage_mode           = var.storage_mode

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.subnet_ids
    security_groups = var.security_group_ids

    storage_info {
      ebs_storage_info {
        volume_size = var.ebs_volume_size

        dynamic "provisioned_throughput" {
          for_each = local.ebs_provisioned_throughput_enabled ? [var.ebs_provisioned_throughput] : []

          content {
            enabled           = true
            volume_throughput = provisioned_throughput.value.volume_throughput
          }
        }
      }
    }

    connectivity_info {
      public_access {
        type = var.public_access
      }
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = var.kms_key_id

    encryption_in_transit {
      client_broker = local.encryption_in_transit.client_broker
      in_cluster    = local.encryption_in_transit.in_cluster
    }
  }

  dynamic "client_authentication" {
    for_each = (
      local.client_authentication.unauthenticated ||
      local.client_authentication.sasl.scram ||
      local.client_authentication.sasl.iam ||
      length(local.client_authentication.tls.certificate_authority_arns) > 0
    ) ? [local.client_authentication] : []

    content {
      unauthenticated = client_authentication.value.unauthenticated

      dynamic "sasl" {
        for_each = (
          client_authentication.value.sasl.scram ||
          client_authentication.value.sasl.iam
        ) ? [client_authentication.value.sasl] : []

        content {
          scram = sasl.value.scram
          iam   = sasl.value.iam
        }
      }

      dynamic "tls" {
        for_each = length(client_authentication.value.tls.certificate_authority_arns) > 0 ? [client_authentication.value.tls] : []

        content {
          certificate_authority_arns = tls.value.certificate_authority_arns
        }
      }
    }
  }

  dynamic "configuration_info" {
    for_each = local.use_configuration ? [1] : []

    content {
      arn = local.create_configuration ? aws_msk_configuration.this[0].arn : var.configuration.arn
      revision = local.create_configuration ? aws_msk_configuration.this[0].latest_revision : var.configuration.revision
    }
  }

  dynamic "logging_info" {
    for_each = local.logging_enabled ? [var.logging] : []

    content {
      broker_logs {
        dynamic "cloudwatch_logs" {
          for_each = local.cloudwatch_logging_enabled ? [logging_info.value.cloudwatch] : []

          content {
            enabled   = true
            log_group = local.cloudwatch_log_group_name
          }
        }

        dynamic "s3" {
          for_each = try(logging_info.value.s3.enabled, false) ? [logging_info.value.s3] : []

          content {
            enabled = true
            bucket  = s3.value.bucket
            prefix  = try(s3.value.prefix, "")
          }
        }

        dynamic "firehose" {
          for_each = try(logging_info.value.firehose.enabled, false) ? [logging_info.value.firehose] : []

          content {
            enabled         = true
            delivery_stream = firehose.value.delivery_stream
          }
        }
      }
    }
  }

  dynamic "open_monitoring" {
    for_each = local.open_monitoring_enabled ? [var.open_monitoring] : []

    content {
      prometheus {
        jmx_exporter {
          enabled_in_broker = try(open_monitoring.value.jmx_exporter_enabled, false)
        }
        node_exporter {
          enabled_in_broker = try(open_monitoring.value.node_exporter_enabled, false)
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_msk_single_scram_secret_association" "scram" {
  for_each = toset(var.scram_secret_arns)

  cluster_arn = aws_msk_cluster.cluster.arn
  secret_arn  = each.value
}
