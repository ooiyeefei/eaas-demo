variable "region" {
  type        = string
  default     = "us-west-2"
}

variable "cluster_version" {
  type        = string
  default     = "1.31"
}

variable "cluster_name" {
  type        = string
  default     = "my-cluster"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = true
}

variable "cluster_compute_enabled" {
  type        = bool
  default     = true
}
