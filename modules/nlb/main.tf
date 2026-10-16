locals {
  target_attachments = {
    for item in flatten([
      for tg_key, tg in var.target_groups : [
        for idx, target in try(tg.targets, []) : {
          key    = "${tg_key}-${idx}"
          tg_key = tg_key
          target = target
        }
      ]
    ]) : item.key => item
  }

  use_subnet_mappings = length(var.subnet_mappings) > 0
}

check "subnet_count" {
  assert {
    condition = (
      local.use_subnet_mappings && length(var.subnet_mappings) >= 2
      ) || (
      !local.use_subnet_mappings && length(var.subnet_ids) >= 2
    )
    error_message = "NLB requires at least two subnet_ids or two subnet_mappings across availability zones."
  }
}

check "target_groups_required" {
  assert {
    condition     = length(var.target_groups) > 0
    error_message = "At least one target group is required."
  }
}

check "listeners_required" {
  assert {
    condition     = length(var.listeners) > 0
    error_message = "At least one listener is required."
  }
}

check "tls_certificate_required" {
  assert {
    condition = alltrue([
      for listener in var.listeners :
      listener.protocol != "TLS" || try(listener.certificate_arn, null) != null
    ])
    error_message = "certificate_arn is required for TLS listeners."
  }
}

check "listener_target_groups" {
  assert {
    condition = alltrue([
      for listener in var.listeners :
      contains(keys(var.target_groups), listener.target_group_key)
    ])
    error_message = "Each listener must reference a valid target_group_key."
  }
}

check "target_group_protocols" {
  assert {
    condition = alltrue([
      for tg in var.target_groups :
      contains(["TCP", "UDP", "TLS", "TCP_UDP"], tg.protocol)
    ])
    error_message = "Target group protocol must be TCP, UDP, TLS, or TCP_UDP."
  }
}

check "listener_protocols" {
  assert {
    condition = alltrue([
      for listener in var.listeners :
      contains(["TCP", "UDP", "TLS"], listener.protocol)
    ])
    error_message = "Listener protocol must be TCP, UDP, or TLS."
  }
}

check "target_group_name_length" {
  assert {
    condition = alltrue([
      for key in keys(var.target_groups) :
      length("${var.name}-${key}") <= 32
    ])
    error_message = "Combined NLB name and target group key must be 32 characters or fewer for the target group name."
  }
}

check "listener_ports_unique" {
  assert {
    condition = length(distinct([
      for listener in var.listeners : "${listener.port}/${listener.protocol}"
    ])) == length(var.listeners)
    error_message = "Each listener must use a unique port and protocol combination."
  }
}

check "target_group_ports" {
  assert {
    condition = alltrue([
      for tg in var.target_groups :
      tg.port >= 1 && tg.port <= 65535
    ])
    error_message = "Target group port must be between 1 and 65535."
  }
}

check "listener_ports" {
  assert {
    condition = alltrue([
      for listener in var.listeners :
      listener.port >= 1 && listener.port <= 65535
    ])
    error_message = "Listener port must be between 1 and 65535."
  }
}

check "target_types" {
  assert {
    condition = alltrue([
      for tg in var.target_groups :
      contains(["instance", "ip", "alb"], tg.target_type)
    ])
    error_message = "Target group target_type must be instance, ip, or alb."
  }
}

check "health_check_protocols" {
  assert {
    condition = alltrue([
      for tg in var.target_groups :
      contains(["TCP", "HTTP", "HTTPS"], tg.health_check_protocol)
    ])
    error_message = "NLB health_check_protocol must be TCP, HTTP, or HTTPS."
  }
}

check "health_check_path_required" {
  assert {
    condition = alltrue([
      for tg in var.target_groups :
      !tg.health_check_enabled ||
      !contains(["HTTP", "HTTPS"], tg.health_check_protocol) ||
      try(tg.health_check_path, null) != null
    ])
    error_message = "health_check_path is required when health_check_protocol is HTTP or HTTPS."
  }
}

check "stickiness_types" {
  assert {
    condition = alltrue([
      for tg in var.target_groups :
      !tg.stickiness_enabled || contains(["source_ip", "source_ip_port"], tg.stickiness_type)
    ])
    error_message = "NLB stickiness_type must be source_ip or source_ip_port."
  }
}

check "instance_target_az" {
  assert {
    condition = alltrue(flatten([
      for tg_key, tg in var.target_groups : [
        for target in try(tg.targets, []) :
        tg.target_type != "instance" || try(target.availability_zone, null) != null
      ]
    ]))
    error_message = "instance targets require availability_zone on each target attachment."
  }
}

resource "aws_lb" "load_balancer" {
  name                             = var.name
  load_balancer_type               = "network"
  internal                         = var.internal
  ip_address_type                  = var.ip_address_type
  security_groups                  = length(var.security_group_ids) > 0 ? var.security_group_ids : null
  subnets                          = local.use_subnet_mappings ? null : var.subnet_ids
  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  dynamic "subnet_mapping" {
    for_each = var.subnet_mappings

    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = try(subnet_mapping.value.allocation_id, null)
      private_ipv4_address = try(subnet_mapping.value.private_ipv4_address, null)
      ipv6_address         = try(subnet_mapping.value.ipv6_address, null)
    }
  }

  dynamic "access_logs" {
    for_each = var.access_logs != null ? [var.access_logs] : []

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_lb_target_group" "target_group" {
  for_each = var.target_groups

  name        = substr("${var.name}-${each.key}", 0, 32)
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = coalesce(try(each.value.vpc_id, null), var.vpc_id)

  deregistration_delay   = each.value.deregistration_delay
  preserve_client_ip            = try(each.value.preserve_client_ip, null)
  connection_termination        = try(each.value.connection_termination, null)
  proxy_protocol_v2             = each.value.proxy_protocol_v2

  dynamic "stickiness" {
    for_each = each.value.stickiness_enabled ? [each.value] : []

    content {
      type    = stickiness.value.stickiness_type
      enabled = true
    }
  }

  health_check {
    enabled             = each.value.health_check_enabled
    interval            = each.value.health_check_interval
    port                = each.value.health_check_port
    protocol            = each.value.health_check_protocol
    path                = try(each.value.health_check_path, null)
    timeout             = each.value.health_check_timeout
    healthy_threshold   = each.value.health_check_healthy_threshold
    unhealthy_threshold = each.value.health_check_unhealthy_threshold
    matcher             = try(each.value.health_check_matcher, null)
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "attachment" {
  for_each = local.target_attachments

  target_group_arn  = aws_lb_target_group.target_group[each.value.tg_key].arn
  target_id         = each.value.target.id
  port              = try(each.value.target.port, null)
  availability_zone = try(each.value.target.availability_zone, null)
}

resource "aws_lb_listener" "listener" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.load_balancer.arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = each.value.protocol == "TLS" ? each.value.certificate_arn : null
  ssl_policy        = each.value.protocol == "TLS" ? each.value.ssl_policy : null
  alpn_policy       = try(each.value.alpn_policy, null)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.value.target_group_key].arn
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}
