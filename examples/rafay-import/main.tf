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

# Install dependencies (AWS CLI, kubectl, jq, curl)
resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      # Function to check and install tools
      install_tool() {
        local tool=$1
        local install_cmd=$2

        if ! command -v "$tool" &> /dev/null; then
          echo "Installing $tool..."
          eval "$install_cmd"
          if ! command -v "$tool" &> /dev/null; then
            echo "Failed to install $tool. Ensure the environment supports the installation command."
            exit 1
          fi
        else
          echo "$tool is already installed."
        fi
      }

      # Install curl if not installed
      install_tool "curl" "apt-get update && apt-get install -y curl"

      # Install unzip if not installed
      install_tool "unzip" "apt-get install -y unzip"

      # Install AWS CLI if not installed
      install_tool "aws" "curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip"

      # Install kubectl if not installed
      install_tool "kubectl" "curl -LO 'https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl' && chmod +x kubectl && mv kubectl /usr/local/bin/"

      # Install jq if not installed
      install_tool "jq" "curl -LO 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64' && chmod +x jq && mv jq /usr/local/bin/"

      # Verify installations
      echo "Verifying installations..."
      aws --version || { echo "AWS CLI installation failed"; exit 1; }
      kubectl version --client || { echo "kubectl installation failed"; exit 1; }
      jq --version || { echo "jq installation failed"; exit 1; }
    EOT
  }
}

# Write the kubeconfig to a file
resource "local_sensitive_file" "kubeconfig" {
  content  = local.extracted_kubeconfig
  filename = "kubeconfig.yaml"
}

# Apply the bootstrap YAML
resource "null_resource" "apply_bootstrap_yaml" {
  depends_on = [
    rafay_import_cluster.import_cluster,
    local_sensitive_file.kubeconfig,
    null_resource.install_dependencies
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      echo "Applying bootstrap YAML using kubectl..."
      kubectl --kubeconfig=kubeconfig.yaml apply -f - <<EOF
${rafay_import_cluster.import_cluster.bootstrap_data}
EOF
    EOT
  }
}
