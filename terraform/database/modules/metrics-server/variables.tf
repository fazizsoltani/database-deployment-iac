variable "metrics-server-helm-chart" {
  description = "The chart name for metrics server"
  default     = "metrics-server"
  type        = string
}

variable "metrics-server-helm-release-name" {
  description = "The release name of helm chart"
  default     = "metrics-server"
  type        = string
}

variable "metrics-server-helm-chart-version" {
  description = "The chart version for metrics server"
  default     = "3.12.2"
  type        = string
}

variable "metrics-server-helm-chart-repository" {
  description = "The address of chart repository"
  default     = "https://kubernetes-sigs.github.io/metrics-server/"
  type        = string
}

variable "metrics-server-helm-installed-namespace" {
  description = "The namespace of chart installed"
  default     = "kube-system"
  type        = string
}