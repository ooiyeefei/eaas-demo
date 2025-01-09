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

variable "tags" {
  type        = map(string)
  default = {
    Environment = "development"
    Owner       = "team"
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}
