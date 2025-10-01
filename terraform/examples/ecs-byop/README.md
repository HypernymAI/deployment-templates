# ECS BYOP Mode Example

This example deploys Hypernym API to ECS Fargate using Bring Your Own Provider (BYOP) mode.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.5.0
- AWS account with appropriate permissions
- Secrets Manager secret with BYOP credentials

## Setup BYOP Secret

Create a secret in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name hypernym-byop-credentials \
  --secret-string '{
    "provider_url": "https://api.openai.com/v1",
    "api_key": "sk-proj-...",
    "model_name": "gpt-4-turbo"
  }' \
  --region us-east-1
```

Note the secret ARN from the output.

## Configuration

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and update:
   - `container_image`: Your ECR image URI
   - `product_code`: AWS Marketplace product code
   - `byop_secret_arn`: ARN from secret creation step

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Accessing the Service

The service is deployed with an internal ALB. Get the URL:

```bash
terraform output load_balancer_url
```

## Cleanup

```bash
terraform destroy

# Optionally delete the secret
aws secretsmanager delete-secret \
  --secret-id hypernym-byop-credentials \
  --force-delete-without-recovery
```

## Resources Created

- VPC with 2 private subnets
- Internal Application Load Balancer
- ECS Fargate cluster and service
- IAM roles with Secrets Manager access
- CloudWatch log group
- Auto-scaling policies
- VPC endpoints for AWS services
