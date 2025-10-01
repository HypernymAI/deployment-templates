# Troubleshooting Guide

Common issues and solutions for Hypernym deployments.

## Table of Contents

- [Deployment Issues](#deployment-issues)
- [Container Issues](#container-issues)
- [Networking Issues](#networking-issues)
- [IAM and Permissions](#iam-and-permissions)
- [Health Check Failures](#health-check-failures)
- [Secrets Manager Issues](#secrets-manager-issues)
- [EKS-Specific Issues](#eks-specific-issues)
- [Performance Issues](#performance-issues)
- [Logging and Monitoring](#logging-and-monitoring)

## Deployment Issues

### CloudFormation Stack Creation Failed

**Symptom**: Stack rollback during creation

**Common Causes**:
1. Invalid parameter values
2. Resource limits exceeded
3. IAM permissions insufficient
4. Resource name conflicts

**Diagnosis**:
```bash
aws cloudformation describe-stack-events \
  --stack-name hypernym-ecs \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

**Solutions**:

1. **Check parameter file**:
   ```bash
   # Validate JSON syntax
   jq . my-params.json

   # Check for TODO placeholders
   grep -i "TODO" my-params.json
   ```

2. **Verify IAM permissions**:
   ```bash
   aws iam get-user
   aws iam list-attached-user-policies --user-name YOUR_USER
   ```

3. **Check resource limits**:
   ```bash
   # Check ECS service quota
   aws service-quotas get-service-quota \
     --service-code ecs \
     --quota-code L-9EF96962
   ```

4. **Delete failed stack and retry**:
   ```bash
   aws cloudformation delete-stack --stack-name hypernym-ecs
   aws cloudformation wait stack-delete-complete --stack-name hypernym-ecs
   # Then retry creation
   ```

### Stack Stuck in CREATE_IN_PROGRESS

**Symptom**: Stack creation takes longer than expected (> 30 minutes)

**Diagnosis**:
```bash
aws cloudformation describe-stack-events \
  --stack-name hypernym-ecs \
  --max-items 10
```

**Solutions**:

1. **Check VPC endpoint creation** (most common delay):
   - Interface endpoints can take 10-15 minutes
   - Multiple endpoints = longer creation time

2. **Monitor specific resource**:
   ```bash
   aws cloudformation describe-stack-resource \
     --stack-name hypernym-ecs \
     --logical-resource-id ECRAPIEndpoint
   ```

3. **If truly stuck** (> 1 hour):
   ```bash
   aws cloudformation cancel-update-stack --stack-name hypernym-ecs
   ```

## Container Issues

### Container Image Pull Failure

**Symptom**: Tasks/pods fail with "CannotPullContainerError"

**Diagnosis**:

**ECS**:
```bash
aws ecs describe-tasks \
  --cluster hypernym-cluster \
  --tasks TASK_ARN \
  --query 'tasks[0].containers[0].reason'
```

**EKS**:
```bash
kubectl describe pod POD_NAME -n hypernym
```

**Common Causes**:

1. **Invalid image URI**
   ```bash
   # Verify image exists
   aws ecr describe-images \
     --repository-name REPO_NAME \
     --image-ids imageTag=TAG
   ```

2. **ECR permissions**
   - Check task execution role has ECR permissions
   - Verify ECR repository policy allows access

3. **Wrong region**
   - Ensure ECR repository is in same region as deployment

**Solutions**:

1. **Update image URI in parameters**:
   ```json
   {
     "ParameterKey": "ContainerImage",
     "ParameterValue": "123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:v1.0.0"
   }
   ```

2. **Test manual pull**:
   ```bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin \
     123456789012.dkr.ecr.us-east-1.amazonaws.com

   docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/hypernym:v1.0.0
   ```

### Container Crashes on Startup

**Symptom**: Container starts but immediately exits

**Diagnosis**:

**ECS**:
```bash
aws logs tail /ecs/hypernym-ecs --follow
```

**EKS**:
```bash
kubectl logs POD_NAME -n hypernym
kubectl logs POD_NAME -n hypernym --previous  # Previous instance
```

**Common Causes**:

1. **Missing environment variables**
2. **Invalid secrets reference**
3. **Port binding issues**
4. **Application configuration errors**

**Solutions**:

1. **Check environment variables**:
   ```bash
   # ECS - view task definition
   aws ecs describe-task-definition \
     --task-definition hypernym-ecs-task \
     --query 'taskDefinition.containerDefinitions[0].environment'

   # EKS - check pod env
   kubectl exec -it POD_NAME -n hypernym -- env
   ```

2. **Verify secrets are accessible**:
   ```bash
   # Test secrets access
   aws secretsmanager get-secret-value \
     --secret-id hypernym-byop-credentials
   ```

3. **Check application logs for specific error**

## Networking Issues

### Cannot Access Internal ALB

**Symptom**: Connection timeout or refused when accessing ALB

**Diagnosis**:
```bash
# Get ALB DNS
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name hypernym-ecs \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text)

# Test from EC2 in same VPC
curl -v http://${ALB_DNS}/health
```

**Common Causes**:

1. **Accessing from outside VPC**
   - ALB is internal, not public
   - Need VPC peering, Transit Gateway, or VPN

2. **Security group misconfiguration**

3. **No route to VPC**

**Solutions**:

1. **Verify ALB is internal**:
   ```bash
   aws elbv2 describe-load-balancers \
     --names hypernym-ecs-alb \
     --query 'LoadBalancers[0].Scheme'
   ```
   Should output: `internal`

2. **Check security groups**:
   ```bash
   # ALB security group should allow your source
   aws ec2 describe-security-groups \
     --filters "Name=tag:Name,Values=*alb-sg*" \
     --query 'SecurityGroups[0].IpPermissions'
   ```

3. **Test from bastion/EC2 in VPC**:
   ```bash
   # Deploy test instance
   aws ec2 run-instances \
     --image-id ami-0c55b159cbfafe1f0 \
     --instance-type t3.micro \
     --subnet-id SUBNET_ID \
     --security-group-ids SG_ID
   ```

### Tasks/Pods Not Reaching Healthy State

**Symptom**: Tasks start but never pass health checks

**Diagnosis**:

**ECS**:
```bash
aws ecs describe-services \
  --cluster hypernym-cluster \
  --services hypernym-api \
  --query 'services[0].events[0:5]'
```

**EKS**:
```bash
kubectl get pods -n hypernym
kubectl describe pod POD_NAME -n hypernym
```

**Common Causes**:

1. **Application not listening on correct port**
2. **Health check path incorrect**
3. **Application slow to start**
4. **Resource constraints (CPU/memory)**

**Solutions**:

1. **Verify application is listening**:
   ```bash
   # ECS - check task logs
   aws logs tail /ecs/hypernym-ecs --follow

   # EKS - exec into pod
   kubectl exec -it POD_NAME -n hypernym -- netstat -tlnp
   ```

2. **Test health endpoint**:
   ```bash
   # From within container
   kubectl exec -it POD_NAME -n hypernym -- curl localhost:8000/health
   ```

3. **Increase grace period**:
   - ECS: Update `HealthCheckGracePeriodSeconds` to 120
   - EKS: Update `initialDelaySeconds` in probes to 60

4. **Check resource limits**:
   ```bash
   # View pod resource usage
   kubectl top pod POD_NAME -n hypernym
   ```

## IAM and Permissions

### Access Denied: Secrets Manager

**Symptom**: "User is not authorized to perform: secretsmanager:GetSecretValue"

**Diagnosis**:
```bash
# Check task/pod role
aws iam get-role-policy \
  --role-name hypernym-ecs-task-role \
  --policy-name SecretsManagerAccess
```

**Solutions**:

1. **Verify BYOP mode is enabled**:
   - Check CloudFormation parameter `InferenceProviderMode=byop`

2. **Verify IAM policy is attached**:
   ```bash
   aws iam list-role-policies --role-name hypernym-ecs-task-role
   ```

3. **Check secret ARN matches**:
   ```bash
   # Get secret ARN
   aws secretsmanager describe-secret \
     --secret-id hypernym-byop-credentials \
     --query 'ARN'

   # Compare with CloudFormation parameter
   ```

4. **Verify VPC endpoint** (BYOP mode):
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters "Name=service-name,Values=com.amazonaws.REGION.secretsmanager"
   ```

### Access Denied: Marketplace Metering

**Symptom**: "User is not authorized to perform: aws-marketplace:MeterUsage"

**Diagnosis**:
```bash
aws iam get-role-policy \
  --role-name hypernym-ecs-task-role \
  --policy-name MarketplaceMetering
```

**Solutions**:

1. **Verify task role has marketplace policy**:
   ```bash
   aws iam list-attached-role-policies --role-name hypernym-ecs-task-role
   ```

2. **Check policy document**:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "aws-marketplace:MeterUsage",
       "aws-marketplace:RegisterUsage"
     ],
     "Resource": "*"
   }
   ```

3. **Verify product code is correct**:
   - Check CloudFormation parameter `MarketplaceProductCode`

### EKS IRSA Not Working

**Symptom**: Pods cannot assume IAM role

**Diagnosis**:
```bash
# Check service account annotation
kubectl describe serviceaccount hypernym-api -n hypernym

# Check pod has correct env vars
kubectl exec POD_NAME -n hypernym -- env | grep AWS
```

**Solutions**:

1. **Verify OIDC provider**:
   ```bash
   aws iam list-open-id-connect-providers
   ```

2. **Check service account annotation**:
   ```yaml
   annotations:
     eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT:role/ROLE_NAME"
   ```

3. **Verify trust relationship**:
   ```bash
   aws iam get-role \
     --role-name hypernym-eks-pod-role \
     --query 'Role.AssumeRolePolicyDocument'
   ```

4. **Update Helm values with correct role ARN**:
   ```bash
   # Get role ARN from CloudFormation
   aws cloudformation describe-stacks \
     --stack-name hypernym-eks \
     --query 'Stacks[0].Outputs[?OutputKey==`PodRoleArn`].OutputValue' \
     --output text
   ```

## Health Check Failures

### Health Endpoint Returns 5xx

**Symptom**: `/health` returns 500 or 503

**Diagnosis**:
```bash
# Check application logs
kubectl logs POD_NAME -n hypernym | grep health
```

**Solutions**:

1. **Check application startup**:
   - Application may still be initializing
   - Increase `initialDelaySeconds`

2. **Check dependencies**:
   - Verify managed API URL is accessible (managed mode)
   - Verify secrets are readable (BYOP mode)

3. **Test endpoint directly**:
   ```bash
   kubectl port-forward POD_NAME -n hypernym 8000:8000
   curl http://localhost:8000/health
   ```

### Health Checks Timeout

**Symptom**: Health checks timeout before responding

**Solutions**:

1. **Increase timeout**:
   - ECS: Update health check timeout in target group
   - EKS: Update `timeoutSeconds` in probes

2. **Check resource constraints**:
   - Application may be CPU/memory starved
   - Increase resource limits

3. **Verify network path**:
   - Check security groups allow ALB → Task/Pod
   - Port 8000 must be accessible

## Secrets Manager Issues

### Secret Not Found

**Symptom**: "ResourceNotFoundException: Secrets Manager can't find the specified secret"

**Solutions**:

1. **Verify secret exists**:
   ```bash
   aws secretsmanager list-secrets \
     --query 'SecretList[?Name==`hypernym-byop-credentials`]'
   ```

2. **Check region**:
   - Secret must be in same region as deployment

3. **Verify ARN format**:
   ```
   arn:aws:secretsmanager:REGION:ACCOUNT:secret:NAME-SUFFIX
   ```

### Invalid Secret Format

**Symptom**: Application fails to parse secret values

**Solutions**:

1. **Verify JSON format**:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id hypernym-byop-credentials \
     --query 'SecretString' \
     --output text | jq .
   ```

2. **Expected format**:
   ```json
   {
     "provider_url": "https://api.openai.com/v1",
     "api_key": "sk-proj-...",
     "model_name": "gpt-4-turbo"
   }
   ```

3. **Update secret**:
   ```bash
   aws secretsmanager update-secret \
     --secret-id hypernym-byop-credentials \
     --secret-string file://byop-secret-template.json
   ```

## EKS-Specific Issues

### AWS Load Balancer Controller Not Installed

**Symptom**: Ingress created but no ALB provisioned

**Diagnosis**:
```bash
kubectl get ingress -n hypernym
# ADDRESS column is empty
```

**Solutions**:

1. **Check controller is running**:
   ```bash
   kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   ```

2. **Install controller**:
   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=hypernym-cluster
   ```

3. **Check controller logs**:
   ```bash
   kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   ```

### Pods Pending (No Nodes Available)

**Symptom**: Pods stuck in Pending state

**Diagnosis**:
```bash
kubectl get pods -n hypernym
kubectl describe pod POD_NAME -n hypernym
```

**Solutions**:

1. **Check node status**:
   ```bash
   kubectl get nodes
   ```

2. **Check node group**:
   ```bash
   aws eks describe-nodegroup \
     --cluster-name hypernym-cluster \
     --nodegroup-name hypernym-cluster-node-group
   ```

3. **Scale node group**:
   ```bash
   aws eks update-nodegroup-config \
     --cluster-name hypernym-cluster \
     --nodegroup-name hypernym-cluster-node-group \
     --scaling-config desiredSize=3
   ```

### Cannot Connect to EKS Cluster

**Symptom**: `kubectl` commands fail with connection error

**Solutions**:

1. **Update kubeconfig**:
   ```bash
   aws eks update-kubeconfig \
     --region us-east-1 \
     --name hypernym-cluster
   ```

2. **Verify AWS credentials**:
   ```bash
   aws sts get-caller-identity
   ```

3. **Check cluster endpoint access**:
   ```bash
   aws eks describe-cluster \
     --name hypernym-cluster \
     --query 'cluster.resourcesVpcConfig.endpointPublicAccess'
   ```

## Performance Issues

### High CPU Usage

**Symptom**: Tasks/pods frequently hitting CPU limits

**Diagnosis**:

**ECS**:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=hypernym-api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

**EKS**:
```bash
kubectl top pods -n hypernym
```

**Solutions**:

1. **Increase CPU allocation**:
   - ECS: Update `TaskCPU` parameter
   - EKS: Update `resources.limits.cpu`

2. **Scale horizontally**:
   - Increase desired task/pod count
   - Adjust auto-scaling thresholds lower

3. **Optimize application**:
   - Review application logs for performance issues
   - Check for inefficient code paths

### High Memory Usage

**Symptom**: Tasks/pods hitting memory limits, OOMKilled

**Solutions**:

1. **Increase memory allocation**:
   - ECS: Update `TaskMemory` parameter
   - EKS: Update `resources.limits.memory`

2. **Check for memory leaks**:
   ```bash
   # Monitor over time
   kubectl top pod POD_NAME -n hypernym --watch
   ```

3. **Review application configuration**:
   - Check `WORKERS` setting
   - Reduce concurrent requests if applicable

## Logging and Monitoring

### No Logs Appearing

**Symptom**: No logs in CloudWatch

**Diagnosis**:

**ECS**:
```bash
aws logs describe-log-groups --log-group-name-prefix /ecs/hypernym
aws logs describe-log-streams --log-group-name /ecs/hypernym-ecs
```

**EKS**:
```bash
kubectl logs POD_NAME -n hypernym
```

**Solutions**:

1. **Verify log group exists**:
   ```bash
   aws logs describe-log-groups
   ```

2. **Check IAM permissions**:
   - Task execution role needs `logs:CreateLogStream` and `logs:PutLogEvents`

3. **Verify VPC endpoint** (CloudWatch Logs):
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters "Name=service-name,Values=com.amazonaws.REGION.logs"
   ```

### High Logging Costs

**Symptom**: CloudWatch Logs costs higher than expected

**Solutions**:

1. **Reduce log retention**:
   ```bash
   aws logs put-retention-policy \
     --log-group-name /ecs/hypernym-ecs \
     --retention-in-days 7
   ```

2. **Filter logs at application level**:
   - Set `LOG_LEVEL` to `info` or `warning`
   - Avoid `debug` in production

3. **Use log insights for analysis instead of exporting**

## Getting Help

### Collecting Diagnostic Information

For support, collect:

1. **CloudFormation stack events**:
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name hypernym-ecs > stack-events.json
   ```

2. **ECS service events**:
   ```bash
   aws ecs describe-services \
     --cluster hypernym-cluster \
     --services hypernym-api > service-events.json
   ```

3. **Application logs**:
   ```bash
   aws logs tail /ecs/hypernym-ecs --since 1h > app-logs.txt
   ```

4. **EKS pod describe**:
   ```bash
   kubectl describe pod POD_NAME -n hypernym > pod-describe.txt
   kubectl logs POD_NAME -n hypernym > pod-logs.txt
   ```

### Common Commands Reference

**ECS**:
```bash
# View service status
aws ecs describe-services --cluster CLUSTER --services SERVICE

# View task details
aws ecs describe-tasks --cluster CLUSTER --tasks TASK_ARN

# View logs
aws logs tail /ecs/STACK_NAME --follow

# Force new deployment
aws ecs update-service --cluster CLUSTER --service SERVICE --force-new-deployment
```

**EKS**:
```bash
# View pod status
kubectl get pods -n hypernym

# View pod details
kubectl describe pod POD_NAME -n hypernym

# View logs
kubectl logs POD_NAME -n hypernym --follow

# Restart deployment
kubectl rollout restart deployment hypernym -n hypernym
```

**CloudFormation**:
```bash
# View stack status
aws cloudformation describe-stacks --stack-name STACK_NAME

# View stack events
aws cloudformation describe-stack-events --stack-name STACK_NAME

# Update stack
aws cloudformation update-stack --stack-name STACK_NAME --template-body file://template.yaml --parameters file://params.json
```

## Related Documentation

- [Deployment Guide](deployment-guide.md): Deployment procedures
- [Architecture](architecture.md): System architecture and design
- [Parameters](parameters.md): Configuration reference
