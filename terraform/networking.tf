module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.12.1"

  name = "${local.project_name}-vpc"
  cidr = local.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  # enable_nat_gateway = true

  tags = merge(local.common_tags, {})
}

# TODO: make this security group more secure
module "sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = "${local.project_name}-sg"
  description = "Security group with self ingress, specific open ports, and all egress traffic"
  vpc_id      = module.vpc.vpc_id

  # rule for internal traffic
  ingress_with_self = [{
    rule = "all-all"
  }]

  # ingress rules for specific ports
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9411
      to_port     = 9411
      protocol    = "tcp"
      description = "Access to port 9411"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 30001
      to_port     = 30002
      protocol    = "tcp"
      description = "Access to ports 30001 and 30002"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 31601
      to_port     = 31601
      protocol    = "tcp"
      description = "Access to port 31601"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # egress rule for all outbound traffic
  egress_rules = ["all-all"]
}
