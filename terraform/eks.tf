provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_ami" "arm64" {
  filter {
    name   = "name"
    values = ["amazon-eks-arm64-node-${local.cluster_version}-v*"]
  }
  most_recent = true
  owners      = ["amazon"]
}

data "aws_ami" "amd64" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-v*"]
  }
  most_recent = true
  owners      = ["amazon"]
}

module "eks" {
  source           = "terraform-aws-modules/eks/aws"
  version          = "~> 17.0.3"
  cluster_name     = local.cluster_name
  cluster_version  = local.cluster_version
  subnets          = module.vpc.private_subnets
  vpc_id           = module.vpc.vpc_id
  enable_irsa      = true
  write_kubeconfig = false

  map_roles = [
    {
      groups : ["system:masters"],
      rolearn : local.admin_role_arn,
      username : "AWSAdministrator"
    }
  ]

  worker_groups = [
    #{
    #  instance_type    = "t4g.large"
    #  asg_min_size     = 1
    #  asg_max_size     = 2
    #  root_volume_type = "gp2"
    #  ami_id           = data.aws_ami.arm64.id
    #},
    {
      instance_type          = "m4.large"
      asg_min_size           = 1
      asg_max_size           = 2
      root_volume_type       = "gp2"
      ami_id                 = data.aws_ami.amd64.id
      asg_recreate_on_change = true
    }
  ]
}
