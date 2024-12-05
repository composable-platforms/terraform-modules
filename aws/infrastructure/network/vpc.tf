# vpc.tf

# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}
locals {
  # Private subnets get /19 (larger), while public and data get /20 (smaller)
  subnet_cidrs = {
    # Public subnets: /20 = 4,094 usable IPs each
    public = {
      "az1" = cidrsubnet(var.cidr_block, 4, 0) # 10.0.0.0/20
      "az2" = cidrsubnet(var.cidr_block, 4, 1) # 10.0.16.0/20
      "az3" = cidrsubnet(var.cidr_block, 4, 2) # 10.0.32.0/20
    }
    # Private subnets: /19 = 8,190 usable IPs each
    private = {
      "az1" = cidrsubnet(var.cidr_block, 3, 2) # 10.0.64.0/19
      "az2" = cidrsubnet(var.cidr_block, 3, 3) # 10.0.96.0/19
      "az3" = cidrsubnet(var.cidr_block, 3, 4) # 10.0.128.0/19
    }
    # Data subnets: /20 = 4,094 usable IPs each
    data = {
      "az1" = cidrsubnet(var.cidr_block, 4, 12) # 10.0.192.0/20
      "az2" = cidrsubnet(var.cidr_block, 4, 13) # 10.0.208.0/20
      "az3" = cidrsubnet(var.cidr_block, 4, 14) # 10.0.224.0/20
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "cloudmap" {
  name        = "${var.stage}-cluster.local"
  description = "Service Map for ${var.stage} cluster."
  vpc         = aws_vpc.vpc.id
}


# Main VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = local.subnet_cidrs.public["az${count.index + 1}"]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true

  tags = {
    Tier = "public"
  }
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = local.subnet_cidrs.private["az${count.index + 1}"]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Tier = "private"
  }
}

# Create var.az_count data subnets, each in a different AZ
resource "aws_subnet" "data" {
  count             = var.az_count
  cidr_block        = local.subnet_cidrs.data["az${count.index + 1}"]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Tier = "data"
  }
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

# Route the public subnet traffic through the internet gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Explicit route table for public subnets
resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_vpc.vpc.main_route_table_id
}

# Create an Elastic IP for each private subnet
resource "aws_eip" "gateway_eip" {
  count      = var.az_count
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
}

# Create a NAT gateway for each private subnet to get internet connectivity
resource "aws_nat_gateway" "nat_gateway" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway_eip.*.id, count.index)


  depends_on = [aws_internet_gateway.internet_gateway]
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gateway.*.id, count.index)
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

# Create a new route table for the data subnets without internet access
resource "aws_route_table" "data" {
  count  = var.az_count
  vpc_id = aws_vpc.vpc.id

  route = []
}

# Explicitly associate the newly created route tables to the data subnets (so they don't default to the main route table)
resource "aws_route_table_association" "data" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.data.*.id, count.index)
  route_table_id = element(aws_route_table.data.*.id, count.index)
}

# Set up a VPC endpoint for S3
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.s3"
#   vpc_endpoint_type = "Gateway"

#   route_table_ids = aws_route_table.private.*.id

#   tags = {
#     Name = "${var.stage}-vpc-endpoint-s3"
#   }
# }

# # Set up VPC endpoints for ECR (x2)
# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true

#   security_group_ids = [aws_security_group.vpc_endpoints.id]
#   subnet_ids         = aws_subnet.private.*.id

# }

# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true

#   security_group_ids = [aws_security_group.vpc_endpoints.id]
#   subnet_ids         = aws_subnet.private.*.id

# }

# # Set up VPC endpoint for secrets manager
# resource "aws_vpc_endpoint" "secretsmanager" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true

#   security_group_ids = [aws_security_group.vpc_endpoints.id]
#   subnet_ids         = aws_subnet.private.*.id

# }
