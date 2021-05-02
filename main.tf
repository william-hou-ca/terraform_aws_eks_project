provider "aws" {
  region = "ca-central-1"
}

###########################################################################
#
# Create a bastion instance in the public subnet.
#
###########################################################################

resource "aws_instance" "bastion" {

  #required parametres
  ami           = data.aws_ami.amz2.id
  instance_type = "t2.micro"

  #optional parametres
  associate_public_ip_address = true
  key_name = var.ec2_key_name #key paire name exists in aws.

  vpc_security_group_ids = [aws_security_group.sg_public.id]

  subnet_id = module.vpc.public_subnets[0]

  user_data = <<-EOF
          #! /bin/sh
          sudo yum update -y
          sudo amazon-linux-extras install epel -y 
          cat <<EOR | sudo tee /etc/yum.repos.d/kubernetes.repo
          [kubernetes]
          name=Kubernetes
          baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
          enabled=1
          gpgcheck=1
          repo_gpgcheck=1
          gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
          EOR
          sudo yum install kubectl-0:1.18.17-0.x86_64 -y
          sudo yum install git -y
          cd /home/ec2-user
          echo "alias k=kubectl" | sudo tee -a /home/ec2-user/.bashrc
          echo 'aws eks update-kubeconfig --region ca-central-1 --name ${local.cluster_name}' | sudo tee /home/ec2-user/k8s.sh
EOF

  tags = {
    Name = "tf-eks-bastionVM"
  }

}