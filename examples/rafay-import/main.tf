provider "kubectl" {
  kubeconfig = var.kubeconfig
}

# Rafay import cluster resource
resource "rafay_import_cluster" "import_cluster" {
  clustername           = var.cluster_name
  projectname           = var.project_name
  blueprint             = var.blueprint
  blueprint_version     = var.blueprint_version
  kubernetes_provider   = var.kubernetes_provider
  provision_environment = var.provision_environment
  lifecycle {
    ignore_changes = [
      bootstrap_path,
      values_path
    ]
  }
}

resource "kubectl_manifest" "apply_bootstrap_yaml" {
  yaml_body = rafay_import_cluster.import_cluster.bootstrap_data

  # Ensure the bootstrap YAML is applied only after the Rafay import is complete
  depends_on = [rafay_import_cluster.import_cluster]
}
