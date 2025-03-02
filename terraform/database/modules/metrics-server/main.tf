resource "helm_release" "metrics-server" {
  name       = var.metrics-server-helm-release-name
  repository = var.metrics-server-helm-chart-repository
  chart      = var.metrics-server-helm-chart
  version    = var.metrics-server-helm-chart-version
  namespace  = var.metrics-server-helm-installed-namespace

  set {
    name  = "containerPort"
    value = "4443"
  }
}