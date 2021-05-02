output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "eks_cluster_name" {
  value = module.eks.cluster_id
}

