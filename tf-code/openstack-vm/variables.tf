variable "resource_prefix" {
  description = "Prefix to apply to all resource names"
  type        = string
}

variable "worker_flavor_name" {
  description = "The name of the OpenStack flavor to use for worker instances"
  type        = string
}

variable "worker_image_name" {
  description = "The name of the OpenStack image to use for worker instances"
  type        = string
}

variable "worker_user_data" {
  type        = string
  description = <<EOS
User data to pass to the worker instances. It can be a script or cloud-init config.
bzip2 package is required for Rafay MKS.
Ref: https://docs.openstack.org/nova/2024.2/user/metadata.html#user-data
EOS
  default     = "#cloud-config\npackages:\n- bzip2\n"
}

variable "worker_network" {
  description = "The name of the OpenStack network to attach the worker instances"
  type        = string
}

variable "controlplane_flavor_name" {
  description = "The name of the OpenStack flavor to use for controlplane instances"
  type        = string
}

variable "controlplane_image_name" {
  description = "The name of the OpenStack image to use for controlplane instances"
  type        = string
}

variable "controlplane_user_data" {
  type        = string
  description = <<EOS
User data to pass to the controlplane instances. It can be a script or cloud-init config.
bzip2 package is required for Rafay MKS.
Ref: https://docs.openstack.org/nova/2024.2/user/metadata.html#user-data
EOS
  default     = "#cloud-config\npackages:\n- bzip2\n"
}

variable "controlplane_network" {
  description = "The name of the OpenStack network to attach the controlplane instances"
  type        = string
}

variable "ssh_public_key" {
  description = "The public SSH key to use for accessing the instances"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key to use for accessing the instances"
  type        = string
}

variable "ssh_username" {
  description = "Username to use for accessing the instances"
  type        = string
  default     = "ubuntu"
}

variable "worker_count" {
  description = "Number of worker instances to create on OpenStack"
  type        = number
  default     = 1
}

variable "controlplane_count" {
  description = "Number of controlplane instances to create on OpenStack"
  type        = number
  default     = 1
}
