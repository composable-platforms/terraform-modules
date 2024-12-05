resource "aws_ecs_service" "srvc" {
  name                               = "${var.stage}-${var.project_name}-${var.service_name}-ecs-service"
  cluster                            = data.aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.task_def.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller {
    type = "ECS"
  }
  # Dynamic resource block is needed: 'count' argument in lb resources doesn't allow for
  # [count.index] to be used in load_balancer block so it needs to be abstracted
  dynamic "load_balancer" {
    for_each = local.optional_load_balancer[*]
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }

  }

  desired_count = var.desired_count

  # Allow external changes (autoscaling) without Terraform plan difference
  # Only ignore change if we wind up implementing autoscaling.
  # lifecycle {
  #   ignore_changes = [desired_count]
  # }

  launch_type = "FARGATE"
  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [data.aws_security_group.ecs.id]
    assign_public_ip = false
  }

  platform_version    = "1.4.0"
  propagate_tags      = "SERVICE"
  scheduling_strategy = "REPLICA"
  service_registries {
    registry_arn = aws_service_discovery_service.cloudmap_entry.arn
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  // If our desired task count is less than 20, the deployment circuit breaker will wait for
  // a minimum 10 (!) tasks failures to mark the rollout as failed. Each task failure can take
  // up to 10 minutes.
  // https://docs.aws.amazon.com/AmazonECS/latest/userguide/deployment-circuit-breaker.html
  // In deployment monitoring, we mark as failed after 2 task failures

}

# Task definition resources
resource "aws_ecs_task_definition" "task_def" {
  family = "${var.env}-${var.project_name}-${var.service_name}"
  cpu    = var.cpu
  memory = var.memory
  dynamic "ephemeral_storage" {
    for_each = local.optional_ephemeral_storage[*]

    content {
      size_in_gib = ephemeral_storage.value.size_in_gib
    }

  }
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  network_mode             = "awsvpc"

  container_definitions = jsonencode([
    {
      name = "ResolvConf-InitContainer"
      command = [
        "${var.aws_region}.compute.internal",
        "${var.env}-cluster.local"
      ]
      image = "docker/ecs-searchdomain-sidecar:1.0"
      repositoryCredentials = {
        credentialsParameter = "arn:aws:secretsmanager:us-west-2:938799764211:secret:docker-hub-creds-BhQeV4"
      },
      essential        = false
      logConfiguration = local.log_config
    },
    {
      name    = "${var.service_name}"
      command = var.container_command
      image   = "${var.service_image}"

      depends_on = [
        {
          condition     = "SUCCESS"
          containerName = "ResolvConf-InitContainer"
        }
      ]
      essential = true
      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
        }
      ]
      environment           = local.service_environment
      secrets               = local.all_secrets
      repositoryCredentials = var.repository_credentials
      dockerLabels          = local.service_docker_labels
      logConfiguration      = local.log_config
    },
    {
      name  = "datadog-agent"
      image = "datadog/agent"
      repositoryCredentials = {
        credentialsParameter = "arn:aws:secretsmanager:us-west-2:938799764211:secret:docker-hub-creds-BhQeV4"
      },
      tag                = "latest"
      cpu                = 10
      memory             = 512
      memory_reservation = 256
      environment        = local.dd_environment
      secrets            = local.all_secrets
      dockerLabels       = local.docker_labels
      logConfiguration   = local.log_config
    },
  ])
}

resource "aws_lb_listener_rule" "host_based_routing" {
  count        = var.register_with_alb ? 1 : 0
  listener_arn = data.aws_lb_listener.public_listener.arn

  dynamic "action" {
    for_each = local.optional_authentication[*]

    content {
      type = action.value.type

      authenticate_cognito {
        user_pool_arn       = action.value.user_pool_arn
        user_pool_client_id = action.value.user_pool_client_id
        user_pool_domain    = action.value.user_pool_domain
        session_cookie_name = action.value.session_cookie_name
        session_timeout     = action.value.session_timeout
      }
    }

  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  condition {
    host_header {
      values = [local.callback_url_string]
    }
  }
}

resource "aws_lb_target_group" "service_target_group" {
  count       = var.register_with_alb ? 1 : 0
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "ip"

  tags = {
    "Service" = var.service_name
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_route53_record" "service_record" {
  count   = var.register_with_alb ? 1 : 0
  zone_id = data.aws_route53_zone.env_zone.zone_id
  name    = local.record_string_name
  type    = "A"

  alias {
    name                   = data.aws_lb.lb.dns_name
    zone_id                = data.aws_lb.lb.zone_id
    evaluate_target_health = true
  }

}
