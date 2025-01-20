module "rafay_cmdexec" {
  source      = "./modules/rafay_cmdexec"
  api_key     = var.api_key
  project_id  = var.project_id
  cluster_id  = var.cluster_id
  command     = var.command
  timeout     = var.timeout
  endpoint    = var.endpoint
}

