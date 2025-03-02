
locals {
  default_tags = {
    "ManagedBy" = "Terraform"
  }

  # Merged user provided and default Tags
  merged_tags = merge(local.default_tags, var.resource_tags)
}

module "aws_lbc_iam_assumable_role_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.17"

  create_role = true

  role_name        = "${terraform.workspace}-${var.aws_lbc_iam_role_name}"
  role_description = var.aws_lbc_iam_role_description

  provider_url = var.eks_cluster_identity_oidc_issuer
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${var.aws_lbc_chart_namespace}:${local.aws_lbc_service_account_name}"
  ]

  tags = local.merged_tags
}

resource "aws_iam_role_policy" "aws_lbc_controller" {
  name_prefix = "AWSLoadBalancerControllerIAMPolicy"
  policy      = data.http.aws_lbc_iam_policy.body
  role        = module.aws_lbc_iam_assumable_role_admin.iam_role_name
}

data "http" "aws_lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${var.aws_lbc_image_tag}/docs/install/iam_policy.json"
}