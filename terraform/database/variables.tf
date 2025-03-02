variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "aws_profile" {
  description = "The AWS profile"
  type        = string
  default     = "default"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "eks_cluster_name" {
  description = "The EKS cluster name"
  type        = string
}

variable "eks_version" {
  description = "The Kubernetes version for the EKS cluster."
  type        = string
}

variable "eks_node_count" {
  description = "The number of nodes in the K8s cluster."
  type        = map(string)
}

variable "eks_disk_size" {
  description = "The size of the disk (in GB) for EKS nodes."
  type        = number
}

variable "eks_instance_types" {
  description = "A list of EC2 instance types for the EKS nodes."
  type        = list(string)
}

variable "eks_tags" {
  description = "A map of tags to assign to the EKS cluster resources."
  type        = map(string)
}