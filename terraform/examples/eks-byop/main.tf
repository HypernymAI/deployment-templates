terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "hypernym" {
  source = "../.."

  aws_region              = var.aws_region
  deployment_target       = "eks"
  project_name            = var.project_name
  container_image         = var.container_image
  product_code            = var.product_code
  inference_provider_mode = "byop"
  byop_secret_arn         = var.byop_secret_arn
  vpc_cidr                = var.vpc_cidr
  private_subnet_cidrs    = var.private_subnet_cidrs
  desired_count           = var.desired_count
  min_capacity            = var.min_capacity
  max_capacity            = var.max_capacity
  eks_node_instance_type  = var.eks_node_instance_type
  eks_node_min_size       = var.eks_node_min_size
  eks_node_max_size       = var.eks_node_max_size
  eks_node_desired_size   = var.eks_node_desired_size
  container_port          = var.container_port
  log_level               = var.log_level
  environment             = var.environment
  tags                    = var.tags
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.hypernym.vpc_id
}

output "load_balancer_url" {
  description = "Load balancer URL"
  value       = module.hypernym.load_balancer_url
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.hypernym.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.hypernym.eks_cluster_endpoint
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.hypernym.eks_cluster_name} --region ${var.aws_region}"
}
