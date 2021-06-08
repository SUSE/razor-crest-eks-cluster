provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "kubewarden" {
  name             = "kubewarden"
  chart            = "kubewarden-controller"
  repository       = "https://charts.kubewarden.io"
  version          = "0.1.17"
  namespace        = "kubewarden"
  create_namespace = true
}

resource "helm_release" "kubewarden_policies" {
  depends_on = [helm_release.kubewarden]

  name             = "kubewarden-policies"
  chart            = "${path.module}/../helm/kubewarden-policies"
  namespace        = "kubewarden"
  create_namespace = true
}
