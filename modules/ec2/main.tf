data "aws_ami" "selected" {
  count = var.ami == null ? 1 : 0

  most_recent = var.ami_lookup.most_recent
  owners      = var.ami_lookup.owners

  dynamic "filter" {
    for_each = var.ami_lookup.filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

locals {
  ami_id = coalesce(var.ami, try(data.aws_ami.selected[0].id, null))

  metadata_options = coalesce(var.metadata_options, {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  })

  root_block_device_defaults = {
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  resolved_root_block_device = merge(
    local.root_block_device_defaults,
    coalesce(var.root_block_device, {})
  )

  volume_tags = merge(var.tags, var.volume_tags, {
    Name = var.name
  })
}

check "ami_source_required" {
  assert {
    condition     = var.ami != null || var.ami_lookup != null
    error_message = "Provide ami or ami_lookup."
  }
}

check "ami_source_exclusive" {
  assert {
    condition     = var.ami == null || var.ami_lookup == null
    error_message = "Use either ami or ami_lookup, not both."
  }
}

check "ami_lookup_filters_required" {
  assert {
    condition     = var.ami_lookup == null || length(var.ami_lookup.filters) > 0
    error_message = "ami_lookup.filters must contain at least one filter."
  }
}

check "security_groups_required" {
  assert {
    condition     = length(var.vpc_security_group_ids) > 0
    error_message = "At least one security group ID is required."
  }
}

check "user_data_exclusive" {
  assert {
    condition     = var.user_data == null || var.user_data_base64 == null
    error_message = "Use either user_data or user_data_base64, not both."
  }
}

check "eip_public_ip_exclusive" {
  assert {
    condition     = !var.create_eip || var.associate_public_ip_address != true
    error_message = "Do not set associate_public_ip_address = true when create_eip is true."
  }
}

check "metadata_http_tokens" {
  assert {
    condition     = contains(["optional", "required"], local.metadata_options.http_tokens)
    error_message = "metadata_options.http_tokens must be optional or required."
  }
}

check "metadata_http_endpoint" {
  assert {
    condition     = contains(["enabled", "disabled"], local.metadata_options.http_endpoint)
    error_message = "metadata_options.http_endpoint must be enabled or disabled."
  }
}

check "metadata_instance_metadata_tags" {
  assert {
    condition     = contains(["enabled", "disabled"], local.metadata_options.instance_metadata_tags)
    error_message = "metadata_options.instance_metadata_tags must be enabled or disabled."
  }
}

check "ebs_block_device_names_unique" {
  assert {
    condition = length(distinct([
      for device in var.ebs_block_devices : device.device_name
    ])) == length(var.ebs_block_devices)
    error_message = "Each ebs_block_devices entry must use a unique device_name."
  }
}

check "ebs_block_device_source" {
  assert {
    condition = alltrue([
      for device in var.ebs_block_devices :
      try(device.snapshot_id, null) != null || try(device.volume_size, null) != null
    ])
    error_message = "Each ebs_block_devices entry must define volume_size or snapshot_id."
  }
}

check "root_volume_size" {
  assert {
    condition = (
      try(local.resolved_root_block_device.volume_size, null) == null ||
      local.resolved_root_block_device.volume_size >= 1
    )
    error_message = "root_block_device.volume_size must be at least 1 GiB when set."
  }
}

check "root_volume_type" {
  assert {
    condition = contains(
      ["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"],
      local.resolved_root_block_device.volume_type
    )
    error_message = "root_block_device.volume_type must be gp2, gp3, io1, io2, st1, sc1, or standard."
  }
}

check "ebs_volume_types" {
  assert {
    condition = alltrue([
      for device in var.ebs_block_devices :
      contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], device.volume_type)
    ])
    error_message = "Each ebs_block_devices volume_type must be gp2, gp3, io1, io2, st1, sc1, or standard."
  }
}

check "credit_specification_values" {
  assert {
    condition = (
      var.credit_specification == null ||
      contains(["standard", "unlimited"], var.credit_specification.cpu_credits)
    )
    error_message = "credit_specification.cpu_credits must be standard or unlimited."
  }
}

resource "aws_instance" "managed" {
  count = var.ignore_ami_changes ? 0 : 1

  ami                                  = local.ami_id
  instance_type                        = var.instance_type
  subnet_id                            = var.subnet_id
  vpc_security_group_ids               = var.vpc_security_group_ids
  key_name                             = var.key_name
  iam_instance_profile                 = var.iam_instance_profile
  availability_zone                    = var.availability_zone
  associate_public_ip_address          = var.associate_public_ip_address
  private_ip                           = var.private_ip
  secondary_private_ips                = length(var.secondary_private_ips) > 0 ? var.secondary_private_ips : null
  source_dest_check                    = var.source_dest_check
  user_data                            = var.user_data
  user_data_base64                     = var.user_data_base64
  user_data_replace_on_change          = var.user_data_replace_on_change
  monitoring                           = var.monitoring
  ebs_optimized                        = var.ebs_optimized
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  tenancy                              = var.tenancy
  placement_group                      = var.placement_group
  hibernation                          = var.hibernation
  volume_tags                          = local.volume_tags

  root_block_device {
    volume_size           = try(local.resolved_root_block_device.volume_size, null)
    volume_type           = local.resolved_root_block_device.volume_type
    iops                  = try(local.resolved_root_block_device.iops, null)
    throughput            = try(local.resolved_root_block_device.throughput, null)
    encrypted             = local.resolved_root_block_device.encrypted
    kms_key_id            = try(local.resolved_root_block_device.kms_key_id, null)
    delete_on_termination = local.resolved_root_block_device.delete_on_termination
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices

    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = try(ebs_block_device.value.volume_size, null)
      volume_type           = ebs_block_device.value.volume_type
      iops                  = try(ebs_block_device.value.iops, null)
      throughput            = try(ebs_block_device.value.throughput, null)
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = try(ebs_block_device.value.kms_key_id, null)
      delete_on_termination = ebs_block_device.value.delete_on_termination
      snapshot_id           = try(ebs_block_device.value.snapshot_id, null)
    }
  }

  metadata_options {
    http_endpoint               = local.metadata_options.http_endpoint
    http_tokens                 = local.metadata_options.http_tokens
    http_put_response_hop_limit = local.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = local.metadata_options.instance_metadata_tags
  }

  dynamic "cpu_options" {
    for_each = var.cpu_options != null ? [var.cpu_options] : []

    content {
      core_count       = cpu_options.value.core_count
      threads_per_core = cpu_options.value.threads_per_core
    }
  }

  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []

    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "pinned" {
  count = var.ignore_ami_changes ? 1 : 0

  ami                                  = local.ami_id
  instance_type                        = var.instance_type
  subnet_id                            = var.subnet_id
  vpc_security_group_ids               = var.vpc_security_group_ids
  key_name                             = var.key_name
  iam_instance_profile                 = var.iam_instance_profile
  availability_zone                    = var.availability_zone
  associate_public_ip_address          = var.associate_public_ip_address
  private_ip                           = var.private_ip
  secondary_private_ips                = length(var.secondary_private_ips) > 0 ? var.secondary_private_ips : null
  source_dest_check                    = var.source_dest_check
  user_data                            = var.user_data
  user_data_base64                     = var.user_data_base64
  user_data_replace_on_change          = var.user_data_replace_on_change
  monitoring                           = var.monitoring
  ebs_optimized                        = var.ebs_optimized
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  tenancy                              = var.tenancy
  placement_group                      = var.placement_group
  hibernation                          = var.hibernation
  volume_tags                          = local.volume_tags

  root_block_device {
    volume_size           = try(local.resolved_root_block_device.volume_size, null)
    volume_type           = local.resolved_root_block_device.volume_type
    iops                  = try(local.resolved_root_block_device.iops, null)
    throughput            = try(local.resolved_root_block_device.throughput, null)
    encrypted             = local.resolved_root_block_device.encrypted
    kms_key_id            = try(local.resolved_root_block_device.kms_key_id, null)
    delete_on_termination = local.resolved_root_block_device.delete_on_termination
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices

    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = try(ebs_block_device.value.volume_size, null)
      volume_type           = ebs_block_device.value.volume_type
      iops                  = try(ebs_block_device.value.iops, null)
      throughput            = try(ebs_block_device.value.throughput, null)
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = try(ebs_block_device.value.kms_key_id, null)
      delete_on_termination = ebs_block_device.value.delete_on_termination
      snapshot_id           = try(ebs_block_device.value.snapshot_id, null)
    }
  }

  metadata_options {
    http_endpoint               = local.metadata_options.http_endpoint
    http_tokens                 = local.metadata_options.http_tokens
    http_put_response_hop_limit = local.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = local.metadata_options.instance_metadata_tags
  }

  dynamic "cpu_options" {
    for_each = var.cpu_options != null ? [var.cpu_options] : []

    content {
      core_count       = cpu_options.value.core_count
      threads_per_core = cpu_options.value.threads_per_core
    }
  }

  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []

    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami]
  }
}

locals {
  instance = var.ignore_ami_changes ? aws_instance.pinned[0] : aws_instance.managed[0]
}

resource "aws_eip" "this" {
  count  = var.create_eip ? 1 : 0
  domain = var.eip_domain

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_eip_association" "this" {
  count = var.create_eip ? 1 : 0

  instance_id   = local.instance.id
  allocation_id = aws_eip.this[0].id
}
