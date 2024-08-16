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

variable "instance_type" {
  type        = string
  description = "The instance type to use for the Kubernetes nodes."
  default     = "t3.medium"
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the cluster."
  default     = 3
}
