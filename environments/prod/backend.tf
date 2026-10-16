terraform {
  backend "s3" {
    bucket         = "terraform-state-use1-management-mihir"
    key            = "opentofu-aws/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-use1-management-mihir"
    encrypt        = true
  }
}
