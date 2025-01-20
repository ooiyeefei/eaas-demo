variable "base_url" {
  description = "Base URL for the API"
  type        = string
}

variable "api_key" {
  description = "API Key for authentication"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "command" {
  description = "Command to execute"
  type        = string
}

variable "timeout" {
  description = "The timeout for command execution (in seconds)."
  type        = number
  default     = 120
}
