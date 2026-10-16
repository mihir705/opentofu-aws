locals {
  lifecycle_transition_values = [
    "AFTER_7_DAYS",
    "AFTER_14_DAYS",
    "AFTER_30_DAYS",
    "AFTER_60_DAYS",
    "AFTER_90_DAYS",
    "AFTER_180_DAYS",
    "AFTER_270_DAYS",
    "AFTER_365_DAYS",
  ]
}

check "subnet_ids_required" {
  assert {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet_id is required for mount targets."
  }
}

check "security_group_ids_required" {
  assert {
    condition     = length(var.security_group_ids) > 0
    error_message = "At least one security_group_id is required for mount targets."
  }
}

check "kms_key_exclusive" {
  assert {
    condition     = var.encrypted || var.kms_key_id == null
    error_message = "kms_key_id is only supported when encrypted is true."
  }
}

check "provisioned_throughput_required" {
  assert {
    condition     = var.throughput_mode != "provisioned" || var.provisioned_throughput_in_mibps != null
    error_message = "provisioned_throughput_in_mibps is required when throughput_mode is provisioned."
  }
}

check "provisioned_throughput_exclusive" {
  assert {
    condition     = var.throughput_mode == "provisioned" || var.provisioned_throughput_in_mibps == null
    error_message = "provisioned_throughput_in_mibps is only supported when throughput_mode is provisioned."
  }
}

check "access_point_paths" {
  assert {
    condition = alltrue([
      for name, ap in var.access_points :
      startswith(ap.path, "/")
    ])
    error_message = "Each access point path must start with '/'."
  }
}

check "lifecycle_transition_values" {
  assert {
    condition = var.lifecycle_policy == null || alltrue(compact([
      var.lifecycle_policy.transition_to_ia == null ? true : contains(local.lifecycle_transition_values, var.lifecycle_policy.transition_to_ia),
      var.lifecycle_policy.transition_to_archive == null ? true : contains(local.lifecycle_transition_values, var.lifecycle_policy.transition_to_archive),
      var.lifecycle_policy.transition_to_primary_storage_class == null ? true : contains(local.lifecycle_transition_values, var.lifecycle_policy.transition_to_primary_storage_class),
    ]))
    error_message = "Lifecycle transition values must use AFTER_<N>_DAYS format."
  }
}

resource "aws_efs_file_system" "file_system" {
  creation_token = var.name
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = var.encrypted
  kms_key_id       = var.encrypted ? var.kms_key_id : null

  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy != null ? [var.lifecycle_policy] : []

    content {
      transition_to_ia                    = try(lifecycle_policy.value.transition_to_ia, null)
      transition_to_archive               = try(lifecycle_policy.value.transition_to_archive, null)
      transition_to_primary_storage_class = try(lifecycle_policy.value.transition_to_primary_storage_class, null)
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_efs_mount_target" "mount_target" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.file_system.id
  subnet_id       = each.value
  security_groups = var.security_group_ids
}

resource "aws_efs_access_point" "access_point" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.file_system.id

  dynamic "posix_user" {
    for_each = try(each.value.posix_user, null) != null ? [each.value.posix_user] : []

    content {
      uid = posix_user.value.uid
      gid = posix_user.value.gid
    }
  }

  root_directory {
    path = each.value.path

    dynamic "creation_info" {
      for_each = try(each.value.creation_info, null) != null ? [each.value.creation_info] : []

      content {
        owner_uid   = creation_info.value.owner_uid
        owner_gid   = creation_info.value.owner_gid
        permissions = creation_info.value.permissions
      }
    }
  }

  tags = merge(var.tags, try(each.value.tags, {}), {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_efs_backup_policy" "backup" {
  count = var.enable_backup_policy ? 1 : 0

  file_system_id = aws_efs_file_system.file_system.id

  backup_policy {
    status = var.backup_policy_status
  }
}
