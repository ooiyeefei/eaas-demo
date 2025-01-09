################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks.cluster_status
}

output "kubeconfig" {
  description = "Kubeconfig file content for the EKS cluster"
  value       = <<EOT
apiVersion: v1
clusters:
- cluster:
    server: "${module.eks.cluster_endpoint}"
    certificate-authority-data: "${module.eks.cluster_certificate_authority_data}"
  name: "${module.eks.cluster_arn}"
contexts:
- context:
    cluster: "${module.eks.cluster_arn}"
    user: "${module.eks.cluster_arn}"
  name: "${module.eks.cluster_arn}"
current-context: "${module.eks.cluster_arn}"
kind: Config
preferences: {}
users:
- name: "${module.eks.cluster_arn}"
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
      - --region
      - ${var.region}
      - eks
      - get-token
      - --cluster-name
      - ${var.cluster_name}
      - --output
      - json
EOT
}
