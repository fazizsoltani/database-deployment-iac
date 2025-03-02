variable "vertica_release_name" {
  description = "Vertica Helm release"
  type        = string
  default     = "vertica"
}

variable "vertica_repository" {
  description = "Vertica chart repository"
  type        = string
  default     = "https://vertica.github.io/charts"
}

variable "vertica_chart_name" {
  description = "Vertica helm chart name"
  type        = string
  default     = "verticadb-operator"
}

variable "vertica_chart_version" {
  description = "Vertica helm chart version"
  type        = string
  default     = "25.1.0-0"
}

variable "vertica_namespace" {
  description = "Vertica namespace to be deployed"
  type        = string
  default     = "vertica"
}

variable "vertica_logging_level" {
  description = "Vertica log level"
  type        = string
  default     = "info"
}

variable "create_namespace" {
  description = "Create helmchart namespace"
  type        = bool
  default     = true
}