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

data "aws_security_group" "ecs" {
  name = "${var.stage}-security-group-ecs"
}
