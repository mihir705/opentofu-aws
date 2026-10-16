locals {
  description = coalesce(var.description, "Security group ${var.name}")

  default_egress_rule = {
    description                  = "All outbound IPv4"
    protocol                     = "-1"
    from_port                    = null
    to_port                      = null
    cidr_blocks                  = ["0.0.0.0/0"]
    ipv6_cidr_blocks             = []
    prefix_list_ids              = []
    referenced_security_group_id = null
    self_reference               = false
  }

  egress_rules = var.egress_rules != null ? var.egress_rules : concat([], [local.default_egress_rule])

  ingress_rule_expansions = flatten([
    for rule_idx, rule in var.ingress_rules : concat(
      [
        for cidr_idx, cidr in rule.cidr_blocks : {
          key          = "ingress-${rule_idx}-cidr-${cidr_idx}"
          rule         = rule
          cidr_ipv4    = cidr
          cidr_ipv6    = null
          prefix_list  = null
          ref_sg_id    = null
          self_ref     = false
        }
      ],
      [
        for cidr_idx, cidr in rule.ipv6_cidr_blocks : {
          key          = "ingress-${rule_idx}-cidr6-${cidr_idx}"
          rule         = rule
          cidr_ipv4    = null
          cidr_ipv6    = cidr
          prefix_list  = null
          ref_sg_id    = null
          self_ref     = false
        }
      ],
      [
        for pl_idx, prefix_list in rule.prefix_list_ids : {
          key          = "ingress-${rule_idx}-pl-${pl_idx}"
          rule         = rule
          cidr_ipv4    = null
          cidr_ipv6    = null
          prefix_list  = prefix_list
          ref_sg_id    = null
          self_ref     = false
        }
      ],
      try(rule.referenced_security_group_id, null) != null ? [{
        key       = "ingress-${rule_idx}-sg"
        rule      = rule
        cidr_ipv4 = null
        cidr_ipv6 = null
        prefix_list = null
        ref_sg_id = rule.referenced_security_group_id
        self_ref  = false
      }] : [],
      rule.self_reference ? [{
        key       = "ingress-${rule_idx}-self"
        rule      = rule
        cidr_ipv4 = null
        cidr_ipv6 = null
        prefix_list = null
        ref_sg_id = null
        self_ref  = true
      }] : []
    )
  ])

  egress_rule_expansions = flatten([
    for rule_idx, rule in local.egress_rules : concat(
      [
        for cidr_idx, cidr in rule.cidr_blocks : {
          key          = "egress-${rule_idx}-cidr-${cidr_idx}"
          rule         = rule
          cidr_ipv4    = cidr
          cidr_ipv6    = null
          prefix_list  = null
          ref_sg_id    = null
          self_ref     = false
        }
      ],
      [
        for cidr_idx, cidr in rule.ipv6_cidr_blocks : {
          key          = "egress-${rule_idx}-cidr6-${cidr_idx}"
          rule         = rule
          cidr_ipv4    = null
          cidr_ipv6    = cidr
          prefix_list  = null
          ref_sg_id    = null
          self_ref     = false
        }
      ],
      [
        for pl_idx, prefix_list in rule.prefix_list_ids : {
          key          = "egress-${rule_idx}-pl-${pl_idx}"
          rule         = rule
          cidr_ipv4    = null
          cidr_ipv6    = null
          prefix_list  = prefix_list
          ref_sg_id    = null
          self_ref     = false
        }
      ],
      try(rule.referenced_security_group_id, null) != null ? [{
        key       = "egress-${rule_idx}-sg"
        rule      = rule
        cidr_ipv4 = null
        cidr_ipv6 = null
        prefix_list = null
        ref_sg_id = rule.referenced_security_group_id
        self_ref  = false
      }] : [],
      rule.self_reference ? [{
        key       = "egress-${rule_idx}-self"
        rule      = rule
        cidr_ipv4 = null
        cidr_ipv6 = null
        prefix_list = null
        ref_sg_id = null
        self_ref  = true
      }] : []
    )
  ])
}

check "ingress_rule_has_target" {
  assert {
    condition = alltrue([
      for rule in var.ingress_rules :
      length(rule.cidr_blocks) > 0 ||
      length(rule.ipv6_cidr_blocks) > 0 ||
      length(rule.prefix_list_ids) > 0 ||
      try(rule.referenced_security_group_id, null) != null ||
      rule.self_reference
    ])
    error_message = "Each ingress rule must define at least one target: cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, referenced_security_group_id, or self_reference."
  }
}

check "egress_rule_has_target" {
  assert {
    condition = alltrue([
      for rule in local.egress_rules :
      length(rule.cidr_blocks) > 0 ||
      length(rule.ipv6_cidr_blocks) > 0 ||
      length(rule.prefix_list_ids) > 0 ||
      try(rule.referenced_security_group_id, null) != null ||
      rule.self_reference
    ])
    error_message = "Each egress rule must define at least one target: cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, referenced_security_group_id, or self_reference."
  }
}

check "tcp_udp_ports_required" {
  assert {
    condition = alltrue(concat(
      [
        for rule in var.ingress_rules :
        contains(["tcp", "udp"], rule.protocol) == false || (
          try(rule.from_port, null) != null && try(rule.to_port, null) != null
        )
      ],
      [
        for rule in local.egress_rules :
        contains(["tcp", "udp"], rule.protocol) == false || (
          try(rule.from_port, null) != null && try(rule.to_port, null) != null
        )
      ]
    ))
    error_message = "from_port and to_port are required when protocol is tcp or udp."
  }
}

check "valid_protocols" {
  assert {
    condition = alltrue(concat(
      [
        for rule in var.ingress_rules :
        contains(["tcp", "udp", "icmp", "icmpv6", "-1"], rule.protocol)
      ],
      [
        for rule in local.egress_rules :
        contains(["tcp", "udp", "icmp", "icmpv6", "-1"], rule.protocol)
      ]
    ))
    error_message = "protocol must be tcp, udp, icmp, icmpv6, or -1."
  }
}

check "tcp_udp_port_range" {
  assert {
    condition = alltrue(concat(
      [
        for rule in var.ingress_rules :
        contains(["tcp", "udp"], rule.protocol) == false || rule.from_port <= rule.to_port
      ],
      [
        for rule in local.egress_rules :
        contains(["tcp", "udp"], rule.protocol) == false || rule.from_port <= rule.to_port
      ]
    ))
    error_message = "from_port must be less than or equal to to_port for tcp and udp rules."
  }
}

resource "aws_security_group" "security_group" {
  name_prefix            = "${var.name}-"
  description            = local.description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each = {
    for item in local.ingress_rule_expansions : item.key => item
  }

  security_group_id = aws_security_group.security_group.id
  description       = try(each.value.rule.description, null)
  ip_protocol       = each.value.rule.protocol
  from_port         = each.value.rule.protocol == "-1" ? null : each.value.rule.from_port
  to_port           = each.value.rule.protocol == "-1" ? null : each.value.rule.to_port

  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list
  referenced_security_group_id = each.value.self_ref ? aws_security_group.security_group.id : each.value.ref_sg_id
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  for_each = {
    for item in local.egress_rule_expansions : item.key => item
  }

  security_group_id = aws_security_group.security_group.id
  description       = try(each.value.rule.description, null)
  ip_protocol       = each.value.rule.protocol
  from_port         = each.value.rule.protocol == "-1" ? null : each.value.rule.from_port
  to_port           = each.value.rule.protocol == "-1" ? null : each.value.rule.to_port

  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list
  referenced_security_group_id = each.value.self_ref ? aws_security_group.security_group.id : each.value.ref_sg_id
}
