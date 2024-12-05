resource "aws_ecs_service" "service" {
  name                               = "${var.stage}-${var.project_name}-${var.service_name}-ecs-service"
  cluster                            = data.aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.task.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller {
    type = "ECS"
  }

  # initial count 
  desired_count = var.min_capacity

  # Allow external changes (autoscaling) without Terraform plan difference
  # Only ignore change if we wind up implementing autoscaling.
  lifecycle {
    ignore_changes = [desired_count]
  }

  launch_type = "FARGATE"
  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [data.aws_security_group.ecs.id]
    assign_public_ip = false
  }

  platform_version    = "1.4.0"
  propagate_tags      = "SERVICE"
  scheduling_strategy = "REPLICA"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
