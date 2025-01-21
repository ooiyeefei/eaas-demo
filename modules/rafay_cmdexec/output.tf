output "command_result" {
  value = jsondecode(data.local_file.command_output.content)["command_output"]
}
