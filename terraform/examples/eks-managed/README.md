# EKS Managed Mode Example

This example deploys Hypernym API to EKS using managed inference mode.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.5.0
- kubectl installed
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

This will take approximately 15-20 minutes to create the EKS cluster and deploy the application.

## Configure kubectl

After deployment completes:

```bash
aws eks update-kubeconfig --name hypernym-cluster --region us-east-1

# Verify connection
kubectl get nodes
kubectl get pods -n hypernym
```

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
```

Note: EKS cluster deletion can take 10-15 minutes.

## Resources Created

- VPC with 2 private subnets
- EKS cluster with managed node group
- Internal Application Load Balancer via Ingress
- IAM roles with IRSA and marketplace metering permissions
- Kubernetes namespace and resources
- Horizontal Pod Autoscaler
- CloudWatch log groups
- VPC endpoints for AWS services
