locals {
  optional_ephemeral_storage = (var.ephemeral_storage == null ? null : { size_in_gib = var.ephemeral_storage })
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.stage}-${var.project_name}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  dynamic "ephemeral_storage" {
    for_each = local.optional_ephemeral_storage[*]
    content {
      size_in_gib = ephemeral_storage.value.size_in_gib
    }
  }

  container_definitions = jsonencode(
    [for k in concat(local.sidecars, ["app"]) : local.containers[k]]
  )
  lifecycle {
    create_before_destroy = true
  }

}
