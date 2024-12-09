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
    command = <<EOT
      # Ensure wget is available
      if ! command -v wget &> /dev/null; then
        echo "wget not found. Please install wget manually and rerun."
        exit 1
      fi

      # Ensure unzip is available
      if ! command -v unzip &> /dev/null; then
        echo "unzip not found. Please install unzip manually and rerun."
        exit 1
      fi

      # Install kubectl if not present
      if [ ! -f "./kubectl" ]; then
        echo "Installing kubectl locally..."
        wget -q "https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl" -O kubectl
        chmod +x kubectl || { echo "Failed to chmod kubectl"; exit 1; }
      else
        echo "kubectl is already present locally."
      fi

      # Install jq if not present
      if [ ! -f "./jq" ]; then
        echo "Installing jq locally..."
        wget -q "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -O jq
        chmod +x jq || { echo "Failed to chmod jq"; exit 1; }
      else
        echo "jq is already present locally."
      fi

      # Install aws-iam-authenticator if not present (for EKS token retrieval)
      if [ ! -f "./aws-iam-authenticator" ]; then
        echo "Installing aws-iam-authenticator locally..."
        wget -q "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/latest/download/aws-iam-authenticator_$(uname -s)_amd64" -O aws-iam-authenticator
        chmod +x aws-iam-authenticator || { echo "Failed to chmod aws-iam-authenticator"; exit 1; }
      else
        echo "aws-iam-authenticator is already present locally."
      fi

      # Verify installations
      echo "Verifying installations..."
      ./kubectl version --client > /dev/null || { echo "kubectl verification failed"; exit 1; }
      ./jq --version > /dev/null || { echo "jq verification failed"; exit 1; }
      ./aws-iam-authenticator help > /dev/null || { echo "aws-iam-authenticator verification failed"; exit 1; }

      echo "All tools installed and verified locally."
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
    command = <<EOT
      echo "Applying bootstrap YAML using local kubectl..."
      # Ensure that your kubeconfig references aws-iam-authenticator like so:
      # users:
      # - name: your-user
      #   user:
      #     exec:
      #       apiVersion: client.authentication.k8s.io/v1beta1
      #       command: ./aws-iam-authenticator
      ./kubectl --kubeconfig=kubeconfig.yaml apply -f - <<EOF
${rafay_import_cluster.import_cluster.bootstrap_data}
EOF
    EOT
  }
}
