locals {
  security_group_ids = var.create_security_group ? [aws_security_group.alb[0].id] : var.security_group_ids

  listener_rules = {
    for item in flatten([
      for listener_key, listener in var.listeners : [
        for rule in try(listener.rules, []) : {
          key          = "${listener_key}-${rule.name}"
          listener_key = listener_key
          rule         = rule
        }
      ]
    ]) : item.key => item
  }

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
}

check "subnet_count" {
  assert {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALB requires at least two subnets in different availability zones."
  }
}

check "security_group_source" {
  assert {
    condition     = var.create_security_group || length(var.security_group_ids) > 0
    error_message = "Provide security_group_ids when create_security_group is false."
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

check "https_certificate_required" {
  assert {
    condition = alltrue([
      for listener in var.listeners :
      listener.protocol != "HTTPS" || try(listener.certificate_arn, null) != null
    ])
    error_message = "certificate_arn is required for HTTPS listeners."
  }
}

check "listener_forward_target_groups" {
  assert {
    condition = alltrue(flatten([
      for listener in var.listeners : concat(
        listener.default_action.type == "forward" ? [
          contains(keys(var.target_groups), try(listener.default_action.target_group_key, ""))
        ] : [true],
        [
          for rule in try(listener.rules, []) :
          rule.action.type != "forward" || contains(keys(var.target_groups), try(rule.action.target_group_key, ""))
        ]
      )
    ]))
    error_message = "Forward actions must reference a valid target_group_key."
  }
}

check "listener_rule_priorities_unique" {
  assert {
    condition = alltrue([
      for listener_key, listener in var.listeners :
      length(distinct([for rule in try(listener.rules, []) : rule.priority])) == length(try(listener.rules, []))
    ])
    error_message = "Listener rule priorities must be unique within each listener."
  }
}

check "listener_rule_requires_condition" {
  assert {
    condition = alltrue(flatten([
      for listener in var.listeners : [
        for rule in try(listener.rules, []) :
        try(rule.host_header, null) != null ||
        try(rule.path_pattern, null) != null ||
        try(rule.http_header, null) != null
      ]
    ]))
    error_message = "Each listener rule requires at least one condition: host_header, path_pattern, or http_header."
  }
}

check "listener_default_action_payload" {
  assert {
    condition = alltrue([
      for listener in var.listeners :
      (listener.default_action.type == "forward" && try(listener.default_action.target_group_key, null) != null) ||
      (listener.default_action.type == "redirect" && try(listener.default_action.redirect, null) != null) ||
      (listener.default_action.type == "fixed-response" && try(listener.default_action.fixed_response, null) != null)
    ])
    error_message = "Listener default_action must include the payload matching its type."
  }
}

check "target_group_name_length" {
  assert {
    condition = alltrue([
      for key in keys(var.target_groups) :
      length("${var.name}-${key}") <= 32
    ])
    error_message = "Combined ALB name and target group key must be 32 characters or fewer for the target group name."
  }
}

resource "aws_security_group" "alb" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${var.name}-sg-"
  description = "Security group for ${var.name} Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "load_balancer" {
  name               = var.name
  load_balancer_type = "application"
  internal           = var.internal
  ip_address_type    = var.ip_address_type
  security_groups    = local.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_http2               = var.enable_http2

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
  vpc_id      = each.value.target_type == "lambda" ? null : coalesce(try(each.value.vpc_id, null), var.vpc_id)

  load_balancing_algorithm_type = each.value.load_balancing_algorithm_type
  deregistration_delay          = each.value.deregistration_delay
  slow_start                    = each.value.slow_start

  dynamic "stickiness" {
    for_each = each.value.stickiness_enabled ? [each.value] : []

    content {
      type            = stickiness.value.stickiness_type
      enabled         = true
      cookie_duration = stickiness.value.stickiness_cookie_duration
    }
  }

  health_check {
    enabled             = each.value.health_check_enabled
    interval            = each.value.health_check_interval
    path                = each.value.health_check_path
    port                = each.value.health_check_port
    protocol            = each.value.health_check_protocol
    timeout             = each.value.health_check_timeout
    healthy_threshold   = each.value.health_check_healthy_threshold
    unhealthy_threshold = each.value.health_check_unhealthy_threshold
    matcher             = each.value.health_check_matcher
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

  target_group_arn = aws_lb_target_group.target_group[each.value.tg_key].arn
  target_id        = each.value.target.id
  port             = try(each.value.target.port, null)
  availability_zone = try(each.value.target.availability_zone, null)
}

resource "aws_lb_listener" "listener" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.load_balancer.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.protocol == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn   = each.value.protocol == "HTTPS" ? each.value.certificate_arn : null

  default_action {
    type = each.value.default_action.type

    target_group_arn = each.value.default_action.type == "forward" ? aws_lb_target_group.target_group[each.value.default_action.target_group_key].arn : null

    dynamic "fixed_response" {
      for_each = each.value.default_action.type == "fixed-response" && each.value.default_action.fixed_response != null ? [each.value.default_action.fixed_response] : []

      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }

    dynamic "redirect" {
      for_each = each.value.default_action.type == "redirect" && each.value.default_action.redirect != null ? [each.value.default_action.redirect] : []

      content {
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        status_code = redirect.value.status_code
        host        = try(redirect.value.host, null)
        path        = try(redirect.value.path, null)
        query       = try(redirect.value.query, null)
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_lb_listener_rule" "rule" {
  for_each = local.listener_rules

  listener_arn = aws_lb_listener.listener[each.value.listener_key].arn
  priority     = each.value.rule.priority

  dynamic "condition" {
    for_each = try(each.value.rule.host_header, null) != null ? [each.value.rule.host_header] : []

    content {
      host_header {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = try(each.value.rule.path_pattern, null) != null ? [each.value.rule.path_pattern] : []

    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = try(each.value.rule.http_header, null) != null ? [each.value.rule.http_header] : []

    content {
      http_header {
        http_header_name = condition.value.name
        values           = condition.value.values
      }
    }
  }

  action {
    type = each.value.rule.action.type

    target_group_arn = each.value.rule.action.type == "forward" ? aws_lb_target_group.target_group[each.value.rule.action.target_group_key].arn : null

    dynamic "fixed_response" {
      for_each = each.value.rule.action.type == "fixed-response" && each.value.rule.action.fixed_response != null ? [each.value.rule.action.fixed_response] : []

      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }

    dynamic "redirect" {
      for_each = each.value.rule.action.type == "redirect" && each.value.rule.action.redirect != null ? [each.value.rule.action.redirect] : []

      content {
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        status_code = redirect.value.status_code
        host        = try(redirect.value.host, null)
        path        = try(redirect.value.path, null)
        query       = try(redirect.value.query, null)
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${each.value.rule.name}"
  })
}
