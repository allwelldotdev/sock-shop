provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "${var.project_name}-${random_string.suffix.result}"
}

# create a random 8-length string character
resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.12.1"

  name = "${var.project_name}-vpc"

  cidr = var.vpc_cidr
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = merge(var.project_tags, {
    Name = "${var.project_name}-vpc"
  })
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    main = {
      name = "${var.project_name}-node-group"

      instance_types = [var.instance_type]

      min_size     = var.node_count
      max_size     = var.node_count
      desired_size = var.node_count
    }
  }

  tags = merge(var.project_tags, {
    Name = "${var.project_name}-eks"
  })
}

# retrieve ARN of AWS-managed policy for the EBS CSI driver
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# create IAM role to be assumed by EBS CSI driver service in cluster 
module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

# create sg with ingress and egress rules
module "eks_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = "${var.project_name}-sg"
  description = "Security group with self ingress, specific open ports, and all egress traffic"
  vpc_id      = module.vpc.vpc_id

  # TODO: make this security group more secure

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
      to_port     = 30001
      protocol    = "tcp"
      description = "Access to ports 30001"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 30002
      to_port     = 30002
      protocol    = "tcp"
      description = "Access to ports 30002"
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

  tags = merge(var.project_tags, {
    Name = "${var.project_name}-sg"
  })
}
