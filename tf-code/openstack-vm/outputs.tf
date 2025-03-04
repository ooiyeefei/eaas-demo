# output "instance_ids" {
#   value = openstack_compute_instance_v2.instance.*.id
# }
#
# output "instance_names" {
#   value = openstack_compute_instance_v2.instance.*.name
# }
#
# output "instance_ips" {
#   value = openstack_compute_instance_v2.instance.*.access_ip_v4
# }

output "worker_instances" {
  value = {
    for instance in openstack_compute_instance_v2.worker :
    instance.name => {
      "arch" : "amd64",
      "hostname" : instance.name,
      "operating_system" : "Ubuntu22.04",
      "private_ip" : instance.access_ip_v4,
      "kubelet_extra_args" : {
        "max-pods" : "100",
        "cpu-manager-reconcile-period" : "30s"
      },
      "roles" : [
        "Worker"
      ],
      "ssh" : {
        "ip_address" : instance.access_ip_v4,
        "port" : "22",
        "private_key_path" : var.ssh_private_key_path,
        "username" : var.ssh_username
      }
    }
  }
}

output "controlplane_instances" {
  value = {
    for instance in openstack_compute_instance_v2.controlplane :
    instance.name => {
      "arch" : "amd64",
      "hostname" : instance.name,
      "operating_system" : "Ubuntu22.04",
      "private_ip" : instance.access_ip_v4,
      "kubelet_extra_args" : {
        "max-pods" : "100",
        "cpu-manager-reconcile-period" : "30s"
      },
      "roles" : [
        "ControlPlane"
      ],
      "ssh" : {
        "ip_address" : instance.access_ip_v4,
        "port" : "22",
        "private_key_path" : var.ssh_private_key_path,
        "username" : var.ssh_username
      }
    }
  }
}
