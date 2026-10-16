locals {
  name_prefix = var.name

  public_subnet_keys  = sort(keys(var.public_subnets))
  private_subnet_keys = sort(keys(var.private_subnets))

  first_public_subnet_key = length(local.public_subnet_keys) > 0 ? local.public_subnet_keys[0] : null

  nat_gateways = var.enable_nat_gateway ? (
    var.one_nat_gateway_per_az ? merge([
      for az in distinct([for subnet in var.public_subnets : subnet.availability_zone]) : {
        (az) = [
          for key in local.public_subnet_keys : key
          if var.public_subnets[key].availability_zone == az
        ][0]
      }
    ]...) : local.first_public_subnet_key != null ? {
      (var.public_subnets[local.first_public_subnet_key].availability_zone) = local.first_public_subnet_key
    } : {}
  ) : {}

  private_route_table_keys = var.enable_nat_gateway && var.one_nat_gateway_per_az ? local.private_subnet_keys : (
    length(local.private_subnet_keys) > 0 ? ["default"] : []
  )

  private_route_table_nat_az = var.enable_nat_gateway && !var.one_nat_gateway_per_az && local.first_public_subnet_key != null ? (
    var.public_subnets[local.first_public_subnet_key].availability_zone
  ) : null

  private_nacl_ingress_rules = coalesce(var.private_nacl_ingress_rules, [
    {
      rule_number = 100
      protocol    = "-1"
      action      = "allow"
      cidr_block  = var.cidr_block
      from_port   = 0
      to_port     = 0
    },
    {
      rule_number = 110
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 1024
      to_port     = 65535
    },
    {
      rule_number = 120
      protocol    = "udp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 1024
      to_port     = 65535
    },
  ])

  public_nacl_ingress_rules_normalized = [
    for rule in var.public_nacl_ingress_rules : {
      rule_number = rule.rule_number
      protocol    = rule.protocol
      action      = rule.action
      cidr_block  = rule.cidr_block
      from_port   = coalesce(try(rule.from_port, null), rule.protocol == "-1" ? 0 : null)
      to_port     = coalesce(try(rule.to_port, null), rule.protocol == "-1" ? 0 : null)
      icmp_type   = try(rule.icmp_type, null)
      icmp_code   = try(rule.icmp_code, null)
    }
  ]

  public_nacl_egress_rules_normalized = [
    for rule in var.public_nacl_egress_rules : {
      rule_number = rule.rule_number
      protocol    = rule.protocol
      action      = rule.action
      cidr_block  = rule.cidr_block
      from_port   = coalesce(try(rule.from_port, null), rule.protocol == "-1" ? 0 : null)
      to_port     = coalesce(try(rule.to_port, null), rule.protocol == "-1" ? 0 : null)
      icmp_type   = try(rule.icmp_type, null)
      icmp_code   = try(rule.icmp_code, null)
    }
  ]

  private_nacl_ingress_rules_normalized = [
    for rule in local.private_nacl_ingress_rules : {
      rule_number = rule.rule_number
      protocol    = rule.protocol
      action      = rule.action
      cidr_block  = rule.cidr_block
      from_port   = coalesce(try(rule.from_port, null), rule.protocol == "-1" ? 0 : null)
      to_port     = coalesce(try(rule.to_port, null), rule.protocol == "-1" ? 0 : null)
      icmp_type   = try(rule.icmp_type, null)
      icmp_code   = try(rule.icmp_code, null)
    }
  ]

  private_nacl_egress_rules_normalized = [
    for rule in var.private_nacl_egress_rules : {
      rule_number = rule.rule_number
      protocol    = rule.protocol
      action      = rule.action
      cidr_block  = rule.cidr_block
      from_port   = coalesce(try(rule.from_port, null), rule.protocol == "-1" ? 0 : null)
      to_port     = coalesce(try(rule.to_port, null), rule.protocol == "-1" ? 0 : null)
      icmp_type   = try(rule.icmp_type, null)
      icmp_code   = try(rule.icmp_code, null)
    }
  ]

  common_tags = merge(var.tags, {
    Name = local.name_prefix
  })
}

check "public_subnets_required" {
  assert {
    condition     = length(var.public_subnets) >= 1
    error_message = "At least one public subnet is required."
  }
}

check "private_subnets_required" {
  assert {
    condition     = length(var.private_subnets) >= 1
    error_message = "At least one private subnet is required."
  }
}

check "nat_requires_public_subnet" {
  assert {
    condition     = !var.enable_nat_gateway || length(var.public_subnets) > 0
    error_message = "enable_nat_gateway requires at least one public subnet."
  }
}

check "nat_strategy_exclusive" {
  assert {
    condition     = !(var.single_nat_gateway && var.one_nat_gateway_per_az)
    error_message = "single_nat_gateway and one_nat_gateway_per_az cannot both be true."
  }
}

check "one_nat_per_az_implies_multiple_nat" {
  assert {
    condition     = !var.one_nat_gateway_per_az || !var.single_nat_gateway
    error_message = "one_nat_gateway_per_az requires single_nat_gateway = false."
  }
}

check "private_subnet_nat_az_coverage" {
  assert {
    condition = !var.enable_nat_gateway || !var.one_nat_gateway_per_az || alltrue([
      for subnet in var.private_subnets :
      contains(keys(local.nat_gateways), subnet.availability_zone)
    ])
    error_message = "Each private subnet AZ must have a public subnet in the same AZ when one_nat_gateway_per_az is enabled."
  }
}

check "nat_per_az_requires_matching_public_subnet" {
  assert {
    condition = !var.one_nat_gateway_per_az || alltrue([
      for az in distinct([for subnet in var.private_subnets : subnet.availability_zone]) :
      contains(distinct([for subnet in var.public_subnets : subnet.availability_zone]), az)
    ])
    error_message = "one_nat_gateway_per_az requires a public subnet in every private subnet availability zone."
  }
}

check "nacl_rule_numbers_unique" {
  assert {
    condition = length(distinct([
      for rule in var.public_nacl_ingress_rules : rule.rule_number
    ])) == length(var.public_nacl_ingress_rules)
    error_message = "public_nacl_ingress_rules rule_number values must be unique."
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = local.name_prefix
  })
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value.availability_zone
  cidr_block        = each.value.cidr_block

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  for_each = local.nat_gateways

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip-${each.key}"
  })

  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "nat" {
  for_each = local.nat_gateways

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
    Tier = "public"
  })
}

resource "aws_route_table" "private" {
  for_each = toset(local.private_route_table_keys)

  vpc_id = aws_vpc.vpc.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = var.one_nat_gateway_per_az ? aws_nat_gateway.nat[
        var.private_subnets[each.key].availability_zone
      ].id : aws_nat_gateway.nat[local.private_route_table_nat_az].id
    }
  }

  tags = merge(local.common_tags, {
    Name = var.one_nat_gateway_per_az ? "${local.name_prefix}-private-rt-${each.key}" : "${local.name_prefix}-private-rt"
    Tier = "private"
  })
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id = aws_subnet.private[each.key].id
  route_table_id = var.one_nat_gateway_per_az ? aws_route_table.private[each.key].id : aws_route_table.private["default"].id
}

resource "aws_network_acl" "public" {
  count = var.create_public_nacl ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = local.public_nacl_ingress_rules_normalized

    content {
      rule_no    = ingress.value.rule_number
      protocol   = ingress.value.protocol
      action     = ingress.value.action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
      icmp_type  = ingress.value.icmp_type
      icmp_code  = ingress.value.icmp_code
    }
  }

  dynamic "egress" {
    for_each = local.public_nacl_egress_rules_normalized

    content {
      rule_no    = egress.value.rule_number
      protocol   = egress.value.protocol
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      icmp_type  = egress.value.icmp_type
      icmp_code  = egress.value.icmp_code
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-nacl"
    Tier = "public"
  })
}

resource "aws_network_acl" "private" {
  count = var.create_private_nacl ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = local.private_nacl_ingress_rules_normalized

    content {
      rule_no    = ingress.value.rule_number
      protocol   = ingress.value.protocol
      action     = ingress.value.action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
      icmp_type  = ingress.value.icmp_type
      icmp_code  = ingress.value.icmp_code
    }
  }

  dynamic "egress" {
    for_each = local.private_nacl_egress_rules_normalized

    content {
      rule_no    = egress.value.rule_number
      protocol   = egress.value.protocol
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      icmp_type  = egress.value.icmp_type
      icmp_code  = egress.value.icmp_code
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-nacl"
    Tier = "private"
  })
}

resource "aws_network_acl_association" "public" {
  for_each = var.create_public_nacl ? var.public_subnets : {}

  network_acl_id = aws_network_acl.public[0].id
  subnet_id      = aws_subnet.public[each.key].id
}

resource "aws_network_acl_association" "private" {
  for_each = var.create_private_nacl ? var.private_subnets : {}

  network_acl_id = aws_network_acl.private[0].id
  subnet_id      = aws_subnet.private[each.key].id
}
