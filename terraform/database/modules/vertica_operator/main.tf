resource "helm_release" "vertica" {
  name             = var.vertica_release_name
  repository       = var.vertica_repository
  chart            = var.vertica_chart_name
  version          = var.vertica_chart_version
  namespace        = var.vertica_namespace
  create_namespace = var.create_namespace

  set {
    name  = "logging.level"
    value = var.vertica_logging_level
  }
}