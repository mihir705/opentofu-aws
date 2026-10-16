# VPC Module

OpenTofu module to create a VPC with public and private subnets, Internet Gateway, NAT Gateway, route tables, and Network ACLs.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_vpc` | Yes | Core VPC |
| `aws_internet_gateway` | Yes | Attached to VPC |
| `aws_subnet` | Yes | Public and private subnets from input maps |
| `aws_route_table` | Yes | One public + one or more private route tables |
| `aws_route_table_association` | Yes | Associates subnets with route tables |
| `aws_eip` | No | Created when `enable_nat_gateway = true` |
| `aws_nat_gateway` | No | Single NAT or one per AZ |
| `aws_network_acl` | No | Public and/or private NACLs when enabled |
| `aws_network_acl_association` | No | Associates NACLs with subnets |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Standard VPC — 2 public + 2 private subnets

```hcl
module "main_vpc" {
  source = "./modules/vpc"

  name       = "my-company-prod"
  cidr_block = "10.0.0.0/16"

  public_subnets = {
    az-a = {
      availability_zone = "ap-south-1a"
      cidr_block        = "10.0.1.0/24"
    }
    az-b = {
      availability_zone = "ap-south-1b"
      cidr_block        = "10.0.2.0/24"
    }
  }

  private_subnets = {
    az-a = {
      availability_zone = "ap-south-1a"
      cidr_block        = "10.0.11.0/24"
    }
    az-b = {
      availability_zone = "ap-south-1b"
      cidr_block        = "10.0.12.0/24"
    }
  }

  tags = {
    Environment = "prod"
    Purpose     = "main-network"
  }
}
```

### Environment stack (prod)

```hcl
vpcs = {
  main = {
    name       = "my-company-prod"
    cidr_block = "10.0.0.0/16"

    public_subnets = {
      az-a = { availability_zone = "ap-south-1a", cidr_block = "10.0.1.0/24" }
      az-b = { availability_zone = "ap-south-1b", cidr_block = "10.0.2.0/24" }
    }

    private_subnets = {
      az-a = { availability_zone = "ap-south-1a", cidr_block = "10.0.11.0/24" }
      az-b = { availability_zone = "ap-south-1b", cidr_block = "10.0.12.0/24" }
    }

    tags = { Purpose = "main-network" }
  }
}
```

## Architecture

```
                    Internet
                        |
                 Internet Gateway
                        |
        +---------------+---------------+
        |                               |
   Public Subnet A              Public Subnet B
   (10.0.1.0/24)                (10.0.2.0/24)
   ap-south-1a                   ap-south-1b
        |                               |
   NAT Gateway (optional)          NAT Gateway (optional, per-AZ mode)
        |                               |
   Private Subnet A              Private Subnet B
   (10.0.11.0/24)                (10.0.12.0/24)
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name prefix for resources | `string` | — | yes |
| `cidr_block` | VPC CIDR | `string` | — | yes |
| `public_subnets` | Public subnet map | `map(object)` | — | yes |
| `private_subnets` | Private subnet map | `map(object)` | — | yes |
| `enable_dns_hostnames` | Enable DNS hostnames | `bool` | `true` | no |
| `enable_dns_support` | Enable DNS support | `bool` | `true` | no |
| `enable_nat_gateway` | Create NAT gateway(s) | `bool` | `true` | no |
| `single_nat_gateway` | One shared NAT (cost saving) | `bool` | `true` | no |
| `one_nat_gateway_per_az` | NAT per AZ (HA) | `bool` | `false` | no |
| `create_public_nacl` | Create public NACL | `bool` | `true` | no |
| `create_private_nacl` | Create private NACL | `bool` | `true` | no |
| `public_nacl_ingress_rules` | Public NACL ingress rules | `list(object)` | HTTP/HTTPS + ephemeral | no |
| `public_nacl_egress_rules` | Public NACL egress rules | `list(object)` | Allow all | no |
| `private_nacl_ingress_rules` | Private NACL ingress rules | `list(object)` | VPC CIDR | no |
| `private_nacl_egress_rules` | Private NACL egress rules | `list(object)` | Allow all | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_arn` | VPC ARN |
| `vpc_cidr_block` | VPC CIDR block |
| `internet_gateway_id` | Internet Gateway ID |
| `public_subnet_ids` | Public subnet IDs by name |
| `private_subnet_ids` | Private subnet IDs by name |
| `nat_gateway_ids` | NAT Gateway IDs by AZ |
| `nat_eip_public_ips` | NAT Elastic IP addresses by AZ |
| `public_route_table_id` | Public route table ID |
| `private_route_table_ids` | Private route table IDs |
| `public_nacl_id` | Public Network ACL ID |
| `private_nacl_id` | Private Network ACL ID |

## Design notes

- **Public subnets** route `0.0.0.0/0` to the Internet Gateway.
- **Private subnets** route `0.0.0.0/0` to NAT Gateway(s) when enabled.
- **Single NAT** (default) places one NAT in the first public subnet — lower cost, AZ dependency for private egress.
- **NAT per AZ** sets `single_nat_gateway = false` and `one_nat_gateway_per_az = true` for HA.
- **Public NACL** allows HTTP/HTTPS inbound and ephemeral return traffic (stateless).
- **Private NACL** allows VPC CIDR traffic plus ephemeral return traffic from the internet (required for NAT egress).
- Security groups are not included — add per workload (Lambda, EC2, RDS).

## NAT gateway cost note

NAT Gateways incur hourly and data processing charges. Use `single_nat_gateway = true` (default) for dev/staging; use `one_nat_gateway_per_az = true` for production HA when required.
