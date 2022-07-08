terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "4.2.0"
    }
    cloudinit = {
      source  = "registry.terraform.io/hashicorp/cloudinit"
      version = "2.2.0"
    }
    # only in Set 1
    external = {
      source  = "registry.terraform.io/hashicorp/external"
      version = "2.1.0"
    }
  }
}