provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile]
    }
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {
}

module "vpc" {
  source                       = "./modules/vpc"
  vpc_name                     = var.vpc_name
  eks_cluster_name             = var.eks_cluster_name
  vpc_cidr                     = var.vpc_cidr
  aws_availability_zones_names = data.aws_availability_zones.available.names
}

module "eks" {
  source             = "./modules/eks"
  eks_cluster_name   = var.eks_cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.vpc_private_subnets
  eks_node_count     = var.eks_node_count
  eks_tags           = var.eks_tags
  eks_instance_types = var.eks_instance_types
  eks_version        = var.eks_version
  eks_disk_size      = var.eks_disk_size
}

module "metrics_server" {
  depends_on = [module.eks]
  source     = "./modules/metrics-server"
}

module "aws_lb_controller" {
  source                           = "./modules/aws_lb_controller"
  aws_region                       = var.aws_region
  eks_cluster_name                 = var.eks_cluster_name
  vpc_id                           = module.vpc.vpc_id
  eks_cluster_identity_oidc_issuer = module.eks.eks_cluster_identity_oidc_issuer
}

