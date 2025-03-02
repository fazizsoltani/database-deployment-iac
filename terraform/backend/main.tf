provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_s3_bucket" "terraform_s3_backend_vertica" {
  bucket = "terraform-backend-s3-vertica"

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "terraform_s3_backend_vertica_public_block" {
  bucket                  = aws_s3_bucket.terraform_s3_backend_vertica.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "terraform_s3_backend_vertica_kms_key" {
  description             = "This key is used to encrypt terraform-backend-s3-vertica bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_s3_backend_vertica_sse" {
  bucket = aws_s3_bucket.terraform_s3_backend_vertica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_s3_backend_vertica_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "terraform_s3_backend_vertica_versioning" {
  bucket = aws_s3_bucket.terraform_s3_backend_vertica.id
  versioning_configuration {
    status = "Enabled"
  }
}