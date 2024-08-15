output "node_addresses" {
  value = aws_instance.ci-sockshop-k8s-node[*].public_dns
}

output "master_address" {
  value = aws_instance.ci-sockshop-k8s-master.public_dns
}

output "sock_shop_address" {
  value = aws_elb.ci-sockshop-k8s-elb.dns_name
}

# output "azs" {
#   value = data.aws_availability_zones.available.names
# }

output "master_public_ip" {
  value = data.aws_instance.ci-sockshop-k8s-master.public_ip
}

output "node_public_ips" {
  value = data.aws_instance.ci-sockshop-k8s-node[*].public_ip
}
