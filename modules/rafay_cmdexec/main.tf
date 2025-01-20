# Fetch Project ID
resource "null_resource" "fetch_project_id" {
  provisioner "local-exec" {
    command = <<EOT
      curl -s -X GET "https://${var.endpoint}/auth/v1/projects/?limit=48&offset=0&order=ASC&orderby=name&q=" \
        -H "accept: application/json" \
        -H "X-RAFAY-API-KEYID: ${var.api_key}" \
        | jq -r --arg name "${var.project_name}" '.results[] | select(.name == $name) | .id' > ${path.module}/project_id.txt 2>/dev/null
    EOT
  }

  triggers = {
    api_key       = var.api_key
    endpoint      = var.endpoint
    project_name  = var.project_name
  }
}

# Fetch Cluster ID
resource "null_resource" "fetch_cluster_id" {
  depends_on = [null_resource.fetch_project_id]

  provisioner "local-exec" {
    command = <<EOT
      PROJECT_ID=$(cat ${path.module}/project_id.txt) && \
      curl -s -X GET "https://${var.endpoint}/edge/v1/projects/$PROJECT_ID/edges/?limit=25&offset=0&q=" \
        -H "accept: application/json" \
        -H "X-RAFAY-API-KEYID: ${var.api_key}" \
        | jq -r --arg name "${var.cluster_name}" '.results[] | select(.name == $name) | .id' > ${path.module}/cluster_id.txt 2>/dev/null
    EOT
  }

  triggers = {
    api_key       = var.api_key
    endpoint      = var.endpoint
    cluster_name  = var.cluster_name
  }
}

# Execute Command
resource "null_resource" "execute_command" {
  depends_on = [null_resource.fetch_cluster_id]

  provisioner "local-exec" {
    command = <<EOT
      PROJECT_ID=$(cat ${path.module}/project_id.txt) && \
      CLUSTER_ID=$(cat ${path.module}/cluster_id.txt) && \
      curl -s -X POST \
        "https://${var.endpoint}/cmdexec/v1/projects/$PROJECT_ID/edges/$CLUSTER_ID/execute/" \
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
    api_key       = var.api_key
    endpoint      = var.endpoint
    command       = var.command
  }
}

# Fetch Command Result
resource "null_resource" "fetch_result" {
  depends_on = [null_resource.execute_command]

  provisioner "local-exec" {
    command = <<EOT
      EXEC_ID=$(jq -r '.Id' ${path.module}/post_response.json) && \
      curl -s -X GET \
        "https://${var.endpoint}/cmdexec/v1/projects/$(cat ${path.module}/project_id.txt)/edges/$(cat ${path.module}/cluster_id.txt)/execution/$EXEC_ID/" \
        -H "accept: application/json" \
        -H "X-RAFAY-API-KEYID: ${var.api_key}" > ${path.module}/get_response.json && \
      echo -e "\\033[0;32m$(cat ${path.module}/get_response.json)\\033[0m"
    EOT
  }

  triggers = {
    execution_trigger = timestamp()
  }
}

output "execution_result" {
  description = "The result of the command execution."
  value       = file("${path.module}/get_response.json")
}
