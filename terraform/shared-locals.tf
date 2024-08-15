locals {
  project_name = "sock-shops-k8s"
  region       = "us-east-1"

  # networking
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.0.0/24"]
  public_subnet_cidrs  = ["10.0.100.0/24"]

  # tags
  common_tags = {
    Project     = "Sock Shop K8s Deployment"
    ManagedBy   = "Terraform"
    Environment = "Dev"
  }
}
