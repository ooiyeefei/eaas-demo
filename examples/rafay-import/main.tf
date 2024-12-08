locals {
  # Extract kubeconfig from JSON if present, otherwise use raw kubeconfig
  extracted_kubeconfig = try(
    jsondecode(var.kubeconfig_json)["value"],
    var.kubeconfig
  )
}

# Debug outputs
output "debug_kubeconfig_raw" {
  value = var.kubeconfig
}

output "debug_kubeconfig_json" {
  value = var.kubeconfig_json
}

output "debug_extracted_kubeconfig" {
  value = local.extracted_kubeconfig
}

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

resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      # Check for essential tools: wget, unzip
      if ! command -v wget &> /dev/null; then
        echo "wget not found. Please install wget manually and rerun."
        exit 1
      fi

      if ! command -v unzip &> /dev/null; then
        echo "unzip not found. Please install unzip manually and rerun."
        exit 1
      fi

      # Check and install AWS CLI if not present
      if ! command -v aws &> /dev/null; then
        echo "Installing AWS CLI..."
        wget -q "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install || { echo "Failed to install AWS CLI."; exit 1; }
        rm -rf aws awscliv2.zip
      else
        echo "aws is already installed."
      fi

      # Check and install kubectl if not present
      if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        wget -q "https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl" -O kubectl
        chmod +x kubectl
        mv kubectl /usr/local/bin/ || { echo "Failed to move kubectl to /usr/local/bin"; exit 1; }
      else
        echo "kubectl is already installed."
      fi

      # Check and install jq if not present
      if ! command -v jq &> /dev/null; then
        echo "Installing jq..."
        wget -q "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -O jq
        chmod +x jq
        mv jq /usr/local/bin/ || { echo "Failed to move jq to /usr/local/bin"; exit 1; }
      else
        echo "jq is already installed."
      fi

      # Verify installations
      echo "Verifying installations..."
      aws --version || { echo "AWS CLI verification failed"; exit 1; }
      kubectl version --client || { echo "kubectl verification failed"; exit 1; }
      jq --version || { echo "jq verification failed"; exit 1; }

      echo "All tools installed and verified."
    EOT
  }
}

resource "local_sensitive_file" "kubeconfig" {
  content  = local.extracted_kubeconfig
  filename = "kubeconfig.yaml"
}

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
