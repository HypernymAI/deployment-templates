# ECS Managed Mode Example

This example deploys Hypernym API to ECS Fargate using managed inference mode.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.5.0
- AWS account with appropriate permissions

## Configuration

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and update:
   - `container_image`: Your ECR image URI
   - `product_code`: AWS Marketplace product code
   - `managed_api_url`: Update if different from default

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
```

## Resources Created

- VPC with 2 private subnets
- Internal Application Load Balancer
- ECS Fargate cluster and service
- IAM roles with marketplace metering permissions
- CloudWatch log group
- Auto-scaling policies
- VPC endpoints for AWS services
