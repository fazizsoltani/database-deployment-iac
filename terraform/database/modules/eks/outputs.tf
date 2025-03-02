output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "The EKS ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "The API server endpoint for the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "The certificate authority data for the cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_identity_oidc_issuer" {
  description = "The OIDC issuer URL for the EKS cluster."
  value       = module.eks.cluster_oidc_issuer_url
}