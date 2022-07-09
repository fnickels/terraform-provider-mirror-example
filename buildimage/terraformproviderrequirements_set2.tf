#see: https://www.terraform.io/language/providers/requirements
terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "4.20.0"
    }
    cloudinit = {
      source  = "registry.terraform.io/hashicorp/cloudinit"
      version = "2.0.0"
    }
    # new provider
    null = {
      source  = "registry.terraform.io/hashicorp/null"
      version = "3.1.0"
    }
  }
}