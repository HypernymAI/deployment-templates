data "aws_region" "current" {}

resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-cluster-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-cluster/cluster"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-logs"
    }
  )
}

resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-cluster"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_policy,
    aws_cloudwatch_log_group.eks
  ]
}

resource "aws_iam_role" "node" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-node-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-node-group"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy
  ]
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-oidc-provider"
    }
  )
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.project_name
  }

  depends_on = [aws_eks_node_group.main]
}

resource "kubernetes_secret" "byop" {
  count = var.inference_provider_mode == "byop" ? 1 : 0

  metadata {
    name      = "${var.project_name}-byop-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    provider_url = ""
    api_key      = ""
    model_name   = ""
  }

  type = "Opaque"

  lifecycle {
    ignore_changes = [data]
  }
}

resource "helm_release" "app" {
  name      = var.project_name
  namespace = kubernetes_namespace.app.metadata[0].name
  chart     = var.helm_chart_path
  wait      = true
  timeout   = 600

  values = [
    yamlencode({
      image = {
        repository = split(":", var.container_image)[0]
        tag        = length(split(":", var.container_image)) > 1 ? split(":", var.container_image)[1] : "latest"
        pullPolicy = "IfNotPresent"
      }

      inferenceProviderMode = var.inference_provider_mode

      managed = var.inference_provider_mode == "managed" ? {
        apiUrl = var.managed_api_url
      } : null

      byop = var.inference_provider_mode == "byop" ? {
        secretName = kubernetes_secret.byop[0].metadata[0].name
        secretKeys = {
          providerUrl = "provider_url"
          apiKey      = "api_key"
          modelName   = "model_name"
        }
      } : null

      marketplace = {
        productCode = var.product_code
      }

      serviceAccount = {
        create = true
        annotations = {
          "eks.amazonaws.com/role-arn" = var.pod_role_arn
        }
        name = "${var.project_name}-api"
      }

      replicaCount = var.desired_count

      container = {
        port        = var.container_port
        environment = var.environment
        logLevel    = var.log_level
        workers     = 1
      }

      service = {
        type       = "ClusterIP"
        port       = 80
        targetPort = var.container_port
      }

      ingress = {
        enabled   = true
        className = "alb"
        annotations = {
          "alb.ingress.kubernetes.io/scheme"                       = "internal"
          "alb.ingress.kubernetes.io/target-type"                  = "ip"
          "alb.ingress.kubernetes.io/healthcheck-path"             = "/health"
          "alb.ingress.kubernetes.io/healthcheck-protocol"         = "HTTP"
          "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "30"
          "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
          "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
          "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "3"
          "alb.ingress.kubernetes.io/target-group-attributes"      = "deregistration_delay.timeout_seconds=30"
          "alb.ingress.kubernetes.io/load-balancer-attributes"     = "idle_timeout.timeout_seconds=60"
          "alb.ingress.kubernetes.io/subnets"                      = join(",", var.private_subnet_ids)
          "alb.ingress.kubernetes.io/security-groups"              = var.security_group_id
        }
        hosts = [
          {
            host = ""
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
      }

      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "512Mi"
          cpu    = "500m"
        }
      }

      autoscaling = {
        enabled                           = true
        minReplicas                       = var.min_capacity
        maxReplicas                       = var.max_capacity
        targetCPUUtilizationPercentage    = 70
        targetMemoryUtilizationPercentage = 80
      }

      livenessProbe = {
        httpGet = {
          path = "/health"
          port = var.container_port
        }
        initialDelaySeconds = 30
        periodSeconds       = 30
        timeoutSeconds      = 5
        successThreshold    = 1
        failureThreshold    = 3
      }

      readinessProbe = {
        httpGet = {
          path = "/health"
          port = var.container_port
        }
        initialDelaySeconds = 5
        periodSeconds       = 10
        timeoutSeconds      = 5
        successThreshold    = 1
        failureThreshold    = 3
      }

      podSecurityContext = {
        runAsNonRoot = true
        runAsUser    = 1000
        runAsGroup   = 1000
        fsGroup      = 1000
      }

      securityContext = {
        allowPrivilegeEscalation = false
        capabilities = {
          drop = ["ALL"]
        }
        readOnlyRootFilesystem = false
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.app,
    aws_eks_node_group.main
  ]
}
