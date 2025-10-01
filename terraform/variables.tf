variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "deployment_target" {
  description = "Deployment target platform"
  type        = string
  validation {
    condition     = contains(["ecs", "eks"], var.deployment_target)
    error_message = "deployment_target must be either 'ecs' or 'eks'"
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hypernym"
}

variable "container_image" {
  description = "Container image URI from ECR"
  type        = string
}

variable "product_code" {
  description = "AWS Marketplace product code for metering"
  type        = string
}

variable "inference_provider_mode" {
  description = "Inference provider mode: managed or byop"
  type        = string
  default     = "managed"
  validation {
    condition     = contains(["managed", "byop"], var.inference_provider_mode)
    error_message = "inference_provider_mode must be either 'managed' or 'byop'"
  }
}

variable "managed_api_url" {
  description = "URL for managed inference API (one-api endpoint)"
  type        = string
  default     = "http://one-api-service:8080"
}

variable "byop_secret_arn" {
  description = "ARN of AWS Secrets Manager secret containing BYOP credentials"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "task_cpu" {
  description = "CPU units for ECS task or EKS pod requests"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory for ECS task (MB) or EKS pod requests"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired number of tasks/pods"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks/pods for autoscaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks/pods for autoscaling"
  type        = number
  default     = 10
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8000
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "info"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 4
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
