resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Installing curl and jq on Alpine Linux using wget..."
      apk add --no-cache wget || { echo "Error: Failed to install wget."; exit 1; }
      apk add --no-cache curl jq || { echo "Error: Failed to install curl and jq."; exit 1; }
    EOT
  }

  triggers = {
    install_trigger = timestamp() # Ensures the resource runs every time `terraform apply` is invoked
  }
}

resource "null_resource" "execute_command" {
  provisioner "local-exec" {
    command = <<EOT
      bash "${path.module}/command_executor.sh" \
        "${var.base_url}" \
        "${var.api_key}" \
        "${var.project_name}" \
        "${var.cluster_name}" \
        "${var.command}" \
        "${var.timeout}"
    EOT
  }

  triggers = {
    command_trigger = timestamp() # Ensures the resource runs every time `terraform apply` is invoked
    base_url        = var.base_url
    api_key         = var.api_key
    project_name    = var.project_name
    cluster_name    = var.cluster_name
    command         = var.command
    timeout         = var.timeout
  }
}

output "command_result" {
  description = "The output of the executed command."
  value       = "See Terraform apply logs for output."
}
