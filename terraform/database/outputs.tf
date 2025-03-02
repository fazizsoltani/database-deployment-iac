output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_igw_id" {
  description = "The Internet Gateway ID"
  value       = module.vpc.vpc_igw_id
}

output "vpc_main_route_table_id" {
  description = "The main route table ID"
  value       = module.vpc.vpc_main_route_table_id
}

output "vpc_private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.vpc_private_subnets
}

output "vpc_private_subnet_arns" {
  description = "List of private subnets ARNs"
  value       = module.vpc.vpc_private_subnet_arns
}

output "vpc_private_subnets_cidr_blocks" {
  description = "List of private subnets CIDR blocks"
  value       = module.vpc.vpc_private_subnets_cidr_blocks
}

output "vpc_private_route_table_ids" {
  description = "List of private route table IDs."
  value       = module.vpc.vpc_private_route_table_ids
}

output "vpc_public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.vpc_public_subnets
}

output "vpc_public_subnet_arns" {
  description = "List of public subnets ARNs"
  value       = module.vpc.vpc_public_subnet_arns
}

output "vpc_public_subnets_cidr_blocks" {
  description = "List of public subnets CIDR blocks"
  value       = module.vpc.vpc_public_subnets_cidr_blocks
}

output "vpc_public_route_table_ids" {
  description = "List of public route table IDs."
  value       = module.vpc.vpc_public_route_table_ids
}

output "eks_cluster_identity_oidc_issuer" {
  description = "The OIDC issuer URL for the EKS cluster."
  value       = module.eks.eks_cluster_identity_oidc_issuer
}

output "eks_cluster_endpoint" {
  description = "The API server endpoint for the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}