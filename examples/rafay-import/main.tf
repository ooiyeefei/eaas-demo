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
    command     = <<EOT
      # Check that wget and unzip exist. If not, fail.
      if ! command -v wget &> /dev/null; then
        echo "wget not found. Please install wget manually and rerun."
        exit 1
      fi

      if ! command -v unzip &> /dev/null; then
        echo "unzip not found. Please install unzip manually and rerun."
        exit 1
      fi

      # Install AWS CLI locally if not present
      if ! command -v ./aws &> /dev/null && ! command -v aws &> /dev/null; then
        echo "Installing AWS CLI locally..."
        wget -q "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O awscliv2.zip
        unzip -q awscliv2.zip
        # Install AWS CLI into the current directory
        ./aws/install --install-dir . --bin-dir . || { echo "Failed to install AWS CLI locally."; exit 1; }
        rm -rf aws awscliv2.zip
      else
        echo "AWS CLI is already installed or available."
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

      # Set PATH to current directory so we can run ./aws, ./kubectl, ./jq directly
      export PATH=$PATH:$(pwd)

      # Verify installations
      echo "Verifying installations..."
      if ! ./aws --version &> /dev/null; then echo "AWS CLI verification failed"; exit 1; fi
      if ! ./kubectl version --client &> /dev/null; then echo "kubectl verification failed"; exit 1; fi
      if ! ./jq --version &> /dev/null; then echo "jq verification failed"; exit 1; fi

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
    command     = <<EOT
      echo "Applying bootstrap YAML using local kubectl..."
      PATH=$PATH:$(pwd) ./kubectl --kubeconfig=kubeconfig.yaml apply -f - <<EOF
${rafay_import_cluster.import_cluster.bootstrap_data}
EOF
    EOT
  }
}
