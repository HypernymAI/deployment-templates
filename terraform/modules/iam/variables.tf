variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "deployment_target" {
  description = "Deployment target (ecs or eks)"
  type        = string
}

variable "inference_provider_mode" {
  description = "Inference provider mode (managed or byop)"
  type        = string
}

variable "product_code" {
  description = "AWS Marketplace product code"
  type        = string
}

variable "byop_secret_arn" {
  description = "ARN of Secrets Manager secret for BYOP mode"
  type        = string
  default     = ""
  sensitive   = true
}

variable "eks_cluster_name" {
  description = "EKS cluster name for IRSA"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
