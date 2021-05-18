provider "aws" {
  region = "ca-central-1"
}

###########################################################################
#
# Create a bastion instance in the public subnet.
#
###########################################################################

resource "aws_instance" "bastion" {
  count = 1
  #required parametres
  ami           = data.aws_ami.amz2.id
  instance_type = "t2.micro"

  #optional parametres
  associate_public_ip_address = true
  key_name = var.ec2_key_name #key paire name exists in aws.

  vpc_security_group_ids = [aws_security_group.sg_public.id]

  subnet_id = module.vpc.public_subnets[0]

  user_data = <<-EOF
#!/bin/sh
sudo yum update -y
sudo amazon-linux-extras install epel -y
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
echo '#######################installer helm###############################'
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
sudo chown -R ec2-user:ec2-user /home/ec2-user
cat << EOR | sudo tee /etc/yum.repos.d/kubernetes.repo
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
echo '#######################install metric service##########################'
#echo 'kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml' | sudo tee -a k8s.sh
sleep 2
#######################################################################
sudo tee -a /home/ec2-user/aws_ebs_csi.sh << EOCSI
#!/bin/sh
echo '#######################installer ebs csi###############################'
cd /home/ec2-user
curl -o example-iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v1.0.0/docs/example-iam-policy.json
aws iam create-policy --policy-name AmazonEKS_EBS_CSI_Driver_Policy --policy-document file://example-iam-policy.json
aws eks describe-cluster --name ${module.eks.cluster_id} --query "cluster.identity.oidc.issuer" --output text
eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster ${local.cluster_name} --attach-policy-arn arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AmazonEKS_EBS_CSI_Driver_Policy --approve --override-existing-serviceaccounts
sleep 2
#aws cloudformation describe-stacks --stack-name eksctl-${module.eks.cluster_id}-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa --query='Stacks[].Outputs[?OutputKey==`Role1`].OutputValue' --output text
sudo chown -R ec2-user:ec2-user /home/ec2-user
echo '#######################deploy ebs csi driver to k8s###############################'
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm upgrade -install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system --set enableVolumeResizing=true --set enableVolumeSnapshot=true --set serviceAccount.controller.create=false --set serviceAccount.controller.name=ebs-csi-controller-sa
echo '#######################download demo##############################################'
git clone https://github.com/kubernetes-sigs/aws-ebs-csi-driver.git
EOCSI
EOF

  tags = {
    Name = "tf-eks-bastionVM"
  }

 lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,user_data
    ]
  }
}


