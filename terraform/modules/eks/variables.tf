variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for EKS pods"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for ALB"
  type        = string
}

variable "container_image" {
  description = "Container image URI"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "desired_count" {
  description = "Desired pod count"
  type        = number
}

variable "min_capacity" {
  description = "Minimum pod count for autoscaling"
  type        = number
}

variable "max_capacity" {
  description = "Maximum pod count for autoscaling"
  type        = number
}

variable "pod_role_arn" {
  description = "Pod IAM role ARN"
  type        = string
}

variable "inference_provider_mode" {
  description = "Inference provider mode"
  type        = string
}

variable "managed_api_url" {
  description = "Managed API URL"
  type        = string
}

variable "byop_secret_arn" {
  description = "BYOP secret ARN"
  type        = string
  sensitive   = true
}

variable "product_code" {
  description = "AWS Marketplace product code"
  type        = string
}

variable "log_level" {
  description = "Application log level"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for nodes"
  type        = string
}

variable "node_min_size" {
  description = "Minimum node count"
  type        = number
}

variable "node_max_size" {
  description = "Maximum node count"
  type        = number
}

variable "node_desired_size" {
  description = "Desired node count"
  type        = number
}

variable "helm_chart_path" {
  description = "Path to Helm chart (relative to root)"
  type        = string
  default     = "../helm/hypernym"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
