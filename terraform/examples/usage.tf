module "hypernym_ecs" {
  source = "../../"

  aws_region              = "us-east-1"
  deployment_target       = "ecs"
  project_name            = "hypernym"
  container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
  product_code            = "abc123xyz456"
  inference_provider_mode = "managed"
  managed_api_url         = "http://one-api-service:8080"

  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

  task_cpu      = "512"
  task_memory   = "1024"
  desired_count = 2
  min_capacity  = 2
  max_capacity  = 10

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
