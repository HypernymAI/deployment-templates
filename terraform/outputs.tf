output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = module.networking.load_balancer_dns
}

output "load_balancer_url" {
  description = "Load balancer URL"
  value       = "http://${module.networking.load_balancer_dns}"
}

output "security_group_id" {
  description = "Security group ID for the application"
  value       = var.deployment_target == "ecs" ? module.networking.ecs_task_security_group_id : module.networking.eks_pod_security_group_id
}

output "iam_role_arn" {
  description = "IAM role ARN for the application"
  value       = var.deployment_target == "ecs" ? module.iam.ecs_task_role_arn : module.iam.eks_pod_role_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name (only for ECS deployments)"
  value       = var.deployment_target == "ecs" ? module.ecs[0].cluster_name : null
}

output "ecs_service_name" {
  description = "ECS service name (only for ECS deployments)"
  value       = var.deployment_target == "ecs" ? module.ecs[0].service_name : null
}

output "eks_cluster_name" {
  description = "EKS cluster name (only for EKS deployments)"
  value       = var.deployment_target == "eks" ? module.eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint (only for EKS deployments)"
  value       = var.deployment_target == "eks" ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data (only for EKS deployments)"
  value       = var.deployment_target == "eks" ? module.eks[0].cluster_certificate_authority_data : null
  sensitive   = true
}
