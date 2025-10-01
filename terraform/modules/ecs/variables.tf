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
  description = "Security group ID for ECS tasks"
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

variable "task_cpu" {
  description = "Task CPU units"
  type        = string
}

variable "task_memory" {
  description = "Task memory (MB)"
  type        = string
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
}

variable "min_capacity" {
  description = "Minimum task count for autoscaling"
  type        = number
}

variable "max_capacity" {
  description = "Maximum task count for autoscaling"
  type        = number
}

variable "task_execution_role_arn" {
  description = "Task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "Task role ARN"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
