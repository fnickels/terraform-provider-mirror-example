#see: https://www.terraform.io/language/providers/requirements
terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = ">= 4.0.0"
    }
    # Specifically ask for v2.0.0
    cloudinit = {
      source  = "registry.terraform.io/hashicorp/cloudinit"
      version = "= 2.0.0"
    }
    external = {
      source  = "registry.terraform.io/hashicorp/external"
      version = ">= 0.0.0"
    }
    null = {
      source  = "registry.terraform.io/hashicorp/null"
      version = ">= 0.0.0"
    }
    artifactory = {
      source  = "registry.terraform.io/jfrog/artifactory"
      version = ">= 0.0.0"
    }
  }
}

provider "aws" {
  alias           = "us_east_1"
  region          = "us-east-1"
}

provider "aws" {
  alias           = "us_west_2"
  region          = "us-west-2"
}

data "aws_ami" "ubuntu1" {
  provider        = aws.us_east_1

  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "ubuntu2" {
  provider        = aws.us_west_2
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "my_test_aws1" {
  provider        = aws.us_east_1
  count           = 1
  ami             = data.aws_ami.ubuntu1.id
  instance_type   = "t3.micro"

  tags = {
    Name = "AWS1"
  }
}

resource "aws_instance" "my_test_aws2" {
  provider        = aws.us_west_2
  count           = 1
  ami             = data.aws_ami.ubuntu2.id
  instance_type   = "t3.micro"

  tags = {
    Name = "AWS2"
  }
}

variable test {
  type = bool
  default = true
}

output mytest {
    value = var.test
}

