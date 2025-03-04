resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${var.resource_prefix}-keypair"
  public_key = var.ssh_public_key
}

resource "openstack_compute_instance_v2" "worker" {
  count           = var.worker_count
  name            = "${var.resource_prefix}-worker-${count.index}"
  image_name      = var.worker_image_name
  flavor_name     = var.worker_flavor_name
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = ["default"]

  network {
    name = var.worker_network
  }

  user_data    = var.worker_user_data
  config_drive = true

  # wait for instance to become available
  provisioner "remote-exec" {
    script = "./check_ready.sh"
    connection {
      type        = "ssh"
      user        = var.ssh_username
      host        = self.access_ip_v4
      private_key = file(var.ssh_private_key_path)
      timeout     = "10m"
    }
  }

  # run before destroying the instance. Best effort hack needed for
  # machines without IPMI.
  provisioner "remote-exec" {
    when   = destroy
    script = "./set_pxe_boot.sh"
    connection {
      type        = "ssh"
      user        = self.metadata.ssh_username
      host        = self.access_ip_v4
      private_key = file(self.metadata.ssh_private_key_path)
      timeout     = "10m"
    }
  }

  metadata = {
    ssh_username         = var.ssh_username
    ssh_private_key_path = var.ssh_private_key_path
  }
}

resource "openstack_compute_instance_v2" "controlplane" {
  count           = var.controlplane_count
  name            = "${var.resource_prefix}-controlplane-${count.index}"
  image_name      = var.controlplane_image_name
  flavor_name     = var.controlplane_flavor_name
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = ["default"]

  network {
    name = var.controlplane_network
  }

  user_data    = var.controlplane_user_data
  config_drive = true

  # wait for instance to become available
  provisioner "remote-exec" {
    script = "./check_ready.sh"
    connection {
      type        = "ssh"
      user        = var.ssh_username
      host        = self.access_ip_v4
      private_key = file(var.ssh_private_key_path)
      timeout     = "10m"
    }
  }

  # run before destroying the instance. Best effort hack needed for
  # machines without IPMI.
  provisioner "remote-exec" {
    when   = destroy
    script = "./set_pxe_boot.sh"
    connection {
      type        = "ssh"
      user        = self.metadata.ssh_username
      host        = self.access_ip_v4
      private_key = file(self.metadata.ssh_private_key_path)
      timeout     = "10m"
    }
  }

  metadata = {
    ssh_username         = var.ssh_username
    ssh_private_key_path = var.ssh_private_key_path
  }
}
