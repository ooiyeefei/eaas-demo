locals {
  kubeconfig_path = "${path.module}/kubeconfig.yaml"
}

resource "local_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = local.kubeconfig_path
}

resource "rafay_import_cluster" "import_cluster" {
  clustername           = var.cluster_name
  projectname           = var.project_name
  blueprint             = var.blueprint
  blueprint_version     = var.blueprint_version
  kubernetes_provider   = var.kubernetes_provider
  provision_environment = var.provision_environment
  values_path           = "values.yaml"

  lifecycle {
    ignore_changes = [
      bootstrap_path,
      values_path
    ]
  }
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

resource "null_resource" "install_aws_cli" {
  provisioner "local-exec" {
    command = <<EOT
      if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found. Installing..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install || { echo "Failed to install AWS CLI"; exit 1; }
        rm -rf awscliv2.zip aws
      else
        echo "AWS CLI is already installed."
      fi
    EOT
  }
}


resource "helm_release" "v2-infra" {
  depends_on = [rafay_import_cluster.import_cluster]

  name             = "v2-infra"
  namespace        = "rafay-system"
  create_namespace = true
  repository       = "https://rafaysystems.github.io/rafay-helm-charts/"
  chart            = "v2-infra"
  values           = [rafay_import_cluster.import_cluster.values_data]
  version          = "1.1.2"

  lifecycle {
    ignore_changes = [
      # Avoid reapplying helm release
      values,
      # Prevent reapplying if version changes
      version
    ]
  }
}
