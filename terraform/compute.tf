# create a key-pair for ssh access
resource "aws_key_pair" "ci-sockshop-k8s-ssh" {
  key_name   = "deploy-sock-k8s"
  public_key = file("~/.ssh/deploy-sock-k8s.pub")
}

# create k8s master node 
resource "aws_instance" "ci-sockshop-k8s-master" {
  instance_type          = var.master_instance_type
  ami                    = lookup(var.aws_amis, local.region)
  key_name               = aws_key_pair.ci-sockshop-k8s-ssh.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.sg.security_group_id]

  tags = merge(local.common_tags, {
    Name = "ci-sockshop-k8s-master"
    Role = "master" # master node
  })
}

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [aws_instance.ci-sockshop-k8s-master, aws_instance.ci-sockshop-k8s-node]
  create_duration = "30s"
}

# use null resource for provisioning - instead of provisioning directly inside the aws_instance resource [OLD METHOD]
resource "null_resource" "ci-sockshop-k8s-master" {

  # depend on aws_instance.ci-sockshop-k8s-master being created first
  depends_on = [time_sleep.wait_30_seconds]

  # re-execute when aws_instance.ci-sockshop-k8s-master is updated
  triggers = {
    instance_id = aws_instance.ci-sockshop-k8s-master.id
  }

  # file provisioner to upload file
  provisioner "file" {
    source      = "../manifests"
    destination = "/tmp/"

    # connection details
    connection {
      type        = "ssh"
      user        = var.instance_user
      private_key = file("~/.ssh/deploy-sock-k8s")
      host        = aws_instance.ci-sockshop-k8s-master.public_ip
      timeout     = "5m"
    }
  }

  # remote-exec or remote execute provisioner to run commands
  provisioner "remote-exec" {
    inline = [
      "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "sudo echo \"deb http://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee --append /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni"
    ]

    # connection details
    connection {
      type        = "ssh"
      user        = var.instance_user
      private_key = file("~/.ssh/deploy-sock-k8s")
      host        = aws_instance.ci-sockshop-k8s-master.public_ip
      timeout     = "5m"
    }
  }
}

resource "aws_instance" "ci-sockshop-k8s-node" {
  instance_type          = var.node_instance_type
  count                  = var.node_count
  ami                    = lookup(var.aws_amis, local.region)
  key_name               = aws_key_pair.ci-sockshop-k8s-ssh.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.sg.security_group_id]

  tags = merge(local.common_tags, {
    Name = "ci-sockshop-k8s-node${count.index + 1}"
    Role = "worker" # worker node
  })
}

resource "null_resource" "ci-sockshop-k8s-node" {
  count = var.node_count

  # depend on aws_instance.ci-sockshop-k8s-node being created first
  depends_on = [time_sleep.wait_30_seconds]

  # re-execute when aws_instance.ci-sockshop-k8s-node is updated
  triggers = {
    # instance_ids = join(",", aws_instance.ci-sockshop-k8s-node[*].id)
    instance_id = aws_instance.ci-sockshop-k8s-node[count.index].id
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "sudo echo \"deb http://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee --append /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni",
      "sudo sysctl -w vm.max_map_count=262144"
    ]

    connection {
      type        = "ssh"
      user        = var.instance_user
      private_key = file("~/.ssh/deploy-sock-k8s")
      host        = aws_instance.ci-sockshop-k8s-node[count.index].public_ip
      timeout     = "5m"
    }
  }
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

