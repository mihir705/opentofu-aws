resource "random_password" "master" {
  count = var.generate_password != null ? 1 : 0

  length           = var.generate_password.length
  special          = var.generate_password.special
  override_special = var.generate_password.override_special
}

data "aws_subnet" "selected" {
  for_each = var.create_db_subnet_group ? toset(var.subnet_ids) : toset([])

  id = each.value
}

data "aws_rds_engine_version" "selected" {
  count = var.engine_version == null ? 1 : 0

  engine  = var.engine
  version = var.engine_version_lookup.version
  latest  = var.engine_version_lookup.latest
}

locals {
  engine_version = coalesce(var.engine_version, try(data.aws_rds_engine_version.selected[0].version, null))

  db_subnet_group_name = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  master_password = (
    var.manage_master_user_password ? null : coalesce(
      var.password,
      try(random_password.master[0].result, null)
    )
  )
  final_snapshot_identifier = coalesce(var.final_snapshot_identifier, "${var.identifier}-final-snapshot")

  subnet_availability_zones = distinct([
    for subnet in data.aws_subnet.selected : subnet.availability_zone
  ])

  engine_cloudwatch_logs = {
    mysql        = ["audit", "error", "general", "iam-db-auth-error", "slowquery"]
    postgres     = ["postgresql", "upgrade"]
    mariadb      = ["audit", "error", "general", "iam-db-auth-error", "slowquery"]
    sqlserver-ex = ["agent", "error"]
    sqlserver-se = ["agent", "error"]
    sqlserver-ee = ["agent", "error"]
    sqlserver-web = ["agent", "error"]
    oracle-ee    = ["alert", "audit", "listener", "trace", "oemagent"]
    oracle-se2   = ["alert", "audit", "listener", "trace", "oemagent"]
  }

  allowed_cloudwatch_logs = local.engine_cloudwatch_logs[var.engine]
}

check "engine_version_source_required" {
  assert {
    condition     = var.engine_version != null || var.engine_version_lookup != null
    error_message = "Provide engine_version or engine_version_lookup."
  }
}

check "engine_version_source_exclusive" {
  assert {
    condition     = var.engine_version == null || var.engine_version_lookup == null
    error_message = "Use either engine_version or engine_version_lookup, not both."
  }
}

check "subnet_source_required" {
  assert {
    condition = var.create_db_subnet_group ? length(var.subnet_ids) >= 2 : (
      try(var.db_subnet_group_name, null) != null && var.db_subnet_group_name != ""
    )
    error_message = "Provide at least two subnet_ids when create_db_subnet_group is true, or set db_subnet_group_name when create_db_subnet_group is false."
  }
}

check "subnet_availability_zones" {
  assert {
    condition     = !var.create_db_subnet_group || length(local.subnet_availability_zones) >= 2
    error_message = "subnet_ids must span at least two availability zones."
  }
}

check "security_groups_required" {
  assert {
    condition     = length(var.vpc_security_group_ids) > 0
    error_message = "At least one security group ID is required."
  }
}

check "password_source_exclusive" {
  assert {
    condition = (
      (var.password == null ? 0 : 1) +
      (var.manage_master_user_password ? 1 : 0) +
      (var.generate_password == null ? 0 : 1)
    ) == 1
    error_message = "Use exactly one of password, manage_master_user_password, or generate_password."
  }
}

check "password_source_required" {
  assert {
    condition     = var.manage_master_user_password || var.password != null || var.generate_password != null
    error_message = "Provide password, manage_master_user_password, or generate_password."
  }
}

check "parameter_group_family_required" {
  assert {
    condition     = !var.create_parameter_group || try(var.parameter_group_family, null) != null
    error_message = "parameter_group_family is required when create_parameter_group is true."
  }
}

check "parameter_group_source_exclusive" {
  assert {
    condition     = !(var.create_parameter_group && try(var.parameter_group_name, null) != null)
    error_message = "Use either create_parameter_group or parameter_group_name, not both."
  }
}

check "final_snapshot_required" {
  assert {
    condition = var.skip_final_snapshot || local.final_snapshot_identifier != ""
    error_message = "final_snapshot_identifier is required when skip_final_snapshot is false."
  }
}

check "monitoring_role_required" {
  assert {
    condition     = var.monitoring_interval == 0 || try(var.monitoring_role_arn, null) != null
    error_message = "monitoring_role_arn is required when monitoring_interval is greater than 0."
  }
}

check "performance_insights_kms" {
  assert {
    condition     = !var.performance_insights_enabled || var.storage_encrypted
    error_message = "storage_encrypted must be true when performance_insights_enabled is true."
  }
}

check "cloudwatch_logs_engine" {
  assert {
    condition = alltrue([
      for log_type in var.enabled_cloudwatch_logs_exports :
      contains(local.allowed_cloudwatch_logs, log_type)
    ])
    error_message = "Each enabled_cloudwatch_logs_exports value must be supported by the selected engine."
  }
}

resource "aws_db_subnet_group" "this" {
  count = var.create_db_subnet_group ? 1 : 0

  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

resource "aws_db_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name   = "${var.identifier}-params"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(var.tags, {
    Name = "${var.identifier}-params"
  })
}

resource "aws_db_instance" "instance" {
  identifier = var.identifier

  engine         = var.engine
  engine_version = local.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_throughput    = var.storage_throughput

  db_name  = var.db_name
  username = var.username
  password = local.master_password
  port     = var.port

  manage_master_user_password = var.manage_master_user_password

  db_subnet_group_name   = local.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  parameter_group_name   = local.parameter_group_name

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshot_identifier

  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period

  copy_tags_to_snapshot               = var.copy_tags_to_snapshot
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  ca_cert_identifier                  = var.ca_cert_identifier

  tags = merge(var.tags, {
    Name = var.identifier
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      password,
    ]
  }

  depends_on = [aws_db_subnet_group.this]
}
