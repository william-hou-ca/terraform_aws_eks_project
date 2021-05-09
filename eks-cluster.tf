module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.18"
  subnets         = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  vpc_id = module.vpc.vpc_id

  enable_irsa = true

  workers_group_defaults = {
    root_volume_type = "gp2"
    root_volume_size = 8
    enable_monitoring = false
    instance_type     = "t2.micro"
    key_name = var.ec2_key_name
  }

  worker_groups = [
    {
      name                          = "worker-group-web"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.sg_private.id]
      subnets = module.vpc.private_subnets
    },
    {
      name                          = "worker-group-db"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.sg_private.id]
      subnets = module.vpc.private_subnets
    }
  ]

  wait_for_cluster_interpreter = ["c:/Program Files/git/bin/sh.exe", "-c"]

  tags = {
    Environment = "training"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
