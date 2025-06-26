terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
  }
}

provider "aws" {
    region = var.region
}
data "aws_eks_cluster" "cluster" {
    name = var.cluster_name
}
data "aws_eks_cluster_auth" "ephemeral" {
  name = var.cluster_name
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

provider kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.ephemeral.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.ephemeral.token
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
  version          = "1.1.3"

  lifecycle {
    ignore_changes = [
      # Avoid reapplying helm release
      values,
      version
    ]
  }
}

resource "null_resource" "delete-webhook" {
  triggers = {
    cluster_name = var.cluster_name
    project_name = var.project_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "chmod +x ./delete-webhook.sh && ./delete-webhook.sh"
    environment = {
      CLUSTER_NAME = "${self.triggers.cluster_name}"
      PROJECT      = "${self.triggers.project_name}"
    }
  }

  depends_on = [helm_release.v2-infra]
}
