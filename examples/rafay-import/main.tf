locals {
  extracted_kubeconfig = try(
    jsondecode(var.kubeconfig_json)["value"],
    var.kubeconfig
  )
}

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

resource "null_resource" "setup_and_apply" {
  depends_on = [rafay_import_cluster.import_cluster]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      # Ensure wget and unzip are present
      if ! command -v wget &> /dev/null; then
        echo "wget not found. Please install wget manually and rerun."
        exit 1
      fi

      if ! command -v unzip &> /dev/null; then
        echo "unzip not found. Please install unzip manually and rerun."
        exit 1
      fi

      # Install kubectl locally if not present
      if [ ! -f "./kubectl" ]; then
        echo "Installing kubectl locally..."
        wget -q "https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl" -O kubectl
        chmod +x kubectl || { echo "Failed to chmod kubectl"; exit 1; }
      else
        echo "kubectl is already present locally."
      fi

      # Install jq locally if not present
      if [ ! -f "./jq" ]; then
        echo "Installing jq locally..."
        wget -q "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -O jq
        chmod +x jq || { echo "Failed to chmod jq"; exit 1; }
      else
        echo "jq is already present locally."
      fi

      # Install aws-iam-authenticator locally if not present
      if [ ! -f "./aws-iam-authenticator" ]; then
        echo "Installing aws-iam-authenticator locally..."
        wget -q "https://amazon-eks.s3.us-west-2.amazonaws.com/1.27.0/2023-07-05/bin/linux/amd64/aws-iam-authenticator" -O aws-iam-authenticator
        chmod +x aws-iam-authenticator || { echo "Failed to chmod aws-iam-authenticator"; exit 1; }
      else
        echo "aws-iam-authenticator is already present locally."
      fi

      # Write kubeconfig to file
      echo "${local.extracted_kubeconfig}" > kubeconfig.yaml

      # Update kubeconfig to use aws-iam-authenticator
      sed -i 's|command: aws|command: ./aws-iam-authenticator|g' kubeconfig.yaml
      sed -i 's|get-token|token -i|g' kubeconfig.yaml

      # Verify installations
      echo "Verifying installations..."
      ./kubectl version --client > /dev/null || { echo "kubectl verification failed"; exit 1; }
      ./jq --version > /dev/null || { echo "jq verification failed"; exit 1; }
      ./aws-iam-authenticator help > /dev/null || { echo "aws-iam-authenticator verification failed"; exit 1; }

      echo "All tools installed and verified locally."

      # Apply the bootstrap YAML using local kubectl
      echo "Applying bootstrap YAML using local kubectl..."
      ./kubectl --kubeconfig=kubeconfig.yaml apply -f - <<EOF
${rafay_import_cluster.import_cluster.bootstrap_data}
EOF
    EOT
  }
}
