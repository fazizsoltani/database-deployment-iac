
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_version

  cluster_endpoint_public_access           = false
  enable_cluster_creator_admin_permissions = true

  cluster_enabled_log_types = var.cluster_enabled_log_types

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v1.11.4-eksbuild.2"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v1.32.0-eksbuild.2"
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v1.19.3-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts        = "OVERWRITE"
      addon_version            = "v1.40.0-eksbuild.1"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  eks_managed_node_groups = {
    "${var.eks_cluster_name}" = {
      ami_type       = "AL2_x86_64"
      instance_types = var.eks_instance_types

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.eks_disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = false
          }
        }
      }


      desired_size = var.eks_node_count["desired"]
      max_size     = var.eks_node_count["max"]
      min_size     = var.eks_node_count["min"]

      iam_role_additional_policies = local.iam_role_additional_policies

    }
  }

  tags = local.merged_tags
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.52.2"

  create_role                   = true
  role_name                     = "AmazonEBSCSIDriverRole"
  role_description              = "Amazon EBS CSI Driver Role"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
  tags                          = local.merged_tags
}

locals {
  # IAM policies added to eks nodes
  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  default_tags = {
    "ManagedBy" = "Terraform"
  }

  # Merged user provided and default Tags
  merged_tags = merge(local.default_tags, var.eks_tags)
}