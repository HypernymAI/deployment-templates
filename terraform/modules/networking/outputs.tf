output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_task_security_group_id" {
  description = "ECS task security group ID"
  value       = var.deployment_target == "ecs" ? aws_security_group.ecs_task[0].id : ""
}

output "eks_pod_security_group_id" {
  description = "EKS pod security group ID"
  value       = var.deployment_target == "eks" ? aws_security_group.eks_pod[0].id : ""
}

output "load_balancer_arn" {
  description = "Load balancer ARN"
  value       = aws_lb.main.arn
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.main.arn
}
