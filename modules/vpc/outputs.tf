output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.vpc.id
}

output "vpc_arn" {
  description = "VPC ARN."
  value       = aws_vpc.vpc.arn
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.vpc.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.gateway.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by logical name."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by logical name."
  value       = { for key, subnet in aws_subnet.private : key => subnet.id }
}

output "public_subnet_arns" {
  description = "Public subnet ARNs keyed by logical name."
  value       = { for key, subnet in aws_subnet.public : key => subnet.arn }
}

output "private_subnet_arns" {
  description = "Private subnet ARNs keyed by logical name."
  value       = { for key, subnet in aws_subnet.private : key => subnet.arn }
}

output "public_subnet_cidr_blocks" {
  description = "Public subnet CIDR blocks keyed by logical name."
  value       = { for key, subnet in aws_subnet.public : key => subnet.cidr_block }
}

output "private_subnet_cidr_blocks" {
  description = "Private subnet CIDR blocks keyed by logical name."
  value       = { for key, subnet in aws_subnet.private : key => subnet.cidr_block }
}

output "availability_zones" {
  description = "Availability zones used by public and private subnets."
  value = distinct(concat(
    [for subnet in var.public_subnets : subnet.availability_zone],
    [for subnet in var.private_subnets : subnet.availability_zone],
  ))
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs keyed by availability zone."
  value       = { for az, nat in aws_nat_gateway.nat : az => nat.id }
}

output "nat_eip_public_ips" {
  description = "Elastic IP public addresses for NAT gateways keyed by availability zone."
  value       = { for az, eip in aws_eip.nat : az => eip.public_ip }
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs keyed by subnet name or default."
  value       = { for key, table in aws_route_table.private : key => table.id }
}

output "public_nacl_id" {
  description = "Public Network ACL ID. Null when create_public_nacl is false."
  value       = try(aws_network_acl.public[0].id, null)
}

output "private_nacl_id" {
  description = "Private Network ACL ID. Null when create_private_nacl is false."
  value       = try(aws_network_acl.private[0].id, null)
}

output "nat_gateway_enabled" {
  description = "Whether NAT gateways were created."
  value       = var.enable_nat_gateway
}

output "single_nat_gateway" {
  description = "Whether a single shared NAT gateway is used."
  value       = var.enable_nat_gateway && var.single_nat_gateway && !var.one_nat_gateway_per_az
}
