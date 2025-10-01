data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ecs_task_execution" {
  count = var.deployment_target == "ecs" ? 1 : 0
  name  = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ecs-task-execution-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count      = var.deployment_target == "ecs" ? 1 : 0
  role       = aws_iam_role.ecs_task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  count = var.deployment_target == "ecs" ? 1 : 0
  name  = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ecs-task-role"
    }
  )
}

resource "aws_iam_role_policy" "ecs_task_managed" {
  count = var.deployment_target == "ecs" && var.inference_provider_mode == "managed" ? 1 : 0
  name  = "${var.project_name}-ecs-task-managed-policy"
  role  = aws_iam_role.ecs_task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aws-marketplace:MeterUsage",
          "aws-marketplace:BatchMeterUsage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_byop" {
  count = var.deployment_target == "ecs" && var.inference_provider_mode == "byop" ? 1 : 0
  name  = "${var.project_name}-ecs-task-byop-policy"
  role  = aws_iam_role.ecs_task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.byop_secret_arn
      }
    ]
  })
}

resource "aws_iam_role" "eks_pod" {
  count = var.deployment_target == "eks" ? 1 : 0
  name  = "${var.project_name}-eks-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.eks_oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:${var.project_name}:${var.project_name}-api"
            "${replace(var.eks_oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-pod-role"
    }
  )
}

resource "aws_iam_role_policy" "eks_pod_managed" {
  count = var.deployment_target == "eks" && var.inference_provider_mode == "managed" ? 1 : 0
  name  = "${var.project_name}-eks-pod-managed-policy"
  role  = aws_iam_role.eks_pod[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aws-marketplace:MeterUsage",
          "aws-marketplace:BatchMeterUsage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_pod_byop" {
  count = var.deployment_target == "eks" && var.inference_provider_mode == "byop" ? 1 : 0
  name  = "${var.project_name}-eks-pod-byop-policy"
  role  = aws_iam_role.eks_pod[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.byop_secret_arn
      }
    ]
  })
}
