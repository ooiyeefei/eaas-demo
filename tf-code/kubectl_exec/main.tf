# Resource to create a custom directory for kubeconfig
resource "null_resource" "create_kubeconfig_directory" {
  provisioner "local-exec" {
    command = <<EOT
      if [ ! -d "${path.module}/kubeconfig_dir" ]; then
        mkdir -p "${path.module}/kubeconfig_dir"
        echo "Created directory ${path.module}/kubeconfig_dir"
      else
        echo "Directory ${path.module}/kubeconfig_dir already exists"
      fi
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# Resource to force a re-download trigger
resource "null_resource" "force_download" {
  triggers = {
    always_run = timestamp()
  }
}

# Resource to download the kubeconfig
resource "rafay_download_kubeconfig" "tfkubeconfig" {
  depends_on = [null_resource.create_kubeconfig_directory, null_resource.force_download]

  cluster            = var.cluster_name
  output_folder_path = "${path.module}/kubeconfig_dir"
  filename           = "kubeconfig"
}

# Resource to install kubectl
resource "null_resource" "install_kubectl" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Downloading kubectl..."
      mkdir -p "$HOME/bin"
      wget -q "https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl" -O "$HOME/bin/kubectl"
      chmod +x "$HOME/bin/kubectl"
      echo "kubectl installed successfully."
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# Resource to execute kubectl commands
resource "null_resource" "kubectl_cmds" {
  depends_on = [
    rafay_download_kubeconfig.tfkubeconfig,
    null_resource.install_kubectl
  ]

  provisioner "local-exec" {
    command = <<EOT
      export PATH="$HOME/bin:$PATH"
      export KUBECONFIG=${path.module}/kubeconfig_dir/kubeconfig
      kubectl get pods -A > "${path.module}/kubectl_output.txt"
    EOT
  }

  triggers = {
    command_trigger = timestamp()
    cluster_name    = var.cluster_name
  }
}

# Data source to read kubectl output
data "local_file" "kubectl_output" {
  depends_on = [null_resource.kubectl_cmds]
  filename   = "${path.module}/kubectl_output.txt"
}
