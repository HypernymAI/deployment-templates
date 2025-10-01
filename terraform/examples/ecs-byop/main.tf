terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "hypernym" {
  source = "../.."

  aws_region              = var.aws_region
  deployment_target       = "ecs"
  project_name            = var.project_name
  container_image         = var.container_image
  product_code            = var.product_code
  inference_provider_mode = "byop"
  byop_secret_arn         = var.byop_secret_arn
  vpc_cidr                = var.vpc_cidr
  private_subnet_cidrs    = var.private_subnet_cidrs
  task_cpu                = var.task_cpu
  task_memory             = var.task_memory
  desired_count           = var.desired_count
  min_capacity            = var.min_capacity
  max_capacity            = var.max_capacity
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

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.hypernym.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.hypernym.ecs_service_name
}
