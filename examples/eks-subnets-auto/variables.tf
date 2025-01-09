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

variable "vpc_id" {
  description = "ID of the VPC where EKS cluster will be deployed. Leave empty to auto-create."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs where EKS cluster nodes will be deployed. Leave empty to auto-create."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "cluster_iam_role_arn" {
  description = "IAM Role ARN for the EKS cluster. Leave empty to auto-create."
  type        = string
  default     = ""
}

variable "node_iam_role_arn" {
  description = "IAM Role ARN for the EKS node role. Leave empty to auto-create."
  type        = string
  default     = ""
}