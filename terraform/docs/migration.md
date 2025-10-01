# CloudFormation to Terraform Migration Guide

Guide for migrating from CloudFormation templates to Terraform modules.

## Overview

This guide helps you transition from CloudFormation-based deployments to Terraform, comparing features and providing migration strategies.

## Feature Comparison

| Feature | CloudFormation | Terraform | Notes |
|---------|---------------|-----------|-------|
| VPC Creation | ✅ | ✅ | Identical |
| ECS Deployment | ✅ | ✅ | Identical |
| EKS Deployment | ✅ | ✅ | Terraform uses Helm provider |
| Managed Mode | ✅ | ✅ | Identical |
| BYOP Mode | ✅ | ✅ | Identical |
| Auto-scaling | ✅ | ✅ | Identical |
| VPC Endpoints | ✅ | ✅ | Identical |
| IAM Roles | ✅ | ✅ | Identical structure |

## Parameter Mapping

### CloudFormation → Terraform

| CloudFormation Parameter | Terraform Variable | Notes |
|-------------------------|-------------------|-------|
| `ContainerImage` | `container_image` | Identical |
| `MarketplaceProductCode` | `product_code` | Renamed |
| `InferenceProviderMode` | `inference_provider_mode` | Identical |
| `ManagedAPIURL` | `managed_api_url` | Identical |
| `SecretsManagerSecretARN` | `byop_secret_arn` | Renamed |
| `VpcCIDR` | `vpc_cidr` | Identical |
| `PrivateSubnet1CIDR` | `private_subnet_cidrs[0]` | Now a list |
| `PrivateSubnet2CIDR` | `private_subnet_cidrs[1]` | Now a list |
| `ClusterName` | `project_name` + "-cluster" | Auto-generated |
| `ServiceName` | `project_name` + "-service" | Auto-generated |
| `TaskCPU` | `task_cpu` | Identical |
| `TaskMemory` | `task_memory` | Identical |
| `DesiredCount` | `desired_count` | Identical |
| N/A | `deployment_target` | New: "ecs" or "eks" |
| N/A | `min_capacity` | New: Auto-scaling min |
| N/A | `max_capacity` | New: Auto-scaling max |

## Migration Strategies

### Strategy 1: Fresh Deployment (Recommended)

Deploy new infrastructure with Terraform alongside existing CloudFormation stack, then cutover.

**Pros:**
- Zero downtime
- Easy rollback
- Test before cutover

**Cons:**
- Temporary double cost
- Requires DNS/routing changes

**Steps:**

1. Deploy Terraform stack with different name:
   ```hcl
   project_name = "hypernym-tf"
   ```

2. Test new deployment thoroughly

3. Update routing to new ALB

4. Delete CloudFormation stack

### Strategy 2: Import Existing Resources

Import CloudFormation-created resources into Terraform state.

**Pros:**
- No new resources
- Maintains existing setup

**Cons:**
- Complex and error-prone
- Potential for drift
- Downtime risk

**Steps:**

1. Export CloudFormation stack outputs

2. Create matching Terraform configuration

3. Import each resource:
   ```bash
   terraform import module.hypernym.module.networking.aws_vpc.main vpc-12345678
   ```

4. Verify state matches reality

### Strategy 3: Recreate (Quick & Clean)

Delete CloudFormation stack and deploy with Terraform.

**Pros:**
- Simple and clean
- No import complexity

**Cons:**
- Downtime required
- New resources = new IDs

**Steps:**

1. Document current configuration

2. Delete CloudFormation stack:
   ```bash
   aws cloudformation delete-stack --stack-name hypernym-ecs
   ```

3. Deploy Terraform:
   ```bash
   terraform apply
   ```

## Example Migrations

### ECS Managed: CloudFormation → Terraform

**CloudFormation Parameters (ecs-managed-params.json):**
```json
[
  {
    "ParameterKey": "ContainerImage",
    "ParameterValue": "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
  },
  {
    "ParameterKey": "MarketplaceProductCode",
    "ParameterValue": "abc123xyz456"
  },
  {
    "ParameterKey": "InferenceProviderMode",
    "ParameterValue": "managed"
  },
  {
    "ParameterKey": "TaskCPU",
    "ParameterValue": "512"
  },
  {
    "ParameterKey": "TaskMemory",
    "ParameterValue": "1024"
  }
]
```

**Equivalent Terraform (terraform.tfvars):**
```hcl
deployment_target       = "ecs"
container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
product_code            = "abc123xyz456"
inference_provider_mode = "managed"
task_cpu                = "512"
task_memory             = "1024"
```

### ECS BYOP: CloudFormation → Terraform

**CloudFormation:**
```json
{
  "ParameterKey": "InferenceProviderMode",
  "ParameterValue": "byop"
},
{
  "ParameterKey": "SecretsManagerSecretARN",
  "ParameterValue": "arn:aws:secretsmanager:us-east-1:123456789012:secret:hypernym-byop-abc123"
}
```

**Terraform:**
```hcl
inference_provider_mode = "byop"
byop_secret_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:hypernym-byop-abc123"
```

### EKS: CloudFormation → Terraform

**CloudFormation:**
```bash
# 1. Deploy EKS infrastructure
aws cloudformation create-stack \
  --stack-name hypernym-eks \
  --template-body file://cloudformation/eks.yaml

# 2. Install Helm chart manually
helm install hypernym ./helm/hypernym --values my-values.yaml
```

**Terraform:**
```hcl
# Single command deploys everything
deployment_target = "eks"
# ... other variables
```

Terraform automatically:
- Creates EKS cluster
- Deploys via Helm
- Configures IRSA

## Resource Name Changes

Terraform uses different naming conventions:

| Resource | CloudFormation | Terraform |
|----------|----------------|-----------|
| VPC | `{StackName}-VPC` | `{project_name}-vpc` |
| Cluster | `{ClusterName}` | `{project_name}-cluster` |
| Service | `{ServiceName}` | `{project_name}-service` |
| Security Group | `{StackName}-ALB-SG` | `{project_name}-alb-sg` |
| IAM Role | `{StackName}-TaskRole` | `{project_name}-ecs-task-role` |

To match existing names, set `project_name` to match your CloudFormation stack name.

## State Management

### CloudFormation State
CloudFormation manages state internally in AWS.

### Terraform State
Terraform uses local or remote state files.

**Recommended: Use S3 backend**

```hcl
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

## Outputs Comparison

### CloudFormation Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name hypernym-ecs \
  --query 'Stacks[0].Outputs'
```

**Output Structure:**
```json
[
  {
    "OutputKey": "LoadBalancerURL",
    "OutputValue": "http://internal-hypernym-alb-123456789.us-east-1.elb.amazonaws.com"
  },
  {
    "OutputKey": "VPCId",
    "OutputValue": "vpc-12345678"
  }
]
```

### Terraform Outputs

```bash
terraform output
```

**Output Structure:**
```
load_balancer_url = "http://internal-hypernym-alb-123456789.us-east-1.elb.amazonaws.com"
vpc_id = "vpc-12345678"
```

Get single output:
```bash
terraform output -raw load_balancer_url
```

## Update Process Comparison

### CloudFormation

```bash
# Update stack
aws cloudformation update-stack \
  --stack-name hypernym-ecs \
  --template-body file://cloudformation/ecs-fargate.yaml \
  --parameters file://my-params.json

# Wait for completion
aws cloudformation wait stack-update-complete \
  --stack-name hypernym-ecs
```

### Terraform

```bash
# Update configuration
vim terraform.tfvars

# Preview changes
terraform plan

# Apply changes
terraform apply
```

## Rollback Comparison

### CloudFormation

Automatic rollback on failure:
```bash
aws cloudformation describe-stack-events \
  --stack-name hypernym-ecs
```

Manual rollback:
```bash
aws cloudformation cancel-update-stack --stack-name hypernym-ecs
```

### Terraform

No automatic rollback. Manual approaches:

**1. Revert configuration:**
```bash
git revert HEAD
terraform apply
```

**2. Use previous state:**
```bash
terraform state pull > backup.tfstate
# Restore from backup if needed
```

**3. Target specific resources:**
```bash
terraform apply -target=module.hypernym.module.ecs[0]
```

## Cost Comparison

Both solutions have identical AWS resource costs:
- VPC, subnets, and networking: Free
- ALB: ~$20/month
- VPC Endpoints: ~$36/month
- ECS Tasks or EKS Nodes: Variable
- CloudWatch Logs: ~$5/month

**Additional Considerations:**
- CloudFormation: Free
- Terraform: Free (Terraform Cloud has paid tiers)

## Feature Advantages

### Terraform Advantages

1. **Multi-cloud**: Works with AWS, Azure, GCP
2. **Modules**: Better code reuse
3. **Plan preview**: See changes before apply
4. **State management**: More control over state
5. **Provider ecosystem**: Extensive provider library
6. **Local development**: Easier local testing

### CloudFormation Advantages

1. **Native AWS**: Integrated with AWS console
2. **Drift detection**: Built-in drift detection
3. **Rollback**: Automatic rollback on failure
4. **StackSets**: Multi-account/region deployments
5. **Registry**: Native template registry

## Migration Checklist

- [ ] Review existing CloudFormation stack configuration
- [ ] Export all parameter values
- [ ] Document custom resources or non-standard configurations
- [ ] Choose migration strategy
- [ ] Set up Terraform backend (S3 + DynamoDB)
- [ ] Create Terraform configuration
- [ ] Test in non-production environment first
- [ ] Plan cutover window (if using fresh deployment)
- [ ] Execute migration
- [ ] Verify all resources working
- [ ] Update documentation and runbooks
- [ ] Delete old CloudFormation stack (if applicable)
- [ ] Update CI/CD pipelines

## Common Pitfalls

### Resource Recreation

Some changes force resource recreation:
- VPC CIDR changes
- Cluster name changes
- Task definition family changes

**Solution**: Plan carefully and use `terraform plan` to preview.

### State Drift

Terraform state can drift from reality if:
- Manual changes in AWS console
- Other tools modify resources

**Solution**: Use `terraform refresh` and avoid manual changes.

### Import Complexity

Importing existing resources is complex:
- Must import every resource individually
- Easy to miss resources
- State must match exactly

**Solution**: Use fresh deployment strategy instead.

## Getting Help

### Terraform Commands

```bash
terraform validate  # Check syntax
terraform plan      # Preview changes
terraform apply     # Apply changes
terraform destroy   # Delete all resources
terraform state list  # List resources in state
terraform state show  # Show resource details
```

### Debugging

```bash
TF_LOG=DEBUG terraform apply
```

### Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Language](https://www.terraform.io/language)
- [Terraform CLI](https://www.terraform.io/cli)

## Support

For migration assistance:
- Review [Terraform Setup Guide](terraform-setup.md)
- Check [Configuration Reference](configuration.md)
- Contact: dan@sibylline.group
