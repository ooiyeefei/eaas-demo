resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Installing curl and jq for the current user..."
      mkdir -p "$HOME/bin"
      export PATH="$HOME/bin:$PATH"

      # Install curl
      if ! command -v curl > /dev/null; then
        echo "Installing curl..."
        wget -qO- https://curl.se/download/curl-7.87.0.tar.gz | tar -xz
        cd curl-7.87.0
        ./configure --prefix=$HOME
        make && make install
        cd ..
        rm -rf curl-7.87.0
        echo "curl installed successfully."
      else
        echo "curl is already installed."
      fi

      # Install jq
      if ! command -v jq > /dev/null; then
        echo "Installing jq..."
        wget -qO "$HOME/bin/jq" https://github.com/stedolan/jq/releases/latest/download/jq-linux64
        chmod +x "$HOME/bin/jq"
        echo "jq installed successfully."
      else
        echo "jq is already installed."
      fi

      # Confirm installation
      curl --version && jq --version
    EOT
  }

  triggers = {
    install_trigger = timestamp()
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
