module "rafay_cmdexec" {
  source        = "../../modules/rafay_cmdexec"
  api_key       = var.api_key
  project_name  = var.project_name
  cluster_name  = var.cluster_name
  command       = var.command
  timeout       = var.timeout
  endpoint      = var.endpoint
}
