variable "resource_tags" {
  description = "A map of tags to assign to the EKS cluster resources."
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}
variable "eks_cluster_name" {
  description = "The EKS cluster name"
  type        = string
}
variable "eks_cluster_identity_oidc_issuer" {
  description = "The OIDC issuer URL for the EKS cluster."
  type        = string
}

########################
# AWS load balancer controller Helm repo values
########################
variable "aws_lbc_release_name" {
  description = "AWS load balancer controller - Helm release name"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "aws_lbc_chart_name" {
  description = "AWS load balancer controller - Helm chart name to provision"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "aws_lbc_chart_repository" {
  description = "AWS load balancer controller - Helm repository for the chart"
  type        = string
  default     = "https://aws.github.io/eks-charts"
}

variable "aws_lbc_chart_version" {
  description = "AWS load balancer controller - version of Chart to install. Set to empty to install the latest version"
  type        = string
  default     = "1.11.0"
}

variable "aws_lbc_chart_namespace" {
  description = "AWS load balancer controller - Namespace to install the chart into"
  type        = string
  default     = "kube-system"
}

variable "aws_lbc_chart_timeout" {
  description = "AWS load balancer controller - Timeout to wait for the Chart to be deployed."
  type        = number
  default     = 300
}

variable "aws_lbc_max_history" {
  description = "AWS load balancer controller - Max History for Helm"
  type        = number
  default     = 20
}

########################
# AWS load balancer controller chart values
########################
variable "aws_lbc_image_tag" {
  description = "AWS load balancer controller - Image tag"
  type        = string
  default     = "v2.11.0"
}

variable "aws_lbc_service_account_name" {
  description = "AWS load balancer controller - Name of service account to create. Not generated"
  type        = string
  default     = "aws-load-balancer-controller"
}


########################
# AWS load balancer controller IAM role
########################

variable "aws_lbc_iam_role_name" {
  description = "AWS load balancer controller - Name of IAM role for controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "aws_lbc_iam_role_description" {
  description = "AWS load balancer controller - Description for IAM role for controller"
  type        = string
  default     = "Used by AWS Load Balancer Controller for EKS"
}