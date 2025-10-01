# Parameters Reference

Complete reference for all configuration parameters used in Hypernym deployments.

## ECS CloudFormation Parameters

### Container Configuration

#### ContainerImage
- **Type**: String
- **Required**: Yes
- **Default**: `<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<TODO_REPOSITORY_NAME>:latest`
- **Description**: Full URI of the container image in ECR
- **Example**: `123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:v1.0.0`
- **TODO**: Update with actual ECR repository URL

#### MarketplaceProductCode
- **Type**: String
- **Required**: Yes
- **Default**: `TODO-marketplace-product-code`
- **Description**: AWS Marketplace product code for metering
- **Example**: `abc123xyz456`
- **TODO**: Replace with actual product code from AWS Marketplace listing

### Inference Provider Configuration

#### InferenceProviderMode
- **Type**: String
- **Required**: Yes
- **Default**: `managed`
- **Allowed Values**: `managed`, `byop`
- **Description**: Determines which inference backend to use
  - `managed`: Uses internal one-api service
  - `byop`: Uses customer-provided inference API
- **Example**: `managed`

#### ManagedAPIURL
- **Type**: String
- **Required**: Only if `InferenceProviderMode=managed`
- **Default**: `http://one-api-service:8080`
- **Description**: URL of the internal managed inference API endpoint
- **Example**: `http://one-api-service:8080`
- **TODO**: Update with actual one-api endpoint when available

#### SecretsManagerSecretARN
- **Type**: String
- **Required**: Only if `InferenceProviderMode=byop`
- **Default**: Empty string
- **Description**: ARN of AWS Secrets Manager secret containing BYOP credentials
- **Format**: `arn:aws:secretsmanager:<REGION>:<ACCOUNT>:secret:<NAME>-<SUFFIX>`
- **Example**: `arn:aws:secretsmanager:us-east-1:123456789012:secret:hypernym-byop-abc123`
- **Secret Structure**:
  ```json
  {
    "provider_url": "https://api.openai.com/v1",
    "api_key": "sk-proj-...",
    "model_name": "gpt-4-turbo"
  }
  ```

### Network Configuration

#### VpcCIDR
- **Type**: String
- **Required**: Yes
- **Default**: `10.0.0.0/16`
- **Description**: CIDR block for the VPC
- **Pattern**: Valid IPv4 CIDR (e.g., `10.0.0.0/16`)
- **Constraints**: Must be a valid CIDR block between /16 and /28
- **Example**: `10.0.0.0/16`

#### PrivateSubnet1CIDR
- **Type**: String
- **Required**: Yes
- **Default**: `10.0.1.0/24`
- **Description**: CIDR block for private subnet in first availability zone
- **Pattern**: Valid IPv4 CIDR
- **Constraints**: Must be within VPC CIDR range
- **Example**: `10.0.1.0/24`

#### PrivateSubnet2CIDR
- **Type**: String
- **Required**: Yes
- **Default**: `10.0.2.0/24`
- **Description**: CIDR block for private subnet in second availability zone
- **Pattern**: Valid IPv4 CIDR
- **Constraints**: Must be within VPC CIDR range and not overlap with Subnet1
- **Example**: `10.0.2.0/24`

### ECS Configuration

#### ClusterName
- **Type**: String
- **Required**: Yes
- **Default**: `hypernym-cluster`
- **Description**: Name for the ECS cluster
- **Constraints**: Alphanumeric and hyphens only
- **Example**: `hypernym-production-cluster`

#### ServiceName
- **Type**: String
- **Required**: Yes
- **Default**: `hypernym-api`
- **Description**: Name for the ECS service
- **Constraints**: Alphanumeric and hyphens only
- **Example**: `hypernym-api-service`

#### TaskCPU
- **Type**: String
- **Required**: Yes
- **Default**: `512`
- **Allowed Values**: `256`, `512`, `1024`, `2048`, `4096`
- **Description**: CPU units for the Fargate task (256 = 0.25 vCPU)
- **Constraints**: Must be compatible with TaskMemory
- **Example**: `512` (0.5 vCPU)

**CPU-Memory Compatibility:**

| CPU (vCPU) | Memory (GB) |
|-----------|-------------|
| 256 (.25) | 0.5, 1, 2 |
| 512 (.5) | 1, 2, 3, 4 |
| 1024 (1) | 2, 3, 4, 5, 6, 7, 8 |
| 2048 (2) | 4-16 (1 GB increments) |
| 4096 (4) | 8-30 (1 GB increments) |

#### TaskMemory
- **Type**: String
- **Required**: Yes
- **Default**: `1024`
- **Allowed Values**: `512`, `1024`, `2048`, `3072`, `4096`, `8192`
- **Description**: Memory for the Fargate task in megabytes
- **Constraints**: Must be compatible with TaskCPU
- **Example**: `1024` (1 GB)

#### DesiredCount
- **Type**: Number
- **Required**: Yes
- **Default**: `2`
- **Min**: `1`
- **Max**: `10`
- **Description**: Number of tasks to run
- **Recommendation**: Minimum 2 for high availability
- **Example**: `2`

## EKS CloudFormation Parameters

### Cluster Configuration

#### ClusterName
- **Type**: String
- **Required**: Yes
- **Default**: `hypernym-cluster`
- **Description**: Name for the EKS cluster
- **Constraints**: Alphanumeric, hyphens, max 100 characters
- **Example**: `hypernym-eks-cluster`

#### KubernetesVersion
- **Type**: String
- **Required**: Yes
- **Default**: `1.31`
- **Allowed Values**: `1.31`, `1.30`, `1.29`
- **Description**: Kubernetes version for the cluster
- **Recommendation**: Use latest stable version
- **Example**: `1.31`

### Network Configuration

Network parameters are identical to ECS (VpcCIDR, PrivateSubnet1CIDR, PrivateSubnet2CIDR).

### Node Group Configuration

#### NodeInstanceType
- **Type**: String
- **Required**: Yes
- **Default**: `t3.medium`
- **Allowed Values**: `t3.medium`, `t3.large`, `t3.xlarge`, `m5.large`, `m5.xlarge`
- **Description**: EC2 instance type for worker nodes
- **Specifications**:
  - `t3.medium`: 2 vCPU, 4 GB RAM
  - `t3.large`: 2 vCPU, 8 GB RAM
  - `t3.xlarge`: 4 vCPU, 16 GB RAM
  - `m5.large`: 2 vCPU, 8 GB RAM
  - `m5.xlarge`: 4 vCPU, 16 GB RAM
- **Example**: `t3.medium`

#### MinNodes
- **Type**: Number
- **Required**: Yes
- **Default**: `2`
- **Min**: `1`
- **Description**: Minimum number of worker nodes
- **Recommendation**: At least 2 for high availability
- **Example**: `2`

#### MaxNodes
- **Type**: Number
- **Required**: Yes
- **Default**: `10`
- **Min**: `1`
- **Description**: Maximum number of worker nodes
- **Recommendation**: Set based on expected peak load
- **Example**: `10`

#### DesiredNodes
- **Type**: Number
- **Required**: Yes
- **Default**: `2`
- **Min**: `1`
- **Description**: Initial desired number of worker nodes
- **Constraints**: Must be between MinNodes and MaxNodes
- **Example**: `2`

### Application Configuration

#### Namespace
- **Type**: String
- **Required**: Yes
- **Default**: `hypernym`
- **Description**: Kubernetes namespace for application resources
- **Example**: `hypernym`

#### ServiceAccountName
- **Type**: String
- **Required**: Yes
- **Default**: `hypernym-api`
- **Description**: Name of Kubernetes service account (used for IRSA)
- **Example**: `hypernym-api`

#### MarketplaceProductCode
- Same as ECS parameter

#### InferenceProviderMode
- Same as ECS parameter

#### SecretsManagerSecretARN
- Same as ECS parameter

## Helm Values Reference

### Image Configuration

#### image.repository
- **Type**: String
- **Required**: Yes
- **Default**: `<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<TODO_REPOSITORY_NAME>`
- **Description**: Container image repository URL (without tag)
- **Example**: `123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym`

#### image.tag
- **Type**: String
- **Required**: Yes
- **Default**: `latest`
- **Description**: Container image tag
- **Recommendation**: Use semantic versioning (e.g., `v1.0.0`)
- **Example**: `v1.0.0`

#### image.pullPolicy
- **Type**: String
- **Required**: No
- **Default**: `IfNotPresent`
- **Allowed Values**: `Always`, `IfNotPresent`, `Never`
- **Description**: Image pull policy
- **Example**: `IfNotPresent`

### Inference Provider Configuration

#### inferenceProviderMode
- **Type**: String
- **Required**: Yes
- **Default**: `managed`
- **Allowed Values**: `managed`, `byop`
- **Description**: Inference provider mode
- **Example**: `managed`

#### managed.apiUrl
- **Type**: String
- **Required**: If mode is `managed`
- **Default**: `http://one-api-service:8080`
- **Description**: Managed inference API endpoint
- **Example**: `http://one-api-service:8080`

#### byop.secretName
- **Type**: String
- **Required**: If mode is `byop`
- **Default**: `hypernym-byop-credentials`
- **Description**: Kubernetes secret name containing BYOP credentials
- **Example**: `hypernym-byop-credentials`

#### byop.secretKeys.*
- **Type**: Object
- **Description**: Keys in the Kubernetes secret
- **Fields**:
  - `providerUrl`: Key for provider URL (default: `provider_url`)
  - `apiKey`: Key for API key (default: `api_key`)
  - `modelName`: Key for model name (default: `model_name`)

### Service Account Configuration

#### serviceAccount.create
- **Type**: Boolean
- **Required**: No
- **Default**: `true`
- **Description**: Whether to create service account
- **Example**: `true`

#### serviceAccount.annotations
- **Type**: Object
- **Required**: For IRSA
- **Default**: `{}`
- **Description**: Annotations for service account (IRSA role ARN)
- **Example**:
  ```yaml
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/hypernym-pod-role"
  ```

#### serviceAccount.name
- **Type**: String
- **Required**: No
- **Default**: `hypernym-api`
- **Description**: Service account name
- **Example**: `hypernym-api`

### Deployment Configuration

#### replicaCount
- **Type**: Number
- **Required**: No
- **Default**: `2`
- **Description**: Number of pod replicas (if autoscaling disabled)
- **Example**: `2`

#### container.port
- **Type**: Number
- **Required**: No
- **Default**: `8000`
- **Description**: Container port
- **Example**: `8000`

#### container.environment
- **Type**: String
- **Required**: No
- **Default**: `production`
- **Description**: Application environment
- **Example**: `production`

#### container.logLevel
- **Type**: String
- **Required**: No
- **Default**: `info`
- **Allowed Values**: `debug`, `info`, `warning`, `error`
- **Description**: Application log level
- **Example**: `info`

#### container.workers
- **Type**: Number
- **Required**: No
- **Default**: `1`
- **Description**: Number of worker processes
- **Example**: `1`

### Service Configuration

#### service.type
- **Type**: String
- **Required**: No
- **Default**: `ClusterIP`
- **Allowed Values**: `ClusterIP`, `NodePort`, `LoadBalancer`
- **Description**: Kubernetes service type
- **Example**: `ClusterIP`

#### service.port
- **Type**: Number
- **Required**: No
- **Default**: `80`
- **Description**: Service port
- **Example**: `80`

#### service.targetPort
- **Type**: Number
- **Required**: No
- **Default**: `8000`
- **Description**: Target container port
- **Example**: `8000`

### Ingress Configuration

#### ingress.enabled
- **Type**: Boolean
- **Required**: No
- **Default**: `true`
- **Description**: Whether to create Ingress resource
- **Example**: `true`

#### ingress.className
- **Type**: String
- **Required**: No
- **Default**: `alb`
- **Description**: Ingress class name (AWS Load Balancer Controller)
- **Example**: `alb`

#### ingress.annotations
- **Type**: Object
- **Required**: No
- **Default**: Internal ALB configuration
- **Description**: Ingress annotations for ALB configuration
- **Key Annotations**:
  - `alb.ingress.kubernetes.io/scheme`: `internal` (internal ALB)
  - `alb.ingress.kubernetes.io/target-type`: `ip` (for Fargate/ENI)
  - `alb.ingress.kubernetes.io/healthcheck-path`: `/health`

### Resource Configuration

#### resources.requests.*
- **Type**: Object
- **Required**: No
- **Default**: `memory: "256Mi"`, `cpu: "250m"`
- **Description**: Minimum resources guaranteed
- **Example**:
  ```yaml
  requests:
    memory: "256Mi"
    cpu: "250m"
  ```

#### resources.limits.*
- **Type**: Object
- **Required**: No
- **Default**: `memory: "512Mi"`, `cpu: "500m"`
- **Description**: Maximum resources allowed
- **Example**:
  ```yaml
  limits:
    memory: "512Mi"
    cpu: "500m"
  ```

### Autoscaling Configuration

#### autoscaling.enabled
- **Type**: Boolean
- **Required**: No
- **Default**: `true`
- **Description**: Enable Horizontal Pod Autoscaler
- **Example**: `true`

#### autoscaling.minReplicas
- **Type**: Number
- **Required**: No
- **Default**: `2`
- **Description**: Minimum number of replicas
- **Example**: `2`

#### autoscaling.maxReplicas
- **Type**: Number
- **Required**: No
- **Default**: `10`
- **Description**: Maximum number of replicas
- **Example**: `10`

#### autoscaling.targetCPUUtilizationPercentage
- **Type**: Number
- **Required**: No
- **Default**: `70`
- **Description**: Target CPU utilization for scaling
- **Range**: 1-100
- **Example**: `70`

#### autoscaling.targetMemoryUtilizationPercentage
- **Type**: Number
- **Required**: No
- **Default**: `80`
- **Description**: Target memory utilization for scaling
- **Range**: 1-100
- **Example**: `80`

### Health Probes

#### livenessProbe.*
- **Type**: Object
- **Description**: Liveness probe configuration
- **Default**:
  ```yaml
  livenessProbe:
    httpGet:
      path: /health
      port: 8000
    initialDelaySeconds: 30
    periodSeconds: 30
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 3
  ```

#### readinessProbe.*
- **Type**: Object
- **Description**: Readiness probe configuration
- **Default**:
  ```yaml
  readinessProbe:
    httpGet:
      path: /health
      port: 8000
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 3
  ```

### Security Configuration

#### podSecurityContext.*
- **Type**: Object
- **Description**: Pod-level security context
- **Default**:
  ```yaml
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
  ```

#### securityContext.*
- **Type**: Object
- **Description**: Container-level security context
- **Default**:
  ```yaml
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: false
  ```

## Parameter Selection Guidelines

### Choosing Task/Pod Resources

**Light Workload (< 10 req/sec):**
- ECS: CPU 256, Memory 512
- EKS: Requests 128m/256Mi, Limits 256m/512Mi

**Medium Workload (10-100 req/sec):**
- ECS: CPU 512, Memory 1024 (default)
- EKS: Requests 250m/256Mi, Limits 500m/512Mi (default)

**Heavy Workload (> 100 req/sec):**
- ECS: CPU 1024-2048, Memory 2048-4096
- EKS: Requests 500m/1Gi, Limits 1000m/2Gi

### Choosing Instance Types (EKS)

**Development/Testing:**
- t3.medium (2 vCPU, 4 GB)

**Production (Low Traffic):**
- t3.large (2 vCPU, 8 GB)

**Production (High Traffic):**
- m5.xlarge (4 vCPU, 16 GB)

### Choosing Scaling Parameters

**Conservative Scaling:**
- Min: 2, Max: 5, Target CPU: 80%

**Balanced Scaling (recommended):**
- Min: 2, Max: 10, Target CPU: 70%

**Aggressive Scaling:**
- Min: 3, Max: 20, Target CPU: 60%

## Next Steps

- [Deployment Guide](deployment-guide.md): Use these parameters in deployments
- [Architecture](architecture.md): Understand how parameters affect architecture
- [Troubleshooting](troubleshooting.md): Debug parameter-related issues
