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

variable "byop_secret_arn" {
  description = "ARN of Secrets Manager secret containing BYOP credentials"
  type        = string
  sensitive   = true
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

variable "desired_count" {
  description = "Desired pod count"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum pod count"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum pod count"
  type        = number
  default     = 10
}

variable "eks_node_instance_type" {
  description = "EKS node instance type"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_min_size" {
  description = "Minimum EKS nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum EKS nodes"
  type        = number
  default     = 4
}

variable "eks_node_desired_size" {
  description = "Desired EKS nodes"
  type        = number
  default     = 2
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
