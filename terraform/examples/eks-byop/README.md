# EKS BYOP Mode Example

This example deploys Hypernym API to EKS using Bring Your Own Provider (BYOP) mode.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.5.0
- kubectl installed
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

After deployment, you'll need to update the Kubernetes secret with the actual values:

```bash
# Get secret values from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id hypernym-byop-credentials \
  --query SecretString \
  --output text)

PROVIDER_URL=$(echo $SECRET_JSON | jq -r .provider_url)
API_KEY=$(echo $SECRET_JSON | jq -r .api_key)
MODEL_NAME=$(echo $SECRET_JSON | jq -r .model_name)

# Update Kubernetes secret
kubectl create secret generic hypernym-byop-credentials \
  --from-literal=provider_url=$PROVIDER_URL \
  --from-literal=api_key=$API_KEY \
  --from-literal=model_name=$MODEL_NAME \
  --namespace hypernym \
  --dry-run=client -o yaml | kubectl apply -f -
```

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

This will take approximately 15-20 minutes to create the EKS cluster and deploy the application.

## Configure kubectl

After deployment completes:

```bash
aws eks update-kubeconfig --name hypernym-cluster --region us-east-1

# Verify connection
kubectl get nodes
kubectl get pods -n hypernym
```

## Update Secret

Don't forget to update the Kubernetes secret with actual BYOP credentials (see "Setup BYOP Secret" above).

## Accessing the Service

The service is deployed with an internal ALB. Get the URL:

```bash
terraform output load_balancer_url

# Or check ingress
kubectl get ingress -n hypernym
```

## Monitoring

```bash
# View pod logs
kubectl logs -f -n hypernym -l app.kubernetes.io/name=hypernym

# Check pod status
kubectl describe pod -n hypernym -l app.kubernetes.io/name=hypernym

# View HPA status
kubectl get hpa -n hypernym
```

## Cleanup

```bash
terraform destroy

# Optionally delete the secret
aws secretsmanager delete-secret \
  --secret-id hypernym-byop-credentials \
  --force-delete-without-recovery
```

Note: EKS cluster deletion can take 10-15 minutes.

## Resources Created

- VPC with 2 private subnets
- EKS cluster with managed node group
- Internal Application Load Balancer via Ingress
- IAM roles with IRSA and Secrets Manager access
- Kubernetes namespace and resources
- Kubernetes secret for BYOP credentials
- Horizontal Pod Autoscaler
- CloudWatch log groups
- VPC endpoints for AWS services
