terraform {
  required_version = ">= 1.2.0"

  backend "s3" {
    bucket       = "terraform-backend-s3-vertica"
    key          = "tf/vertica/terraform.tfstate"
    region       = "us-east-1"
    profile      = "default"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.89.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
  }
}