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

# Download kubectl binary
resource "null_resource" "download_kubectl" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      wget "https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl" -O ./kubectl
      chmod +x ./kubectl
    EOT
  }
}

# Echo kubeconfig to stdout
resource "null_resource" "echo_kubeconfig" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      echo "### KUBECONFIG CONTENT ###"
      echo "${var.kubeconfig}"
      echo "###########################"
    EOT
  }
}

# Apply the bootstrap YAML using kubectl
resource "null_resource" "apply_bootstrap_yaml" {
  depends_on = [
    rafay_import_cluster.import_cluster,
    null_resource.download_kubectl,
    null_resource.echo_kubeconfig
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      # Save kubeconfig to a file
      echo "${var.kubeconfig}" > kubeconfig.yaml

      # Apply the bootstrap YAML using kubectl
      ./kubectl --kubeconfig=kubeconfig.yaml apply -f - <<EOF
${rafay_import_cluster.import_cluster.bootstrap_data}
EOF
    EOT
  }
}
