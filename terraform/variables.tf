variable "aws_region" {
  type        = string
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "The name of this deployment project"
  default     = "sock-shop"
}

variable "project_tags" {
  type        = map(string)
  description = "Common tags for deployed project resources"
  default = {
    Project     = "Sock Shop K8s Deployment"
    ManagedBy   = "Terraform"
    Environment = "Dev"
  }
}

# variable "aws_amis" {
#   type        = map(string)
#   description = "The AMI to use for setting up the instances."
#   default = {
#     # Ubuntu Jammy Jellyfish 22.04 LTS
#     "eu-west-1"    = "ami-00bf8c84e3af174f6"
#     "eu-west-2"    = "ami-01dcd7d526188b94f"
#     "eu-central-1" = "ami-06e89bbb5f88b3a34"
#     "us-east-1"    = "ami-03e31863b8e1f70a5"
#     "us-east-2"    = "ami-0986e6d2d2bc905ca"
#     "us-west-1"    = "ami-0e9db8a56316dabe0"
#     "us-west-2"    = "ami-0b33ebbed151cf740"
#   }
# }

variable "vpc_cidr" {
  type        = string
  description = "The VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "The private subnet CIDR block"
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "The public subnet CIDR block"
  default     = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]
}

# ---
variable "instance_user" {
  type        = string
  description = "The user account to use on the instances to run the scripts."
  default     = "ubuntu"
}

variable "instance_type" {
  type        = string
  description = "The instance type to use for the Kubernetes nodes."
  default     = "t3.medium"
}

variable "node_count" {
  type        = string
  description = "The number of nodes in the cluster."
  default     = "3"
}
