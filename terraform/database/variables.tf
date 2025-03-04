variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
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
  default     = "1.32"
}

variable "eks_node_count" {
  description = "The number of nodes in the K8s cluster."
  type        = map(string)
  default = {
    min     = 3
    desired = 3
    max     = 3
  }
}

variable "eks_disk_size" {
  description = "The size of the disk (in GB) for EKS nodes."
  type        = number
  default     = 100
}

variable "eks_instance_types" {
  description = "A list of EC2 instance types for the EKS nodes."
  type        = list(string)
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}

variable "database_super_pass" {
  description = "The superuser password for the database."
  type        = string
  sensitive   = true
}

variable "database_namespace" {
  description = "The Kubernetes namespace where the database resources will be deployed."
  type        = string
  default     = "database"
}

variable "database_bucket_name" {
  description = "The s3 bucket name which is used by vertica"
  type        = string
}

variable "enable_database_installation" {
  description = "enable database installation via helmchart in terraform"
  type        = bool
  default     = false
}

variable "database_super_username" {
  description = "The name of databse super username"
  type        = string
  default     = "dbadmin"
}