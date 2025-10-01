provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "cluster" {
  count = var.deployment_target == "eks" ? 1 : 0
  name  = module.eks[0].cluster_name

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.deployment_target == "eks" ? 1 : 0
  name  = module.eks[0].cluster_name

  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = var.deployment_target == "eks" ? data.aws_eks_cluster.cluster[0].endpoint : null
  cluster_ca_certificate = var.deployment_target == "eks" ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
  token                  = var.deployment_target == "eks" ? data.aws_eks_cluster_auth.cluster[0].token : null
}

provider "helm" {
  kubernetes {
    host                   = var.deployment_target == "eks" ? data.aws_eks_cluster.cluster[0].endpoint : null
    cluster_ca_certificate = var.deployment_target == "eks" ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
    token                  = var.deployment_target == "eks" ? data.aws_eks_cluster_auth.cluster[0].token : null
  }
}

locals {
  common_tags = merge(
    var.tags,
    {
      Project           = var.project_name
      ManagedBy         = "Terraform"
      DeploymentTarget  = var.deployment_target
      InferenceProvider = var.inference_provider_mode
    }
  )
}

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  container_port       = var.container_port
  deployment_target    = var.deployment_target
  tags                 = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  project_name            = var.project_name
  deployment_target       = var.deployment_target
  inference_provider_mode = var.inference_provider_mode
  product_code            = var.product_code
  byop_secret_arn         = var.byop_secret_arn
  eks_cluster_name        = var.deployment_target == "eks" ? module.eks[0].cluster_name : ""
  eks_oidc_provider_arn   = var.deployment_target == "eks" ? module.eks[0].oidc_provider_arn : ""
  tags                    = local.common_tags

  depends_on = [module.eks]
}

module "ecs" {
  count  = var.deployment_target == "ecs" ? 1 : 0
  source = "./modules/ecs"

  project_name            = var.project_name
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  security_group_id       = module.networking.ecs_task_security_group_id
  target_group_arn        = module.networking.target_group_arn
  container_image         = var.container_image
  container_port          = var.container_port
  task_cpu                = var.task_cpu
  task_memory             = var.task_memory
  desired_count           = var.desired_count
  min_capacity            = var.min_capacity
  max_capacity            = var.max_capacity
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn
  inference_provider_mode = var.inference_provider_mode
  managed_api_url         = var.managed_api_url
  byop_secret_arn         = var.byop_secret_arn
  product_code            = var.product_code
  log_level               = var.log_level
  environment             = var.environment
  tags                    = local.common_tags
}

module "eks" {
  count  = var.deployment_target == "eks" ? 1 : 0
  source = "./modules/eks"

  project_name            = var.project_name
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  security_group_id       = module.networking.eks_pod_security_group_id
  target_group_arn        = module.networking.target_group_arn
  container_image         = var.container_image
  container_port          = var.container_port
  desired_count           = var.desired_count
  min_capacity            = var.min_capacity
  max_capacity            = var.max_capacity
  pod_role_arn            = module.iam.eks_pod_role_arn
  inference_provider_mode = var.inference_provider_mode
  managed_api_url         = var.managed_api_url
  byop_secret_arn         = var.byop_secret_arn
  product_code            = var.product_code
  log_level               = var.log_level
  environment             = var.environment
  node_instance_type      = var.eks_node_instance_type
  node_min_size           = var.eks_node_min_size
  node_max_size           = var.eks_node_max_size
  node_desired_size       = var.eks_node_desired_size
  tags                    = local.common_tags
}
