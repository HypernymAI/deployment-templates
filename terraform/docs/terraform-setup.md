# Terraform Setup Guide

Complete guide for deploying Hypernym API using Terraform.

## Prerequisites

### Required Tools

- **Terraform** >= 1.5.0
  ```bash
  terraform version
  ```

- **AWS CLI** configured with credentials
  ```bash
  aws configure
  aws sts get-caller-identity
  ```

- **kubectl** (for EKS deployments)
  ```bash
  kubectl version --client
  ```

- **Helm** (for EKS deployments)
  ```bash
  helm version
  ```

### AWS Permissions

The AWS user/role needs permissions for:
- VPC, Subnets, Security Groups, Route Tables
- Application Load Balancer
- VPC Endpoints
- ECS or EKS resources
- IAM roles and policies
- CloudWatch Logs
- Secrets Manager (for BYOP mode)

## Quick Start

### 1. Choose Your Deployment

Navigate to the appropriate example directory:

```bash
cd terraform/examples/ecs-managed    # ECS with managed inference
cd terraform/examples/ecs-byop       # ECS with BYOP
cd terraform/examples/eks-managed    # EKS with managed inference
cd terraform/examples/eks-byop       # EKS with BYOP
```

### 2. Configure Variables

Copy and edit the variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
product_code    = "abc123xyz456"
aws_region      = "us-east-1"
```

### 3. Initialize Terraform

```bash
terraform init
```

This downloads required providers and sets up the backend.

### 4. Plan Deployment

```bash
terraform plan
```

Review the resources that will be created.

### 5. Deploy

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Timing:**
- ECS deployments: ~5-10 minutes
- EKS deployments: ~15-20 minutes

### 6. Get Outputs

```bash
terraform output
terraform output -raw load_balancer_url
```

## BYOP Mode Setup

For BYOP deployments, create the secret first:

```bash
aws secretsmanager create-secret \
  --name hypernym-byop-credentials \
  --secret-string '{
    "provider_url": "https://api.openai.com/v1",
    "api_key": "sk-proj-YOUR-KEY-HERE",
    "model_name": "gpt-4-turbo"
  }' \
  --region us-east-1
```

Copy the ARN and add it to `terraform.tfvars`:

```hcl
byop_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:hypernym-byop-credentials-abc123"
```

## EKS-Specific Steps

### Configure kubectl

After EKS deployment:

```bash
aws eks update-kubeconfig --name hypernym-cluster --region us-east-1
```

### Verify Deployment

```bash
kubectl get nodes
kubectl get pods -n hypernym
kubectl get ingress -n hypernym
```

### Update BYOP Secret (EKS BYOP only)

```bash
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id hypernym-byop-credentials \
  --query SecretString --output text)

kubectl create secret generic hypernym-byop-credentials \
  --from-literal=provider_url=$(echo $SECRET_JSON | jq -r .provider_url) \
  --from-literal=api_key=$(echo $SECRET_JSON | jq -r .api_key) \
  --from-literal=model_name=$(echo $SECRET_JSON | jq -r .model_name) \
  --namespace hypernym \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Testing the Deployment

### Health Check

```bash
ALB_URL=$(terraform output -raw load_balancer_url)
curl $ALB_URL/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "0.3.0",
  "environment": "production"
}
```

### View Logs

**ECS:**
```bash
aws logs tail /ecs/hypernym --follow
```

**EKS:**
```bash
kubectl logs -f -n hypernym -l app.kubernetes.io/name=hypernym
```

## Updating Deployments

### Update Container Image

Edit `terraform.tfvars`:
```hcl
container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:v2.0.0"
```

Apply changes:
```bash
terraform apply
```

### Update Configuration

Modify any variable in `terraform.tfvars` and run:
```bash
terraform apply
```

## State Management

### Remote State (Recommended for Teams)

Create S3 backend configuration:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "hypernym/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

Initialize with backend:
```bash
terraform init -migrate-state
```

### Import Existing Resources

If you have existing resources:

```bash
terraform import module.hypernym.module.networking.aws_vpc.main vpc-12345678
```

## Cleanup

### Destroy All Resources

```bash
terraform destroy
```

Type `yes` when prompted.

**Important:** This deletes all resources including data. Ensure you have backups.

### Selective Destroy

To destroy specific resources:

```bash
terraform destroy -target=module.hypernym.module.ecs[0]
```

## Troubleshooting

### Common Issues

**Insufficient IAM Permissions**
```
Error: creating ECS Cluster: AccessDeniedException
```
Solution: Add required IAM permissions to your AWS user/role.

**VPC CIDR Conflicts**
```
Error: CIDR block conflicts with existing VPC
```
Solution: Change `vpc_cidr` in `terraform.tfvars`.

**EKS Cluster Creation Timeout**
```
Error: timeout while waiting for state to become 'ACTIVE'
```
Solution: Increase timeout or check AWS Service Health Dashboard.

**Image Pull Errors**
```
Error: ErrImagePull
```
Solution: Verify ECR permissions and image URI.

### Enable Debug Logging

```bash
TF_LOG=DEBUG terraform apply
```

### Check Provider Versions

```bash
terraform version
terraform providers
```

### Force Unlock State

If state is locked:
```bash
terraform force-unlock LOCK_ID
```

## Best Practices

### 1. Use Remote State

Always use S3 backend with DynamoDB locking for team environments.

### 2. Workspace Isolation

Use workspaces for multiple environments:
```bash
terraform workspace new production
terraform workspace new staging
terraform workspace select production
```

### 3. Variable Files

Use separate `.tfvars` files per environment:
```bash
terraform apply -var-file="production.tfvars"
```

### 4. Validate Before Apply

Always run plan first:
```bash
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### 5. Tag Resources

Add meaningful tags:
```hcl
tags = {
  Environment = "production"
  Team        = "platform"
  CostCenter  = "engineering"
  Terraform   = "true"
}
```

### 6. Pin Provider Versions

Use exact versions in production:
```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "= 5.31.0"
  }
}
```

## Next Steps

- Review [Configuration Reference](configuration.md)
- See [Migration Guide](migration.md) for CloudFormation migration
- Check example READMEs for specific deployment scenarios
- Configure monitoring and alerting
- Set up CI/CD pipeline for Terraform
