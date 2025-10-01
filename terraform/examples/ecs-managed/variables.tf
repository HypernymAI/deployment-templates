variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "hypernym"
}

variable "container_image" {
  description = "Container image URI from ECR"
  type        = string
}

variable "product_code" {
  description = "AWS Marketplace product code"
  type        = string
}

variable "managed_api_url" {
  description = "Managed API URL"
  type        = string
  default     = "http://one-api-service:8080"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Task memory (MB)"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum task count"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum task count"
  type        = number
  default     = 10
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8000
}

variable "log_level" {
  description = "Log level"
  type        = string
  default     = "info"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
