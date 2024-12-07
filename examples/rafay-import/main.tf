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
      wget -q "https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl" -O ./kubectl
      chmod +x ./kubectl
    EOT
  }
}

# Install jq binary if not present
resource "null_resource" "install_jq" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      if ! command -v jq &> /dev/null; then
        echo "jq not found. Installing jq..."
        wget -q "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -O jq
        chmod +x jq
        sudo mv jq /usr/local/bin/ || (chmod +x jq && mv jq ~/jq && export PATH=$PATH:~)
      fi
    EOT
  }
}

# Extract and apply the kubeconfig
resource "null_resource" "apply_bootstrap_yaml" {
  depends_on = [
    rafay_import_cluster.import_cluster,
    null_resource.download_kubectl,
    null_resource.install_jq
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      # Check if kubeconfig is a JSON object or plain string
      if echo '${var.kubeconfig}' | jq empty 2>/dev/null; then
        echo '${var.kubeconfig}' | jq -r '.value' > kubeconfig.yaml
      else
        echo "${var.kubeconfig}" > kubeconfig.yaml
      fi

      # Debugging: Print the kubeconfig file content
      echo "Generated kubeconfig:"
      cat kubeconfig.yaml

      # Apply the bootstrap YAML using kubectl
      ./kubectl --kubeconfig=kubeconfig.yaml apply -f - <<EOF
${rafay_import_cluster.import_cluster.bootstrap_data}
EOF
    EOT
  }
}

# Debug output
output "debug_kubeconfig" {
  value = var.kubeconfig
}
