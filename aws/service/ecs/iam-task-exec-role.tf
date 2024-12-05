data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${var.stage}_${var.project_name}_${var.service_name}_task_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "task_execution_role" {
  statement {
    actions = [
      "secretsmanager:Get*",
      "secretsmanager:Describe*",
      "secretsmanager:List*",
      "ssm:GetParameter*",
      "ssm:DescribeParameter*",
      "kms:Decrypt",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task_execution_role" {
  role   = aws_iam_role.task_execution_role.id
  policy = data.aws_iam_policy_document.task_execution_role.json
}

# If you still need the custom inline policy based on a variable:
resource "aws_iam_role_policy" "custom_inline" {
  count  = var.custom_task_exec_iam_policy != null ? 1 : 0
  role   = aws_iam_role.task_execution_role.id
  policy = var.custom_task_exec_iam_policy
}

resource "aws_iam_role_policy_attachment" "task_execution_role_ecs_task_exec_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_execution_role_ecr_read_only" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

