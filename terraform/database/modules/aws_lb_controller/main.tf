locals {
  aws_lbc_service_account_name = var.aws_lbc_service_account_name

  aws_lbc_values = {

    cluster_name = var.eks_cluster_name
    service_account_annotations = jsonencode({
      "eks.amazonaws.com/role-arn" = module.aws_lbc_iam_assumable_role_admin.iam_role_arn
    })
    service_account_name = var.aws_lbc_service_account_name
    region               = var.aws_region
    vpc_id               = var.vpc_id
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name       = var.aws_lbc_release_name
  chart      = var.aws_lbc_chart_name
  repository = var.aws_lbc_chart_repository
  version    = var.aws_lbc_chart_version
  namespace  = var.aws_lbc_chart_namespace

  max_history = var.aws_lbc_max_history
  timeout     = var.aws_lbc_chart_timeout

  values = [
    templatefile("${path.module}/templates/aws_load_balancer_controller_values.yaml", local.aws_lbc_values),
  ]
}