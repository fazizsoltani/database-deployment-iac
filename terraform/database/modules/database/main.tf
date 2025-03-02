locals {
  default_tags = {
    "ManagedBy" = "Terraform"
  }

  # Merged user provided and default Tags
  merged_tags = merge(local.default_tags, var.resource_tags)
}

resource "aws_s3_bucket" "s3_communal" {
  bucket = "test-vertica-s3-bucket"

  tags = local.merged_tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_endpoint_policy" "s3_vpce_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.s3_bucket_role.arn
        },
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          aws_s3_bucket.s3_communal.arn,
          "${aws_s3_bucket.s3_communal.arn}/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:SourceVpc" : "${var.vpc_id}"
          }
        }
      }
    ]
  })
}

locals {
  oidc_issuer = trim(var.eks_cluster_identity_oidc_issuer, "https://")
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/${local.oidc_issuer}"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:${var.database_namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "s3_bucket_role" {
  name               = "s3-bucket-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "s3_bucket_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = compact([
      "${aws_s3_bucket.s3_communal.arn}/*",
      "${aws_s3_bucket.s3_communal.arn}"
    ])
  }
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "s3-bucket-policy"
  description = "policy for s3 to assigne to service account"
  policy      = data.aws_iam_policy_document.s3_bucket_policy_document.json
}

resource "aws_iam_role_policy_attachment" "s3_bucket_policy_attachment" {
  role       = aws_iam_role.s3_bucket_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
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

# If your Kubernetes cluster is in the cloud or on a managed service, each Vertica node must operate in the same availability zone.
# https://docs.vertica.com/25.1.x/en/containerized/configuring-communal-storage/
resource "helm_release" "verticadatabase" {
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
    serviceAccountName: ${var.service_account_name}
    communal:
      path: "s3://${aws_s3_bucket.s3_communal.id}"
      endpoint: "https://s3.${var.aws_region}.amazonaws.com"
      s3ServerSideEncryption: SSE-S3
      region: ${var.aws_region}
    subclusters:
      - name: primary
        size: 3
        serviceType: LoadBalancer
        serviceAnnotations:
              service.beta.kubernetes.io/aws-load-balancer-type: external
              service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
              service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
        affinity:
          podAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/name
                      operator: In
                      values:
                        - vertica
                topologyKey: topology.kubernetes.io/zone
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