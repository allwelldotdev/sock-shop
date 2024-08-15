terraform {
  required_version = "~>1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.0"
    }
  }
}

provider "aws" {
  region = local.region
}
