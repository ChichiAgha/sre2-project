data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/tags/v*"
      ]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

resource "aws_iam_role" "github_actions_ecr" {
  name               = var.github_actions_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Name        = var.github_actions_role_name
    Environment = var.environment
    Project     = "techbleat-global-bank"
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "github_actions_ecr_public_push" {
  statement {
    sid = "AuthenticateToPublicECR"
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }

  statement {
    sid = "PushImagesToPublicECR"
    actions = [
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:DescribeImages",
      "ecr-public:DescribeRepositories",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:PutImage",
      "ecr-public:UploadLayerPart"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_ecr_public_push" {
  name        = "${var.github_actions_role_name}-public-ecr-push"
  description = "Allow GitHub Actions to push scanned Techbleat images to Amazon ECR Public."
  policy      = data.aws_iam_policy_document.github_actions_ecr_public_push.json
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr_public_push" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.github_actions_ecr_public_push.arn
}
