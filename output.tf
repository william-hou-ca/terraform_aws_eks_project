output "bastion_ip" {
  value = length(aws_instance.bastion) > 0 ? aws_instance.bastion[0].public_ip : "no bastion"
}

output "eks_cluster_name" {
  value = module.eks.cluster_id
}
