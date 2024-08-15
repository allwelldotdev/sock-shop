variable "aws_amis" {
  description = "The AMI to use for setting up the instances."
  default = {
    # Ubuntu Jammy Jellyfish 18.04 LTS
    "eu-west-1"    = "ami-00bf8c84e3af174f6"
    "eu-west-2"    = "ami-01dcd7d526188b94f"
    "eu-central-1" = "ami-06e89bbb5f88b3a34"
    "us-east-1"    = "ami-03e31863b8e1f70a5"
    "us-east-2"    = "ami-0986e6d2d2bc905ca"
    "us-west-1"    = "ami-0e9db8a56316dabe0"
    "us-west-2"    = "ami-0b33ebbed151cf740"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "instance_user" {
  description = "The user account to use on the instances to run the scripts."
  default     = "ubuntu"
}

variable "master_instance_type" {
  description = "The instance type to use for the Kubernetes master."
  default     = "t3.large"
}

variable "node_instance_type" {
  description = "The instance type to use for the Kubernetes nodes."
  default     = "t3.large"
}

variable "node_count" {
  description = "The number of nodes in the cluster."
  default     = "3"
}
