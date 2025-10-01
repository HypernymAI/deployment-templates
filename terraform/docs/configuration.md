# Configuration Reference

Complete reference for all Terraform variables and configuration options.

## Required Variables

### container_image
- **Type:** `string`
- **Description:** Full URI of container image in ECR
- **Example:** `123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest`
- **Required:** Yes

### product_code
- **Type:** `string`
- **Description:** AWS Marketplace product code for metering
- **Example:** `abc123xyz456`
- **Required:** Yes

### deployment_target
- **Type:** `string`
- **Description:** Deployment platform
- **Allowed Values:** `ecs`, `eks`
- **Required:** Yes

## Inference Provider Configuration

### inference_provider_mode
- **Type:** `string`
- **Default:** `managed`
- **Allowed Values:** `managed`, `byop`
- **Description:** Inference provider mode
  - `managed`: Use Sibylline's managed service
  - `byop`: Use your own inference provider

### managed_api_url
- **Type:** `string`
- **Default:** `http://one-api-service:8080`
- **Description:** URL for managed inference API
- **Required:** Only when `inference_provider_mode = "managed"`

### byop_secret_arn
- **Type:** `string`
- **Default:** `""`
- **Sensitive:** Yes
- **Description:** ARN of Secrets Manager secret with BYOP credentials
- **Required:** Only when `inference_provider_mode = "byop"`
- **Secret Format:**
  ```json
  {
    "provider_url": "https://api.openai.com/v1",
    "api_key": "sk-proj-...",
    "model_name": "gpt-4-turbo"
  }
  ```

## Network Configuration

### vpc_cidr
- **Type:** `string`
- **Default:** `10.0.0.0/16`
- **Description:** CIDR block for VPC
- **Validation:** Must be valid CIDR notation
- **Example:** `10.0.0.0/16`, `172.16.0.0/16`

### private_subnet_cidrs
- **Type:** `list(string)`
- **Default:** `["10.0.1.0/24", "10.0.2.0/24"]`
- **Description:** CIDR blocks for private subnets (must be within VPC CIDR)
- **Constraints:** Minimum 2 subnets for high availability

## ECS Configuration

### task_cpu
- **Type:** `string`
- **Default:** `512`
- **Allowed Values:** `256`, `512`, `1024`, `2048`, `4096`
- **Description:** CPU units for ECS task (1024 = 1 vCPU)

### task_memory
- **Type:** `string`
- **Default:** `1024`
- **Description:** Memory for ECS task in MB
- **Valid Combinations:**
  | CPU | Valid Memory Values |
  |-----|---------------------|
  | 256 | 512, 1024, 2048 |
  | 512 | 1024, 2048, 3072, 4096 |
  | 1024 | 2048-8192 (1GB increments) |
  | 2048 | 4096-16384 (1GB increments) |
  | 4096 | 8192-30720 (1GB increments) |

## EKS Configuration

### eks_node_instance_type
- **Type:** `string`
- **Default:** `t3.medium`
- **Description:** EC2 instance type for EKS nodes
- **Recommended:** `t3.medium`, `t3.large`, `m5.large`

### eks_node_min_size
- **Type:** `number`
- **Default:** `2`
- **Description:** Minimum number of EKS nodes
- **Minimum:** 2 (for high availability)

### eks_node_max_size
- **Type:** `number`
- **Default:** `4`
- **Description:** Maximum number of EKS nodes

### eks_node_desired_size
- **Type:** `number`
- **Default:** `2`
- **Description:** Desired number of EKS nodes
- **Constraints:** Must be between `eks_node_min_size` and `eks_node_max_size`

## Scaling Configuration

### desired_count
- **Type:** `number`
- **Default:** `2`
- **Description:** Initial number of tasks/pods
- **Minimum:** 2 (recommended for HA)

### min_capacity
- **Type:** `number`
- **Default:** `2`
- **Description:** Minimum tasks/pods for auto-scaling
- **Minimum:** 1

### max_capacity
- **Type:** `number`
- **Default:** `10`
- **Description:** Maximum tasks/pods for auto-scaling

## Application Configuration

### container_port
- **Type:** `number`
- **Default:** `8000`
- **Description:** Port exposed by the container

### log_level
- **Type:** `string`
- **Default:** `info`
- **Allowed Values:** `debug`, `info`, `warning`, `error`
- **Description:** Application log level

### environment
- **Type:** `string`
- **Default:** `production`
- **Description:** Environment name passed to application

### project_name
- **Type:** `string`
- **Default:** `hypernym`
- **Description:** Project name used for resource naming
- **Note:** Affects resource names like `{project_name}-cluster`

## Regional Configuration

### aws_region
- **Type:** `string`
- **Default:** `us-east-1`
- **Description:** AWS region for deployment
- **Common Values:** `us-east-1`, `us-west-2`, `eu-west-1`

## Tagging

### tags
- **Type:** `map(string)`
- **Default:** `{}`
- **Description:** Additional tags for all resources
- **Example:**
  ```hcl
  tags = {
    Environment = "production"
    Team        = "platform"
    CostCenter  = "engineering"
    Owner       = "john.doe@example.com"
  }
  ```

## Auto-Generated Tags

The module automatically adds these tags:
- `Project`: Value of `project_name`
- `ManagedBy`: "Terraform"
- `DeploymentTarget`: Value of `deployment_target`
- `InferenceProvider`: Value of `inference_provider_mode`

## Configuration Examples

### Minimal ECS Managed

```hcl
deployment_target       = "ecs"
container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
product_code            = "abc123xyz456"
inference_provider_mode = "managed"
```

### Production ECS BYOP

```hcl
deployment_target       = "ecs"
container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
product_code            = "abc123xyz456"
inference_provider_mode = "byop"
byop_secret_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:hypernym-byop-abc123"

task_cpu     = "1024"
task_memory  = "2048"
desired_count = 4
max_capacity = 20

tags = {
  Environment = "production"
  Compliance  = "hipaa"
}
```

### High-Scale EKS Managed

```hcl
deployment_target       = "eks"
container_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:latest"
product_code            = "abc123xyz456"
inference_provider_mode = "managed"

eks_node_instance_type = "m5.large"
eks_node_min_size      = 3
eks_node_max_size      = 10
eks_node_desired_size  = 3

desired_count = 6
min_capacity  = 6
max_capacity  = 30
```

### Custom Network Configuration

```hcl
vpc_cidr             = "172.16.0.0/16"
private_subnet_cidrs = [
  "172.16.10.0/24",
  "172.16.20.0/24",
  "172.16.30.0/24"
]
```

## Variable Validation

The module includes validation for:

- **deployment_target**: Must be `ecs` or `eks`
- **inference_provider_mode**: Must be `managed` or `byop`
- **vpc_cidr**: Must be valid CIDR notation
- **byop_secret_arn**: Required when `inference_provider_mode = "byop"`

## Environment-Specific Configurations

### Development

```hcl
environment   = "development"
desired_count = 1
min_capacity  = 1
max_capacity  = 2
task_cpu      = "256"
task_memory   = "512"
log_level     = "debug"
```

### Staging

```hcl
environment   = "staging"
desired_count = 2
min_capacity  = 2
max_capacity  = 5
task_cpu      = "512"
task_memory   = "1024"
log_level     = "info"
```

### Production

```hcl
environment   = "production"
desired_count = 4
min_capacity  = 4
max_capacity  = 20
task_cpu      = "1024"
task_memory   = "2048"
log_level     = "warning"
```

## Security Considerations

### Sensitive Variables

These variables are marked sensitive:
- `byop_secret_arn`

They will not appear in logs or console output.

### Secret Management

**BYOP Mode:**
- Always use AWS Secrets Manager
- Never hardcode credentials
- Rotate API keys regularly
- Use IAM policies to restrict secret access

### Network Security

- VPC is fully private (no internet gateway)
- ALB is internal only
- Security groups follow least privilege
- VPC endpoints for AWS service access

## Cost Optimization

### Development/Testing

```hcl
task_cpu               = "256"
task_memory            = "512"
desired_count          = 1
eks_node_instance_type = "t3.small"
eks_node_min_size      = 1
```

### Production with Cost Controls

```hcl
task_cpu      = "512"
task_memory   = "1024"
desired_count = 2
max_capacity  = 10

eks_node_instance_type = "t3.medium"
eks_node_max_size      = 4
```

## Performance Tuning

### High Throughput

```hcl
task_cpu      = "2048"
task_memory   = "4096"
desired_count = 10
max_capacity  = 50

eks_node_instance_type = "m5.xlarge"
```

### Low Latency

```hcl
desired_count = 8
min_capacity  = 8

eks_node_instance_type = "c5.large"
```

## Outputs Reference

The module provides these outputs:

- `vpc_id`: VPC ID
- `private_subnet_ids`: List of private subnet IDs
- `load_balancer_dns`: ALB DNS name
- `load_balancer_url`: Full ALB URL with http://
- `security_group_id`: Application security group ID
- `iam_role_arn`: Application IAM role ARN
- `ecs_cluster_name`: ECS cluster name (ECS only)
- `ecs_service_name`: ECS service name (ECS only)
- `eks_cluster_name`: EKS cluster name (EKS only)
- `eks_cluster_endpoint`: EKS API endpoint (EKS only)
