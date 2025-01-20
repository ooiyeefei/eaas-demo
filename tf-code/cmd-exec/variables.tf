variable "endpoint" {
  description = "The Rafay API endpoint."
  type        = string
}

variable "api_key" {
  description = "The API key for authentication with Rafay."
  type        = string
}

variable "project_id" {
  description = "The ID of the Rafay project."
  type        = string
}

variable "cluster_id" {
  description = "The ID of the Rafay cluster."
  type        = string
}

variable "command" {
  description = "The command to execute."
  type        = string
}

variable "timeout" {
  description = "Timeout for the command execution."
  type        = number
  default     = 120
}
