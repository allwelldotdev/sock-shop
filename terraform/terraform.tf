terraform {
  required_version = "~>1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.4"
    }
  }

  # set terraform backend to remote: using aws s3 bucket for state file
  # and aws dynamodb for state locking
  backend "s3" {
    bucket         = "terraform-backend-frz9g"
    key            = "sock-shop/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-sock-shop"
  }
}
