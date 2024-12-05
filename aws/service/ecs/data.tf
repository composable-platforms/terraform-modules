data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ecs_cluster" "cluster" {
  cluster_name = "${var.stage}-ecs-cluster"
}

data "aws_vpc" "vpc" {
  tags = { stage = "${var.stage}" }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  tags = {
    tier = "private"
  }
}

data "aws_service_discovery_dns_namespace" "cloudmap" {
  name = "${var.stage}-cluster.local"
  type = "DNS_PRIVATE"
}

data "aws_lb" "lb" {
  name = "${var.stage}-alb"
}

data "aws_lb_listener" "listener" {
  load_balancer_arn = data.aws_lb.lb.arn
  port              = 443
}

# data "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecs-task-execution-role-curai"
# }

# data "aws_iam_role" "ecs_task_role" {
#   name = "ecs-task-role-curai"
# }

# data "aws_security_group" "ecs" {
#   name = "${var.env}-security-group-ecs-curai"
# }

# data "aws_sns_topic" "sns_topic" {
#   name = "${var.env}-sns-topic-curai"
# }

# data "aws_secretsmanager_secret" "dd_api_key" {
#   name = "${var.env}-secret-DD_API_KEY-curai"
# }

# data "aws_secretsmanager_secret" "cert_public_key" {
#   name = "${var.env}-secret-CERT_PUBLIC_KEY-curai"
# }

# data "aws_secretsmanager_secret" "cert_private_key" {
#   name = "${var.env}-secret-CERT_PRIVATE_KEY-curai"
# }
