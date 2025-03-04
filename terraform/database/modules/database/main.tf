locals {
  default_tags = {
    "ManagedBy" = "Terraform"
  }

  # Merged user provided and default Tags
  merged_tags = merge(local.default_tags, var.resource_tags)

  oidc_issuer = trim(var.eks_cluster_identity_oidc_issuer, "https://")

}

resource "kubernetes_service_account" "s3_bucket_sa" {
  metadata {
    name      = var.service_account_name
    namespace = var.database_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.account_id}:role/${aws_iam_role.s3_bucket_role.name}"
    }
  }
}

resource "kubernetes_secret" "s3_bucket_secret" {
  metadata {
    namespace = var.database_namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.s3_bucket_sa.metadata.0.name
    }

    generate_name = "s3-bucket-"
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

resource "helm_release" "verticadatabase" {
  count      = var.enable_database_installation ? 1 : 0
  name       = "verticadatabase"
  chart      = "../../charts/database" # Relative to Terraform directory
  namespace  = var.database_namespace
  depends_on = [kubernetes_secret.database_super_password, kubernetes_namespace.database_namespace]

  values = [
    <<-EOF
    local:
      storageClass: gp2
      requestSize: 2Gi
    passwordSecret: ${var.database_super_pass_secret}
    superUsername: ${var.database_super_username}
    serviceAccountName: ${var.service_account_name}
    communal:
      path: "s3://${aws_s3_bucket.s3_communal.id}"
      endpoint: "https://s3.${var.aws_region}.amazonaws.com"
      s3ServerSideEncryption: SSE-S3
      region: ${var.aws_region}
    EOF  
  ]
}

resource "kubernetes_secret" "database_super_password" {
  depends_on = [kubernetes_namespace.database_namespace]
  metadata {
    name      = var.database_super_pass_secret
    namespace = var.database_namespace
  }

  data = {
    password = var.database_super_pass
  }
}

resource "kubernetes_namespace" "database_namespace" {
  metadata {

    name = var.database_namespace
  }
}