# Hypernym Architecture Documentation

## Overview

Hypernym API is deployed on AWS using either ECS Fargate or EKS (Kubernetes). Both deployment options follow AWS best practices for security, scalability, and cost optimization.

## Architecture Principles

- **Security First**: Private subnets, VPC endpoints, least privilege IAM
- **High Availability**: Multi-AZ deployment with auto-scaling
- **Internal Access Only**: No public endpoints, internal ALB only
- **Cost Optimized**: VPC endpoints eliminate NAT Gateway costs
- **Marketplace Ready**: Built-in AWS Marketplace metering integration

## Network Architecture

### VPC Design

```
VPC (10.0.0.0/16)
├── Private Subnet 1 (10.0.1.0/24) - AZ1
│   ├── ECS Tasks / EKS Nodes
│   └── Internal ALB (Multi-AZ)
└── Private Subnet 2 (10.0.2.0/24) - AZ2
    ├── ECS Tasks / EKS Nodes
    └── Internal ALB (Multi-AZ)
```

**Key Features:**
- No public subnets or internet gateways
- All resources in private subnets
- Cross-AZ deployment for high availability
- Internal ALB for load balancing

### VPC Endpoints

To avoid NAT Gateway costs while maintaining AWS service access:

| Service | Type | Purpose |
|---------|------|---------|
| ECR API | Interface | Container registry API calls |
| ECR DKR | Interface | Docker image pulls |
| S3 | Gateway | ECR layer storage |
| Secrets Manager | Interface | BYOP credential access (conditional) |
| CloudWatch Logs | Interface | Application logging |

**Benefits:**
- No internet egress charges
- No NAT Gateway costs (~$32/month savings)
- Better performance and security
- Private AWS service connectivity

### Network Flow

```
Client Request
    ↓
[VPC Peering / Transit Gateway / VPN]
    ↓
Internal ALB (Private Subnets)
    ↓
ECS Tasks / K8s Pods (Private Subnets)
    ↓
VPC Endpoints → AWS Services
```

## ECS Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────┐
│                    VPC                          │
│  ┌──────────────────────────────────────────┐  │
│  │         Internal ALB                     │  │
│  │  (10.0.1.0/24 + 10.0.2.0/24)            │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                                │
│  ┌──────────────┴───────────────────────────┐  │
│  │        ECS Fargate Service              │  │
│  │                                          │  │
│  │  ┌────────────┐      ┌────────────┐    │  │
│  │  │  Task 1    │      │  Task 2    │    │  │
│  │  │  (AZ1)     │      │  (AZ2)     │    │  │
│  │  └────────────┘      └────────────┘    │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │         VPC Endpoints                    │  │
│  │  - ECR  - S3  - Secrets  - Logs         │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### ECS Components

1. **ECS Cluster**: Container orchestration
2. **Task Definition**: Container specs, environment, IAM roles
3. **ECS Service**: Maintains desired task count, integrates with ALB
4. **Target Group**: Health checks and routing
5. **CloudWatch Logs**: Centralized logging

### Task Specifications

- **Launch Type**: Fargate (serverless)
- **CPU**: 512 units (0.5 vCPU) - configurable
- **Memory**: 1024 MB (1 GB) - configurable
- **Network Mode**: awsvpc (dedicated ENI per task)
- **Task Count**: 2 minimum (configurable)

## EKS Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────┐
│                    VPC                          │
│  ┌──────────────────────────────────────────┐  │
│  │    AWS Load Balancer Controller          │  │
│  │         Internal ALB                      │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                                │
│  ┌──────────────┴───────────────────────────┐  │
│  │        EKS Cluster                       │  │
│  │                                          │  │
│  │  ┌────────────┐      ┌────────────┐    │  │
│  │  │  Pod 1     │      │  Pod 2     │    │  │
│  │  │  (AZ1)     │      │  (AZ2)     │    │  │
│  │  └────────────┘      └────────────┘    │  │
│  │                                          │  │
│  │  Managed Node Group (t3.medium)         │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │         VPC Endpoints                    │  │
│  │  - ECR  - S3  - Secrets  - Logs         │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### EKS Components

1. **EKS Control Plane**: Managed Kubernetes control plane
2. **Managed Node Group**: EC2 instances for pod scheduling
3. **Kubernetes Deployment**: Pod replica management
4. **Kubernetes Service**: Internal service discovery
5. **Ingress**: ALB integration for external access
6. **HPA**: Horizontal Pod Autoscaler (2-10 replicas)

### Node Specifications

- **Instance Type**: t3.medium (default) - configurable
- **Min Nodes**: 2
- **Max Nodes**: 10
- **Desired Nodes**: 2
- **AMI**: EKS-optimized Amazon Linux 2

### Pod Specifications

- **Requests**: 250m CPU, 256Mi memory
- **Limits**: 500m CPU, 512Mi memory
- **Min Replicas**: 2
- **Max Replicas**: 10
- **Auto-scaling**: Based on CPU (70%) and memory (80%)

## Security Model

### Defense in Depth

1. **Network Layer**
   - Private subnets only
   - Security groups with least privilege
   - No internet gateway
   - VPC endpoints for AWS services

2. **IAM Layer**
   - Separate execution and task/pod roles
   - Least privilege policies
   - Conditional permissions based on mode
   - IRSA (IAM Roles for Service Accounts) for EKS

3. **Container Layer**
   - Non-root user (UID 1000)
   - Read-only root filesystem where possible
   - Dropped capabilities
   - Security scanning via ECR

### Security Groups

**ALB Security Group:**
```
Ingress:
- Port 80 from VPC CIDR (10.0.0.0/16)

Egress:
- Port 8000 to ECS Task Security Group
```

**ECS Task / EKS Node Security Group:**
```
Ingress:
- Port 8000 from ALB Security Group

Egress:
- Port 443 to VPC Endpoint Security Group
```

**VPC Endpoint Security Group:**
```
Ingress:
- Port 443 from VPC CIDR (10.0.0.0/16)
```

### IAM Roles and Permissions

#### ECS Task Execution Role

**Purpose**: Pull container images, write logs

**Permissions:**
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `logs:CreateLogStream`
- `logs:PutLogEvents`
- **Conditional** (BYOP): `secretsmanager:GetSecretValue`

#### ECS Task Role / EKS Pod Role

**Purpose**: Application runtime permissions

**Permissions:**
- `aws-marketplace:MeterUsage`
- `aws-marketplace:RegisterUsage`
- **Conditional** (BYOP): `secretsmanager:GetSecretValue`

**EKS Implementation:** Uses IRSA (IAM Roles for Service Accounts)
- Service account annotation: `eks.amazonaws.com/role-arn`
- OIDC provider for secure token exchange
- No node-level permissions required

## Inference Provider Modes

### Managed Mode

**Architecture:**
```
Hypernym Pod/Task
    ↓
MANAGED_API_URL (one-api endpoint)
    ↓
Managed Inference Service
```

**Configuration:**
- Environment variable: `INFERENCE_PROVIDER_MODE=managed`
- Environment variable: `MANAGED_API_URL=http://one-api-service:8080`
- No secrets required
- Managed billing and scaling

**Use Case:** Customers who want fully managed inference

### BYOP Mode (Bring Your Own Provider)

**Architecture:**
```
Hypernym Pod/Task
    ↓
AWS Secrets Manager (via VPC Endpoint)
    ↓
External Provider (OpenAI, Anthropic, etc.)
```

**Configuration:**
- Environment variable: `INFERENCE_PROVIDER_MODE=byop`
- Secrets Manager secret with:
  - `provider_url`: API endpoint
  - `api_key`: Authentication key
  - `model_name`: Model identifier
- IAM permissions for secret access

**Use Case:** Customers who want to use their own API keys and providers

### Mode Comparison

| Feature | Managed | BYOP |
|---------|---------|------|
| Setup Complexity | Low | Medium |
| Cost Model | Per-request via AWS Marketplace | Customer pays provider directly |
| Scaling | Automatic | Customer manages |
| Provider Choice | Predetermined | Any HTTP REST API |
| Secrets Management | Not required | Required |
| IAM Permissions | Marketplace only | Marketplace + Secrets Manager |

## Scaling and Performance

### Auto-Scaling

**ECS:**
- Service auto-scaling based on CPU/memory
- Target tracking policies
- Scale-out: 30 seconds
- Scale-in: 5 minutes (cooldown)

**EKS:**
- Horizontal Pod Autoscaler (HPA)
- Metrics: CPU utilization (70%), Memory utilization (80%)
- Scale-out: 30 seconds
- Scale-in: 5 minutes

### High Availability

- Multi-AZ deployment (minimum 2 AZs)
- Minimum 2 tasks/pods
- Health checks every 30 seconds
- Unhealthy threshold: 3 consecutive failures
- Automatic task/pod replacement

### Resource Limits

**Default Configuration:**
- Minimum replicas: 2
- Maximum replicas: 10
- CPU per task/pod: 250m-500m
- Memory per task/pod: 256Mi-512Mi

**Scaling Capacity:**
- Can handle ~100-500 requests/second (depends on workload)
- ~20-100 concurrent users per task/pod
- Adjust based on load testing

## Cost Considerations

### ECS Costs

- Fargate: $0.04048/vCPU/hour + $0.004445/GB/hour
- ALB: $0.0225/hour + $0.008/LCU-hour
- VPC Endpoints: $0.01/hour/endpoint
- Data transfer: $0.01/GB within VPC (minimal)

**Example (us-east-1, 2 tasks, 0.5 vCPU, 1GB each):**
- Fargate: ~$30/month
- ALB: ~$20/month
- VPC Endpoints (5): ~$36/month
- **Total: ~$86/month**

### EKS Costs

- EKS Cluster: $0.10/hour ($73/month)
- EC2 Nodes: 2× t3.medium = $0.0416/hour each
- ALB: $0.0225/hour + $0.008/LCU-hour
- VPC Endpoints: $0.01/hour/endpoint

**Example (us-east-1, 2 nodes t3.medium):**
- EKS Cluster: ~$73/month
- EC2 Nodes: ~$61/month
- ALB: ~$20/month
- VPC Endpoints (5): ~$36/month
- **Total: ~$190/month**

### Cost Optimization Tips

1. Use Savings Plans or Reserved Instances for EC2 nodes
2. Right-size task/pod resources after load testing
3. Adjust auto-scaling thresholds to match workload patterns
4. Use single NAT Gateway if internet access is required (not included by default)
5. Enable S3 VPC Gateway endpoint (free) instead of Interface endpoint

## Monitoring and Observability

### CloudWatch Metrics

**ECS:**
- `CPUUtilization`
- `MemoryUtilization`
- `TargetResponseTime`
- `HealthyHostCount`
- `RequestCount`

**EKS:**
- Container Insights for pod-level metrics
- Node CPU/Memory utilization
- Pod CPU/Memory utilization
- HPA metrics

### Logging

**ECS:**
- CloudWatch Logs: `/ecs/<stack-name>`
- Retention: 30 days
- Log streams per task

**EKS:**
- CloudWatch Logs: `/aws/eks/<cluster-name>/cluster`
- Control plane logs (api, audit, authenticator, etc.)
- Container logs via FluentBit or CloudWatch agent

### Health Checks

- **Endpoint**: `/health`
- **Expected Response**: HTTP 200
- **Response Body**: `{"status": "healthy", "version": "x.y.z"}`
- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Healthy Threshold**: 2 consecutive successes
- **Unhealthy Threshold**: 3 consecutive failures

## Disaster Recovery

### Backup Strategy

- **Infrastructure as Code**: All resources defined in CloudFormation/Helm
- **Container Images**: Stored in ECR with lifecycle policies
- **Secrets**: Backed up via Secrets Manager (automatic)
- **Configuration**: Parameter files stored in version control

### Recovery Procedures

**Complete Stack Loss:**
1. Deploy CloudFormation stack from template
2. Deploy Helm chart from repository
3. Verify health checks
4. Update DNS/routing if needed

**RTO (Recovery Time Objective):** 15-30 minutes
**RPO (Recovery Point Objective):** Near-zero (stateless application)

### Multi-Region Considerations

For multi-region deployment:
1. Replicate ECR images to target regions
2. Copy Secrets Manager secrets to target regions
3. Deploy CloudFormation stacks in each region
4. Use Route53 for DNS failover
5. Consider Global Accelerator for optimal routing

## Compliance and Governance

### Tagging Strategy

All resources tagged with:
- `Name`: Resource identifier
- `ManagedBy`: CloudFormation/Helm
- `Product`: Hypernym
- `Environment`: Derived from stack name

### AWS Well-Architected Framework

| Pillar | Implementation |
|--------|---------------|
| **Operational Excellence** | IaC, CloudWatch monitoring, automated deployments |
| **Security** | Least privilege IAM, private subnets, VPC endpoints, encryption at rest |
| **Reliability** | Multi-AZ, auto-scaling, health checks, automated recovery |
| **Performance Efficiency** | Right-sized resources, auto-scaling, VPC endpoints |
| **Cost Optimization** | VPC endpoints (no NAT), right-sizing, auto-scaling |
| **Sustainability** | Serverless Fargate option, efficient resource usage |

## Next Steps

- [Deployment Guide](deployment-guide.md): Step-by-step deployment instructions
- [Parameters Reference](parameters.md): Complete parameter documentation
- [Troubleshooting](troubleshooting.md): Common issues and solutions
