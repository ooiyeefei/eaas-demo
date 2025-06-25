terraform {
  required_providers {
    rafay = {
      version = "= 1.1.47"
      source  = "RafaySystems/rafay"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
