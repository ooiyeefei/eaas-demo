resource "null_resource" "execute_command" {
  provisioner "local-exec" {
    command = <<EOT
      bash ${path.module}/command_executor.sh \
        "${var.base_url}" \
        "${var.api_key}" \
        "${var.project_name}" \
        "${var.cluster_name}" \
        "${var.command}"
    EOT
  }

  triggers = {
    base_url     = var.base_url
    api_key      = var.api_key
    project_name = var.project_name
    cluster_name = var.cluster_name
    command      = var.command
  }
}

output "command_result" {
  description = "Command result from shell script execution"
  value       = "See Terraform apply logs for output."
}
