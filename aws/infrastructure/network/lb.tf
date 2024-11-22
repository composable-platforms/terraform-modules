# Listeners and target groups are defined by services

resource "aws_lb" "load_balancer" {
  name = "${var.stage}-alb"

  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public.*.id
  idle_timeout       = 150
}


resource "aws_lb_listener" "public_listener" {
  count = var.certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content that should never show up."
      status_code  = "200"
    }
  }

}
