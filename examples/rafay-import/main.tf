locals {
  # Extract kubeconfig from JSON if present, otherwise use raw kubeconfig
  extracted_kubeconfig = try(
    jsondecode(var.kubeconfig_json)["value"],
    var.kubeconfig
  )
}

# Debugging Outputs
output "debug_kubeconfig_raw" {
  value = var.kubeconfig
}

output "debug_kubeconfig_json" {
  value = var.kubeconfig_json
}

output "debug_extracted_kubeconfig" {
  value = local.extracted_kubeconfig
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

# Install dependencies (AWS CLI, kubectl, jq)
resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      # Install curl if not installed
      if ! command -v curl &> /dev/null; then
        echo "Installing curl..."
        apt-get update && apt-get install -y curl
      fi

      # Install unzip if not installed
      if ! command -v unzip &> /dev/null; then
        echo "Installing unzip..."
        apt-get update && apt-get install -y unzip
      fi

      # Install AWS CLI if not installed
      if ! command -v aws &> /dev/null; then
        echo "Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
      fi

      # Install kubectl if not present
      if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        mv ./kubectl /usr/local/bin/
      fi

      # Install jq if not present
      if ! command -v jq &> /dev/null; then
        echo "Installing jq..."
        curl -LO "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
        chmod +x jq
        mv jq /usr/local/bin/
      fi

      # Verify installations
      aws --version
      kubectl version --client
      jq --version
    EOT
  }
}

# Extract and apply the kubeconfig
resource "null_resource" "apply_bootstrap_yaml" {
  depends_on = [
    rafay_import_cluster.import_cluster,
    null_resource.install_dependencies
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      # Write the kubeconfig to a file
      echo "${local.extracted_kubeconfig}" > kubeconfig.yaml
      
      # Apply the bootstrap YAML using kubectl
      kubectl --kubeconfig=kubeconfig.yaml apply -f - <<EOF
${rafay_import_cluster.import_cluster.bootstrap_data}
EOF
    EOT
  }
}
