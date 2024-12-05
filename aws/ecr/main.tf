resource "aws_ecr_repository" "repo" {
  name                 = "${var.project_name}/${var.service_name}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Allows trusted accounts full access to ECR
resource "aws_ecr_repository_policy" "cross_account" {
  repository = aws_ecr_repository.repo.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPull"
        Effect = "Allow"
        Principal = {
          AWS = formatlist("arn:aws:iam::%s:root", var.trusted_account_ids)
        }
        Action = [
          "ecr:*",
        ]
      }
    ]
  })
}
