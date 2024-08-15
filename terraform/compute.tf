# create a key-pair for ssh access
resource "aws_key_pair" "ci-sockshop-k8s-ssh" {
  key_name   = "deploy-sock-k8s"
  public_key = file("~/.ssh/deploy-sock-k8s.pub")
}

# create k8s master node 
resource "aws_instance" "ci-sockshop-k8s-master" {
  instance_type               = var.master_instance_type
  ami                         = lookup(var.aws_amis, local.region)
  key_name                    = aws_key_pair.ci-sockshop-k8s-ssh.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.sg.security_group_id]
  associate_public_ip_address = true

  user_data = <<-EOF
  "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
  "sudo echo \"deb http://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee --append /etc/apt/sources.list.d/kubernetes.list",
  "sudo apt-get update",
  "sudo apt-get install -y docker.io",
  "sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni"
  EOF

  tags = merge(local.common_tags, {
    Name = "ci-sockshop-k8s-master"
    Role = "master" # master node
  })
}

resource "aws_instance" "ci-sockshop-k8s-node" {
  instance_type               = var.node_instance_type
  count                       = var.node_count
  ami                         = lookup(var.aws_amis, local.region)
  key_name                    = aws_key_pair.ci-sockshop-k8s-ssh.key_name
  subnet_id                   = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]
  vpc_security_group_ids      = [module.sg.security_group_id]
  associate_public_ip_address = true

  user_data = <<-EOF
  "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
  "sudo echo \"deb http://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee --append /etc/apt/sources.list.d/kubernetes.list",
  "sudo apt-get update",
  "sudo apt-get install -y docker.io",
  "sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni",
  "sudo sysctl -w vm.max_map_count=262144"
  EOF

  tags = merge(local.common_tags, {
    Name = "ci-sockshop-k8s-node${count.index + 1}"
    Role = "worker" # worker node
  })
}

resource "aws_elb" "ci-sockshop-k8s-elb" {

  # make this ELB dependent on aws_instance.ci-sockshop-k8s-node creation/update
  depends_on = [aws_instance.ci-sockshop-k8s-node]

  name      = "ci-sockshop-k8s-elb"
  instances = aws_instance.ci-sockshop-k8s-node[*].id
  # availability_zones = data.aws_availability_zones.available.names
  security_groups = [module.sg.security_group_id]
  subnets         = module.vpc.public_subnets

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 30001
    instance_protocol = "http"
  }

  # TODO: create an ssl certificate to allow HTTPS connection via route53 and open listener on this elb
  # listener {
  #   instance_port      = 30001
  #   instance_protocol  = "http"
  #   lb_port            = 443
  #   lb_protocol        = "https"
  #   ssl_certificate_id = #arn
  # }

  # TODO: set up health check for elb
  # health_check {
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  #   timeout             = 3
  #   target              = "HTTP:30001/"
  #   interval            = 30
  # }

  listener {
    lb_port           = 9411
    instance_port     = 30002
    lb_protocol       = "http"
    instance_protocol = "http"
  }

  tags = merge(local.common_tags, {
    Name = "ci-sockshop-k8s-elb"
  })
}

