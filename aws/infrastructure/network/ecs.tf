resource "aws_ecs_cluster" "cluster" {
  name = "${var.stage}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
