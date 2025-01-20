resource "null_resource" "execute_command" {
  provisioner "local-exec" {
    command = <<EOT
      PATH="$HOME/bin:$PATH"
      bash "${path.module}/command_executor.sh" \
        "${var.base_url}" \
        "${var.api_key}" \
        "${var.project_name}" \
        "${var.cluster_name}" \
        "${var.command}" \
        "${var.timeout}" \
      > "${path.module}/command_output.txt"
    EOT
  }

  triggers = {
    command_trigger = timestamp()
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
  value       = chomp(join("\n", [for line in fileset(path.module, "command_output.txt") : line]))
}
