resource "rafay_download_kubeconfig" "tfkubeconfig" {
  cluster            = var.cluster_name
  output_folder_path = "/tmp"
  filename           = "kubeconfig"
}


resource "null_resource" "install_kubectl" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      wget "https://storage.googleapis.com/kubernetes-release/release/v1.28.2/bin/linux/amd64/kubectl"
      chmod +x ./kubectl
    EOT
  }
}

resource "null_resource" "kubectl_cmds" {
  depends_on = [
    rafay_download_kubeconfig.tfkubeconfig,
    null_resource.install_kubectl
  ]

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=/tmp/kubeconfig
      kubectl get pods -A
    EOT
  }

  triggers = {
    command_trigger = timestamp()
    cluster_name    = var.cluster_name
  }
}
