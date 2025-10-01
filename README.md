# Hypernym Deployment Templates

Infrastructure as Code templates for deploying Hypernym API on AWS via AWS Marketplace.

## Overview

This repository contains deployment templates for running Hypernym API on AWS infrastructure:

- **ECS Fargate**: Serverless container deployment
- **EKS (Kubernetes)**: Flexible cluster-based deployment

### Deployment Methods

- **[Terraform Module](terraform/)**: Modern IaC with modules for ECS and EKS (Recommended)
- **[CloudFormation Templates](cloudformation/)**: Native AWS templates
- **[Helm Charts](helm/)**: For existing Kubernetes clusters

All deployment methods support:
- ✅ **Managed Mode**: Use Sibylline's managed inference service
- ✅ **BYOP Mode**: Bring your own provider (OpenAI, Anthropic, etc.)
- ✅ **Private Networking**: Internal ALB with VPC endpoints
- ✅ **High Availability**: Multi-AZ deployment with auto-scaling
- ✅ **AWS Marketplace**: Built-in metering and billing integration
- ✅ **Production Ready**: Security best practices and monitoring

## Quick Start

### Choose Your Deployment Method

**Terraform (Recommended)**
```bash
cd terraform/examples/ecs-managed
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
terraform init
terraform apply
```

**CloudFormation**
```bash
cd cloudformation
aws cloudformation create-stack \
  --stack-name hypernym-ecs \
  --template-body file://ecs-fargate.yaml \
  --parameters file://examples/ecs-managed-params.json \
  --capabilities CAPABILITY_NAMED_IAM
```

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0 (for Terraform deployments)
- kubectl and Helm (for EKS deployments)
- AWS account with permissions for ECS/EKS, IAM, VPC

## Deployment Options

### Terraform Module (Recommended)

Modern Infrastructure as Code with modular design:

```hcl
module "hypernym" {
  source = "./terraform"

  deployment_target       = "ecs"  # or "eks"
  container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
  product_code            = "abc123xyz456"
  inference_provider_mode = "managed"  # or "byop"
}
```

**Benefits:**
- Single module for both ECS and EKS
- Better variable validation
- Cleaner state management
- Easier to version and reuse

See [Terraform documentation](terraform/) for complete guide.

### CloudFormation Templates

Native AWS templates for infrastructure deployment.

#### Deploy to ECS Fargate

1. **Update Parameters**:
   ```bash
   cp examples/ecs-managed-params.json my-params.json
   # Edit my-params.json with your configuration
   ```

2. **Deploy Stack**:
   ```bash
   aws cloudformation create-stack \
     --stack-name hypernym-ecs \
     --template-body file://cloudformation/ecs-fargate.yaml \
     --parameters file://my-params.json \
     --capabilities CAPABILITY_NAMED_IAM \
     --region us-east-1
   ```

3. **Monitor Deployment**:
   ```bash
   aws cloudformation wait stack-create-complete \
     --stack-name hypernym-ecs
   ```

4. **Get Load Balancer URL**:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name hypernym-ecs \
     --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
     --output text
   ```

#### Deploy to EKS

1. **Deploy EKS Infrastructure**:
   ```bash
   aws cloudformation create-stack \
     --stack-name hypernym-eks \
     --template-body file://cloudformation/eks.yaml \
     --parameters \
       ParameterKey=ClusterName,ParameterValue=hypernym-cluster \
       ParameterKey=MarketplaceProductCode,ParameterValue=YOUR-PRODUCT-CODE \
     --capabilities CAPABILITY_NAMED_IAM
   ```

2. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --name hypernym-cluster --region us-east-1
   ```

3. **Install AWS Load Balancer Controller**:
   ```bash
   kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system --set clusterName=hypernym-cluster
   ```

4. **Deploy with Helm**:
   ```bash
   cp examples/eks-managed-values.yaml my-values.yaml
   # Edit my-values.yaml with your configuration

   kubectl create namespace hypernym
   helm install hypernym ./helm/hypernym \
     --namespace hypernym \
     --values my-values.yaml
   ```

## Repository Structure

```
deployment-templates/
├── terraform/                    # Terraform module (Recommended)
│   ├── main.tf                   # Root module orchestration
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── modules/                  # Sub-modules
│   │   ├── networking/           # VPC, ALB, security groups
│   │   ├── iam/                  # IAM roles with conditional policies
│   │   ├── ecs/                  # ECS cluster and services
│   │   └── eks/                  # EKS cluster and Helm deployment
│   ├── examples/                 # Complete usage examples
│   │   ├── ecs-managed/
│   │   ├── ecs-byop/
│   │   ├── eks-managed/
│   │   └── eks-byop/
│   └── docs/                     # Terraform documentation
│       ├── terraform-setup.md
│       ├── configuration.md
│       └── migration.md
├── cloudformation/               # CloudFormation templates
│   ├── ecs-fargate.yaml          # ECS Fargate deployment
│   └── eks.yaml                  # EKS cluster infrastructure
├── helm/                         # Helm charts
│   └── hypernym/                 # Helm chart for EKS
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── examples/                     # CloudFormation examples
│   ├── ecs-managed-params.json   # ECS managed mode parameters
│   ├── ecs-byop-params.json      # ECS BYOP mode parameters
│   ├── eks-managed-values.yaml   # EKS managed mode values
│   ├── eks-byop-values.yaml      # EKS BYOP mode values
│   └── byop-secret-template.json # BYOP secrets format
├── docs/                         # General documentation
│   ├── deployment-guide.md       # Detailed deployment steps
│   ├── architecture.md           # Architecture documentation
│   ├── parameters.md             # Parameter reference
│   └── troubleshooting.md        # Common issues and solutions
└── README.md                     # This file
```

## Deployment Modes

### Managed Mode (Default)

Use Sibylline's managed inference service:

- Simplified setup - no external API keys required
- Fully managed scaling and availability
- Pay-per-use via AWS Marketplace
- Automatic updates and improvements

**Configuration**: Set `InferenceProviderMode=managed`

### BYOP Mode (Bring Your Own Provider)

Use your own inference API (OpenAI, Anthropic, etc.):

- Control your own inference provider
- Use existing API keys and agreements
- Direct billing with your provider
- Flexible provider selection

**Configuration**:
1. Create secret in AWS Secrets Manager:
   ```json
   {
     "provider_url": "https://api.openai.com/v1",
     "api_key": "sk-proj-...",
     "model_name": "gpt-4-turbo"
   }
   ```
2. Set `InferenceProviderMode=byop`
3. Provide secret ARN in parameters

## Architecture Highlights

### Network Design

- **Private Subnets**: All resources in private subnets (no internet gateway)
- **Multi-AZ**: Deployed across 2 availability zones
- **Internal ALB**: Load balancer accessible only within VPC
- **VPC Endpoints**: Direct AWS service access (no NAT Gateway costs)

### Security Features

- **Least Privilege IAM**: Conditional permissions based on mode
- **Secrets Management**: Secure credential handling via Secrets Manager
- **Container Security**: Non-root user, dropped capabilities, security scanning
- **Network Isolation**: Security groups with minimal required access

### Scalability

- **ECS**: Auto-scaling based on CPU/memory metrics
- **EKS**: Horizontal Pod Autoscaler (2-10 replicas)
- **Resource Limits**: Configurable CPU and memory allocation
- **Health Checks**: Automatic unhealthy task/pod replacement

## Configuration Reference

### Required Configuration

Before deploying, update these placeholders in parameter/values files:

1. **Container Image URI** (TODO):
   ```
   <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<REPOSITORY_NAME>:latest
   ```

2. **Marketplace Product Code** (TODO):
   ```
   TODO-marketplace-product-code
   ```

3. **For Managed Mode** (TODO):
   - Update `MANAGED_API_URL` with actual one-api endpoint

4. **For BYOP Mode**:
   - Create Secrets Manager secret with provider credentials
   - Update `SecretsManagerSecretARN` parameter

### Common Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `VpcCIDR` | `10.0.0.0/16` | VPC CIDR block |
| `TaskCPU` / `cpu` | `512` / `250m` | CPU allocation |
| `TaskMemory` / `memory` | `1024` / `256Mi` | Memory allocation |
| `DesiredCount` / `replicaCount` | `2` | Initial task/pod count |
| `InferenceProviderMode` | `managed` | Provider mode (managed/byop) |

See [Parameters Reference](docs/parameters.md) for complete documentation.

## Accessing the Service

The service is deployed with an **internal ALB** and is not publicly accessible.

### Access Methods

1. **VPC Peering**: Peer your VPCs for direct access
2. **AWS Transit Gateway**: Connect multiple VPCs/networks
3. **VPN Connection**: Site-to-site or client VPN
4. **Bastion Host**: EC2 instance in the same VPC

### Testing from Within VPC

```bash
# Get ALB URL
ALB_URL=$(aws cloudformation describe-stacks \
  --stack-name hypernym-ecs \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text)

# Test health endpoint
curl http://${ALB_URL}/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "0.3.0",
  "environment": "production"
}
```

## Documentation

| Document | Description |
|----------|-------------|
| [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment instructions |
| [Architecture](docs/architecture.md) | System architecture and design decisions |
| [Parameters](docs/parameters.md) | Complete parameter reference |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |

## Cost Estimates

### ECS Fargate (Approximate)

| Component | Monthly Cost |
|-----------|-------------|
| Fargate (2 tasks, 0.5 vCPU, 1GB) | $30 |
| Internal ALB | $20 |
| VPC Endpoints (5) | $36 |
| CloudWatch Logs | $5 |
| **Total** | **~$91/month** |

### EKS (Approximate)

| Component | Monthly Cost |
|-----------|-------------|
| EKS Control Plane | $73 |
| EC2 Nodes (2x t3.medium) | $61 |
| Internal ALB | $20 |
| VPC Endpoints (5) | $36 |
| CloudWatch Logs | $5 |
| **Total** | **~$195/month** |

*Costs are estimates for us-east-1 region. Actual costs vary by region, usage, and configuration.*

## Monitoring and Logging

### CloudWatch Metrics

- CPU and memory utilization
- Request count and latency
- Health check status
- Auto-scaling activities

### Logs

- **ECS**: CloudWatch Logs at `/ecs/<stack-name>`
- **EKS**: CloudWatch Logs and Container Insights

### Viewing Logs

```bash
# ECS
aws logs tail /ecs/hypernym-ecs --follow

# EKS
kubectl logs -f -n hypernym -l app.kubernetes.io/name=hypernym
```

## Updating Deployments

### ECS

```bash
aws cloudformation update-stack \
  --stack-name hypernym-ecs \
  --template-body file://cloudformation/ecs-fargate.yaml \
  --parameters file://my-params.json \
  --capabilities CAPABILITY_NAMED_IAM
```

### EKS

```bash
helm upgrade hypernym ./helm/hypernym \
  --namespace hypernym \
  --values my-values.yaml
```

## Cleanup

### Delete ECS Stack

```bash
aws cloudformation delete-stack --stack-name hypernym-ecs
aws cloudformation wait stack-delete-complete --stack-name hypernym-ecs
```

### Delete EKS Deployment

```bash
# Delete Helm release
helm uninstall hypernym -n hypernym

# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name hypernym-eks
```

## Support and Troubleshooting

### Common Issues

- **Container won't start**: Check image URI and ECR permissions
- **Health checks failing**: Verify application is listening on port 8000
- **Cannot access ALB**: ALB is internal - access from within VPC
- **Secret access denied**: Verify IAM permissions and secret ARN

See [Troubleshooting Guide](docs/troubleshooting.md) for detailed solutions.

### Getting Help

1. Check the [Troubleshooting Guide](docs/troubleshooting.md)
2. Review CloudWatch Logs for error messages
3. Verify all TODO placeholders are updated
4. Contact Sibylline support with diagnostic information

## Security Best Practices

- ✅ Use Secrets Manager for sensitive data (never commit secrets)
- ✅ Regularly update container images with security patches
- ✅ Review IAM permissions periodically
- ✅ Enable CloudTrail for audit logging
- ✅ Use AWS GuardDuty for threat detection
- ✅ Implement VPC Flow Logs for network monitoring

## Contributing

This repository is maintained by Sibylline for AWS Marketplace deployments.

For issues or feature requests, please contact:
- Email: dan@sibylline.group
- GitHub: https://github.com/sibylline/hypernym

## License

MIT AND (Apache-2.0 OR BSD-2-Clause)

See [LICENSE](LICENSE) file for details.

---

**Note**: This is an AWS Marketplace deployment template. The Hypernym API container image is distributed separately via AWS Marketplace.
