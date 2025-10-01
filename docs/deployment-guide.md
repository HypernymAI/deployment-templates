# Hypernym Deployment Guide

Complete guide for deploying Hypernym API on AWS using ECS Fargate or EKS.

## Table of Contents

- [Prerequisites](#prerequisites)
- [ECS Fargate Deployment](#ecs-fargate-deployment)
- [EKS Deployment](#eks-deployment)
- [BYOP Mode Setup](#byop-mode-setup)
- [Post-Deployment Configuration](#post-deployment-configuration)
- [Verification](#verification)

## Prerequisites

### Required Tools

- AWS CLI v2.x or later
- For ECS: AWS CloudFormation access
- For EKS: kubectl and Helm 3.x

### AWS Permissions

Required IAM permissions:
- CloudFormation: Full access
- ECS/EKS: Full access
- EC2: VPC and subnet management
- IAM: Role and policy management
- Secrets Manager: Read/write (for BYOP mode)
- CloudWatch Logs: Create log groups

### Configuration Checklist

Before deploying, prepare:

1. **Container Image URI**: Update from ECR repository
   - Format: `<account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:<tag>`
   - TODO: Replace placeholder in parameter files

2. **Marketplace Product Code**: Obtain from AWS Marketplace listing
   - TODO: Replace placeholder in parameter files

3. **For BYOP Mode**: Create Secrets Manager secret with provider credentials

4. **For Managed Mode**: Configure internal one-api endpoint URL

## ECS Fargate Deployment

### Step 1: Prepare Parameters

Copy the appropriate example file:

```bash
cp examples/ecs-managed-params.json my-params.json
```

Edit `my-params.json` and update:
- `ContainerImage`: Your ECR image URI
- `MarketplaceProductCode`: Your product code
- `ManagedAPIURL`: Your one-api endpoint (managed mode)
- Or `SecretsManagerSecretARN`: Your secret ARN (BYOP mode)

### Step 2: Deploy Stack

```bash
aws cloudformation create-stack \
  --stack-name hypernym-ecs \
  --template-body file://cloudformation/ecs-fargate.yaml \
  --parameters file://my-params.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Step 3: Monitor Deployment

```bash
aws cloudformation wait stack-create-complete \
  --stack-name hypernym-ecs \
  --region us-east-1
```

This typically takes 10-15 minutes.

### Step 4: Get Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name hypernym-ecs \
  --query 'Stacks[0].Outputs' \
  --region us-east-1
```

Save the `LoadBalancerURL` value for accessing the service.

## EKS Deployment

### Step 1: Deploy EKS Infrastructure

```bash
cp examples/eks-managed-values.yaml my-values.yaml
```

Deploy the CloudFormation stack:

```bash
aws cloudformation create-stack \
  --stack-name hypernym-eks \
  --template-body file://cloudformation/eks.yaml \
  --parameters \
    ParameterKey=ClusterName,ParameterValue=hypernym-cluster \
    ParameterKey=MarketplaceProductCode,ParameterValue=YOUR-PRODUCT-CODE \
    ParameterKey=InferenceProviderMode,ParameterValue=managed \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

Wait for completion (15-20 minutes):

```bash
aws cloudformation wait stack-create-complete \
  --stack-name hypernym-eks \
  --region us-east-1
```

### Step 2: Configure kubectl

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name hypernym-cluster
```

Verify connection:

```bash
kubectl get nodes
```

### Step 3: Install AWS Load Balancer Controller

Required for internal ALB creation:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=hypernym-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Step 4: Create Namespace

```bash
kubectl create namespace hypernym
```

### Step 5: Update Helm Values

Edit `my-values.yaml`:

1. Get the Pod Role ARN from CloudFormation outputs:
```bash
aws cloudformation describe-stacks \
  --stack-name hypernym-eks \
  --query 'Stacks[0].Outputs[?OutputKey==`PodRoleArn`].OutputValue' \
  --output text
```

2. Update the ServiceAccount annotation with the ARN:
```yaml
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/hypernym-eks-pod-role"
```

3. Update image repository and tag
4. Update marketplace product code

### Step 6: Deploy with Helm

```bash
helm install hypernym ./helm/hypernym \
  --namespace hypernym \
  --values my-values.yaml
```

### Step 7: Monitor Deployment

```bash
kubectl get pods -n hypernym -w
```

Wait for all pods to reach `Running` status.

### Step 8: Get Load Balancer URL

```bash
kubectl get ingress -n hypernym
```

The ALB DNS name will appear in the ADDRESS column (may take 2-3 minutes).

## BYOP Mode Setup

### Step 1: Create Secrets Manager Secret

Use the template from `examples/byop-secret-template.json`:

```json
{
  "provider_url": "https://api.openai.com/v1",
  "api_key": "sk-proj-your-api-key-here",
  "model_name": "gpt-4-turbo"
}
```

Create the secret:

```bash
aws secretsmanager create-secret \
  --name hypernym-byop-credentials \
  --secret-string file://byop-secret-template.json \
  --region us-east-1
```

Save the ARN from the output.

### Step 2: For ECS

Use `examples/ecs-byop-params.json` and update:
- `InferenceProviderMode`: Set to `byop`
- `SecretsManagerSecretARN`: Use the ARN from Step 1

### Step 3: For EKS

1. Create Kubernetes secret from AWS Secrets Manager:

```bash
kubectl create secret generic hypernym-byop-credentials \
  --from-literal=provider_url="https://api.openai.com/v1" \
  --from-literal=api_key="sk-proj-your-key" \
  --from-literal=model_name="gpt-4-turbo" \
  --namespace hypernym
```

2. Use `examples/eks-byop-values.yaml` and update:
- `inferenceProviderMode`: Set to `byop`
- `byop.secretName`: `hypernym-byop-credentials`

## Post-Deployment Configuration

### Accessing the Service

The service is deployed with an **internal ALB** (not publicly accessible).

To access from your network:

1. **VPC Peering**: Set up VPC peering to the Hypernym VPC
2. **Transit Gateway**: Connect via AWS Transit Gateway
3. **VPN**: Establish VPN connection to the VPC
4. **Bastion Host**: Deploy a bastion in the same VPC

### Testing from EC2 Instance

Deploy a test EC2 instance in the same VPC:

```bash
LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
  --stack-name hypernym-ecs \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text)

curl http://${LOAD_BALANCER_URL}/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "0.2.1",
  "environment": "production"
}
```

### Scaling Configuration

**ECS**: Modify desired count in CloudFormation parameters and update stack.

**EKS**: Update autoscaling configuration:

```bash
kubectl edit hpa -n hypernym
```

Or update `my-values.yaml` and upgrade:

```bash
helm upgrade hypernym ./helm/hypernym \
  --namespace hypernym \
  --values my-values.yaml
```

## Verification

### Health Check

```bash
curl http://<LOAD_BALANCER_URL>/health
```

### View Logs

**ECS**:
```bash
aws logs tail /ecs/hypernym-ecs --follow
```

**EKS**:
```bash
kubectl logs -f -n hypernym -l app.kubernetes.io/name=hypernym
```

### Check IAM Permissions

Verify marketplace metering permissions:

**ECS**:
```bash
aws cloudformation describe-stack-resource \
  --stack-name hypernym-ecs \
  --logical-resource-id TaskRole
```

**EKS**:
```bash
kubectl describe serviceaccount hypernym-api -n hypernym
```

Should show the IRSA annotation with the pod role ARN.

### Verify Secrets Access (BYOP Mode)

Check that the application can access secrets:

**ECS**: View task logs for any secret access errors

**EKS**:
```bash
kubectl exec -it -n hypernym <pod-name> -- env | grep UPSTREAM
```

Should show the environment variables populated from secrets.

## Common Issues

See [troubleshooting.md](troubleshooting.md) for detailed troubleshooting steps.

### Quick Fixes

1. **Pods not starting**: Check image URI and pull permissions
2. **Health check failing**: Verify port 8000 is accessible
3. **Secret access denied**: Check IAM role permissions
4. **ALB not created**: Verify AWS Load Balancer Controller is installed (EKS)

## Next Steps

- Configure monitoring and alerting with CloudWatch
- Set up log aggregation
- Implement backup and disaster recovery
- Configure auto-scaling policies
- Review security group rules
- Set up CI/CD pipeline for updates
