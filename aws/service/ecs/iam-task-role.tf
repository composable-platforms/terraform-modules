resource "aws_iam_role" "task_role" {
  name               = "${var.stage}_${var.project_name}_${var.service_name}_task_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "task_role" {
  statement {
    actions = [
      "ecs:DescribeTasks",
      "ecs:StopTask"
    ]
    effect    = "Allow"
    resources = ["*"]

  }
  statement {
    actions = [
      "iam:PassRole"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_permissions" {
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_role
}

resource "aws_iam_role_policy" "custom_task_policy" {
  count  = var.custom_task_iam_policy != null ? 1 : 0
  role   = aws_iam_role.task_role.id
  policy = var.custom_task_iam_policy
}

