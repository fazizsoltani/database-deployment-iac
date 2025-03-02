variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "eks_cluster_name" {
  description = "The EKS name"
  type        = string
}

variable "aws_availability_zones_names" {
  description = "List of AWS Availability Zones"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}