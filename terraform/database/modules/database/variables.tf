variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "eks_cluster_identity_oidc_issuer" {
  description = "The OIDC issuer URL for the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "database_namespace" {
  description = "The Kubernetes namespace where the database resources will be deployed."
  type        = string
  default     = "database"
}

variable "database_super_pass" {
  description = "The superuser password for the database."
  type        = string
  sensitive   = true
}

variable "database_super_pass_secret" {
  description = "The superuser password secret for the database."
  type        = string
  default     = "database-super-password-secret"
}

variable "service_account_name" {
  description = "The name of the Kubernetes service account for accessing AWS resources."
  type        = string
  default     = "database-s3-bucket-sa"
}

variable "resource_tags" {
  description = "A map of tags to assign to the EKS cluster resources."
  type        = map(string)
  default     = {}
}