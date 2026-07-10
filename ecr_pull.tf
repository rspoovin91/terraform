resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}

resource "aws_ecr_pull_through_cache_rule" "quay" {
  ecr_repository_prefix = "quay"
  upstream_registry_url = "quay.io"
}

resource "aws_ecr_pull_through_cache_rule" "gcr" {
  ecr_repository_prefix = "gcr"
  upstream_registry_url = "gcr.io"
}

resource "aws_iam_role_policy" "ecr_pull_through" {
  name = "ecr-pull-through-cache"
  role = aws_iam_role.eks_node.name # your existing node role

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PullThroughCache"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:BatchImportUpstreamImage"
        ]
        Resource = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/*"
      }
    ]
  })
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
  addon_version = "v1.18.1-eksbuild.1"

  configuration_values = jsonencode({
    init = {
      image = {
        repository = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/ecr-public/eks-distro/kubernetes/pause"
      }
    }
    image = {
      repository = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/ecr-public/amazon-vpc-cni"
    }
  })
}
