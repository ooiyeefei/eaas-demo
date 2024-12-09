variable "kubeconfig" {
  type        = string
  description = "Raw kubeconfig content as a string"
  default     = ""
}

variable "kubeconfig_json" {
  type        = any
  description = "Optional JSON kubeconfig object containing sensitive, type, and value"
  default     = {}
}

variable "region" {
  type        = string
  default = "us-west-2"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "blueprint" {
  type        = string
  description = "Blueprint to use"
}

variable "blueprint_version" {
  type        = string
  description = "Version of the blueprint"
}

variable "kubernetes_provider" {
  type        = string
  description = "Kubernetes provider (e.g., EKS)"
}

variable "provision_environment" {
  type        = string
  description = "Environment for provisioning"
}
