module "rafay_exec" {
  source        = "../../modules/rafay_cmdexec"
  base_url      = var.base_url
  api_key       = var.api_key
  project_name  = var.project_name
  cluster_name  = var.cluster_name
  command       = var.command
  timeout       = var.timeout
}


