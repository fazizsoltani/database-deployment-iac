
resource "aws_s3_bucket" "s3_communal" {
  bucket = var.database_bucket_name

  tags = local.merged_tags
}

resource "aws_vpc_endpoint" "s3_endpoind" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  tags         = local.merged_tags
}

resource "aws_vpc_endpoint_policy" "s3_vpce_policy" {
  depends_on = [aws_vpc_endpoint.s3_endpoind, aws_s3_bucket.s3_communal]

  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoind.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${aws_iam_role.s3_bucket_role.arn}"
        },
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "${aws_s3_bucket.s3_communal.arn}",
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

resource "aws_s3_bucket_public_access_block" "s3_communal_public_block" {
  bucket                  = aws_s3_bucket.s3_communal.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

}

resource "aws_kms_key" "s3_communal_kms_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = local.merged_tags
}


resource "aws_s3_bucket_server_side_encryption_configuration" "s3_communal_sse" {
  bucket = aws_s3_bucket.s3_communal.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_communal_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_communal_versioning" {
  bucket = aws_s3_bucket.s3_communal.id
  versioning_configuration {
    status = "Enabled"
  }
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
  name                 = "s3-bucket-role"
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  permissions_boundary = aws_iam_policy.s3_permission_boundary.arn
  tags                 = local.merged_tags
}

data "aws_iam_policy_document" "s3_bucket_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.s3_communal.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      "${aws_s3_bucket.s3_communal.arn}/*"
    ]
  }

}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "s3-bucket-policy"
  description = "policy for s3 to assigne to service account"
  policy      = data.aws_iam_policy_document.s3_bucket_policy_document.json
  tags        = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "s3_bucket_policy_attachment" {
  role       = aws_iam_role.s3_bucket_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn

}

resource "aws_iam_policy" "s3_permission_boundary" {
  name = "s3-permission-boundary"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ],
        "Resource" : [
          aws_s3_bucket.s3_communal.arn,
          "${aws_s3_bucket.s3_communal.arn}/*"
        ]
      },
      {
        "Effect" : "Deny",
        "Action" : "s3:*",
        "Resource" : "*",
        "Condition" : {
          "StringNotEquals" : {
            "aws:RequestedRegion" : var.aws_region
          }
        }
      }
    ]
  })
  tags = local.merged_tags
}