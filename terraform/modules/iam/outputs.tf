output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = var.deployment_target == "ecs" ? aws_iam_role.ecs_task_execution[0].arn : ""
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = var.deployment_target == "ecs" ? aws_iam_role.ecs_task[0].arn : ""
}

output "eks_pod_role_arn" {
  description = "EKS pod role ARN"
  value       = var.deployment_target == "eks" ? aws_iam_role.eks_pod[0].arn : ""
}
