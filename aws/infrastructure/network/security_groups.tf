# security_groups.tf

# ALB security group should only allow external traffic on ports 80 and 443
resource "aws_security_group" "lb" {
  name        = "${var.stage}-security-group-lb"
  description = "Security group to controls access to the ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5000
    to_port     = 5005
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.stage}-security-group-lb"
    Environment = var.stage
  }
}
# VPC endpoints security group
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.stage}-security-group-vpc-endpoints"
  description = "allow VPC endpoint access"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stage}-security-group-vpc-endpoints"
  }
}

# Traffic to ECS can come from the ALB, EC2 tunnel, or VPC endpoints
resource "aws_security_group" "ecs" {
  name        = "${var.stage}-security-group-ecs"
  description = "allow inbound access from ALB, EC2 tunnel, VPC endpoints, or ECS itself"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    self      = true
    security_groups = [
      aws_security_group.lb.id,
      aws_security_group.ec2_tunnel.id,
      aws_security_group.vpc_endpoints.id,
    ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    # this is not a meaningful change to the resource
    ignore_changes = [description]
  }

  tags = {
    Name        = "${var.stage}-security-group-ecs"
    Environment = var.stage
  }
}

# Traffic to EC2 tunnel can come from anywhere
resource "aws_security_group" "ec2_tunnel" {
  name        = "${var.stage}-security-group-ec2-tunnel"
  description = "allow inbound access for internal resources through tunnel"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # TODO: limit SSH access to specific IP blocks
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.stage}-security-group-ec2-tunnel"
    Environment = var.stage
  }
}

