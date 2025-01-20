output "execution_result" {
  description = "The result of the command execution."
  value       = <<EOT
$(cat ${path.module}/get_response.json)
EOT
}

resource "null_resource" "execute_command" {
  provisioner "local-exec" {
    command = <<EOT
      curl -s -X POST \
        "https://${var.endpoint}/cmdexec/v1/projects/${var.project_id}/edges/${var.cluster_id}/execute/" \
        -H "accept: application/json" \
        -H "X-RAFAY-API-KEYID: ${var.api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "target_type": "cluster",
          "command": "${var.command}",
          "timeout": ${var.timeout}
        }' > ${path.module}/post_response.json
    EOT
  }

  triggers = {
    project_id = var.project_id
    cluster_id = var.cluster_id
    api_key    = var.api_key
    command    = var.command
    endpoint   = var.endpoint
  }
}

resource "null_resource" "fetch_result" {
  depends_on = [null_resource.execute_command]

  provisioner "local-exec" {
    command = <<EOT
      EXEC_ID=$(jq -r '.Id' ${path.module}/post_response.json) && \
      curl -s -X GET \
        "https://${var.endpoint}/cmdexec/v1/projects/${var.project_id}/edges/${var.cluster_id}/execution/$EXEC_ID/" \
        -H "accept: application/json" \
        -H "X-RAFAY-API-KEYID: ${var.api_key}" > ${path.module}/get_response.json && \
      echo -e "\\033[0;32m$(cat ${path.module}/get_response.json)\\033[0m"
    EOT
  }

  triggers = {
    execution_trigger = timestamp()
  }
}
