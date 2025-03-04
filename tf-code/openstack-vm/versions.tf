terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "3.0.0"
    }
  }
}

provider "openstack" {
  # Configuration options
  # Set the OS_CLIENT_CONFIG_FILE environment variable to
  # /etc/kolla/clouds.yaml
  # https://search.opentofu.org/provider/terraform-provider-openstack/openstack/latest#configuration-reference
  cloud = "openstack"
}
