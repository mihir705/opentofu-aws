terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws" # resolved from registry.opentofu.org
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

provider "aws" {
  alias  = "replica"
  region = var.aws_replica_region

  default_tags {
    tags = var.default_tags
  }
}
