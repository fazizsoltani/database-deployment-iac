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

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnet IDs to deploy EKS cluster"
  type        = list(string)
}

# To follow security best practices enable all type of logging
variable "cluster_enabled_log_types" {
  description = "List of EKS cluster control plane logs to enable."
  type        = list(string)
  # default     = ["api", "authenticator", "audit", "scheduler", "controllerManager"]
  default = []
}