resource "aws_cloudwatch_log_group" "logs" {
  name              = "ecs/${replace(local.task_name, "-", "/")}"
  retention_in_days = var.log_retention
}

locals {
  task_name = "${var.stage}-${var.project_name}-${var.service_name}"

  ephemeral_storage_config = var.ephemeral_storage != null ? [{
    size_in_gib = var.ephemeral_storage
  }] : []

  environment = [
    for name, value in var.container_environment : {
      name  = name
      value = value
    }
  ]

  secrets = [
    for name, valueFrom in var.container_secrets : {
      name      = name
      valueFrom = valueFrom
    }
  ]
  parsed_ports = [
    for mapping in var.ports : {
      hostPort      = try(tonumber(split(":", mapping)[0]), tonumber(mapping))
      containerPort = try(tonumber(split(":", mapping)[1]), tonumber(mapping))
      protocol      = "tcp"
    }
  ]


  main_container = [
    {
      name        = var.service_name
      command     = var.container_command
      image       = var.image
      essential   = true
      environment = local.environment
      secrets     = local.secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.service_name
        }
      }
      portMappings = local.parsed_ports
    }
  ]

  container_definitions = jsonencode(concat(local.main_container, var.custom_sidecars))
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
    for_each = local.ephemeral_storage_config
    content {
      size_in_gib = ephemeral_storage.value.size_in_gib
    }
  }

  container_definitions = local.container_definitions
  lifecycle {
    create_before_destroy = true
  }

}
