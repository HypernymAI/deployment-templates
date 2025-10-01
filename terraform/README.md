# Hypernym Terraform Module

Terraform module for deploying Hypernym API on AWS via ECS Fargate or EKS.

## Features

- ✅ **Dual Platform Support**: Deploy to ECS Fargate or EKS
- ✅ **Managed & BYOP Modes**: Use Sibylline's managed inference or bring your own provider
- ✅ **Private Networking**: Internal ALB with VPC endpoints (no NAT Gateway)
- ✅ **High Availability**: Multi-AZ deployment with auto-scaling
- ✅ **AWS Marketplace**: Built-in metering and billing integration
- ✅ **Production Ready**: Security best practices and monitoring
- ✅ **Infrastructure as Code**: Repeatable, version-controlled deployments

## Quick Start

### ECS Deployment

```hcl
module "hypernym" {
  source = "github.com/sibylline/hypernym//deployment-templates/terraform"

  aws_region              = "us-east-1"
  deployment_target       = "ecs"
  container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
  product_code            = "abc123xyz456"
  inference_provider_mode = "managed"
}
```

### EKS Deployment

```hcl
module "hypernym" {
  source = "github.com/sibylline/hypernym//deployment-templates/terraform"

  aws_region              = "us-east-1"
  deployment_target       = "eks"
  container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
  product_code            = "abc123xyz456"
  inference_provider_mode = "managed"
}
```

### BYOP Mode

```hcl
module "hypernym" {
  source = "github.com/sibylline/hypernym//deployment-templates/terraform"

  aws_region              = "us-east-1"
  deployment_target       = "ecs"
  container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
  product_code            = "abc123xyz456"
  inference_provider_mode = "byop"
  byop_secret_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:hypernym-byop-abc123"
}
```

## Examples

Complete examples are available in the `examples/` directory:

- [ECS Managed Mode](examples/ecs-managed/) - ECS with managed inference
- [ECS BYOP Mode](examples/ecs-byop/) - ECS with bring your own provider
- [EKS Managed Mode](examples/eks-managed/) - EKS with managed inference
- [EKS BYOP Mode](examples/eks-byop/) - EKS with bring your own provider

## Documentation

- [Terraform Setup Guide](docs/terraform-setup.md) - Complete setup and deployment guide
- [Configuration Reference](docs/configuration.md) - All variables and options
- [Migration Guide](docs/migration.md) - Migrate from CloudFormation to Terraform

## Architecture

### Network Design

- **Private Subnets**: All resources in private subnets across 2 AZs
- **Internal ALB**: Load balancer accessible only within VPC
- **VPC Endpoints**: Direct AWS service access without NAT Gateway
- **Security Groups**: Least privilege network access

### Compute Options

**ECS Fargate:**
- Serverless container execution
- No server management
- Pay-per-use pricing
- Ideal for: Simpler deployments, lower operational overhead

**EKS:**
- Kubernetes-based orchestration
- Advanced scheduling and features
- More control and flexibility
- Ideal for: Complex workloads, Kubernetes expertise

### Inference Modes

**Managed Mode:**
- Use Sibylline's managed inference service
- Simplified setup, no API keys needed
- Fully managed scaling
- AWS Marketplace billing

**BYOP Mode:**
- Use your own inference API (OpenAI, Anthropic, etc.)
- Control your provider
- Direct billing with your provider
- Requires AWS Secrets Manager secret

## Module Structure

```
terraform/
├── main.tf                     # Root module orchestration
├── variables.tf                # Input variables
├── outputs.tf                  # Output values
├── versions.tf                 # Provider requirements
├── modules/
│   ├── networking/             # VPC, subnets, ALB, security groups
│   ├── iam/                    # IAM roles with conditional policies
│   ├── ecs/                    # ECS cluster, tasks, services
│   └── eks/                    # EKS cluster, nodes, Helm deployment
├── examples/                   # Complete usage examples
└── docs/                       # Documentation
```

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- kubectl (for EKS deployments)
- Helm (for EKS deployments)
- AWS account with appropriate permissions

## Resources Created

### Common Resources (Both ECS and EKS)

- VPC with 2 private subnets
- Internal Application Load Balancer
- Security Groups
- VPC Endpoints (ECR, S3, Secrets Manager, CloudWatch Logs)
- IAM Roles with conditional policies
- CloudWatch Log Groups

### ECS-Specific Resources

- ECS Cluster
- ECS Task Definition
- ECS Service
- Auto Scaling Target and Policies

### EKS-Specific Resources

- EKS Cluster
- EKS Managed Node Group
- OIDC Provider for IRSA
- Kubernetes Namespace
- Helm Release (application deployment)
- Horizontal Pod Autoscaler

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

*Costs for us-east-1. Actual costs vary by region, usage, and configuration.*

## Development Setup

### Install Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
cd terraform
pre-commit install

# Run manually
pre-commit run --all-files
```

### Generate Documentation

```bash
# Install terraform-docs
brew install terraform-docs

# Generate docs
terraform-docs markdown table . > README.md
```

### Lint Terraform

```bash
# Install tflint
brew install tflint

# Initialize
tflint --init

# Run linter
tflint
```

## Security

### Best Practices

- ✅ VPC with private subnets only
- ✅ Internal ALB (not internet-facing)
- ✅ Security groups with least privilege
- ✅ IAM roles with conditional permissions
- ✅ Secrets stored in AWS Secrets Manager
- ✅ Non-root container user
- ✅ Dropped Linux capabilities
- ✅ Encrypted VPC endpoints

### Secrets Management

**Never commit secrets to Git**

For BYOP mode, use AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name hypernym-byop-credentials \
  --secret-string '{
    "provider_url": "https://api.openai.com/v1",
    "api_key": "sk-proj-...",
    "model_name": "gpt-4-turbo"
  }'
```

## Monitoring

### CloudWatch Metrics

- CPU and memory utilization
- Request count and latency
- Health check status
- Auto-scaling activities

### Logs

```bash
# ECS
aws logs tail /ecs/hypernym --follow

# EKS
kubectl logs -f -n hypernym -l app.kubernetes.io/name=hypernym
```

## Support

For issues or questions:
- Email: dan@sibylline.group
- GitHub: https://github.com/sibylline/hypernym
- Documentation: See `docs/` directory

## License

MIT AND (Apache-2.0 OR BSD-2-Clause)

---

**Note**: This is an AWS Marketplace deployment module. The Hypernym API container image is distributed separately via AWS Marketplace.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
