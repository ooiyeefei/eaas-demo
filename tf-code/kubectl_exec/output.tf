output "kubectl_output" {
  value = data.local_file.kubectl_output.content
}
