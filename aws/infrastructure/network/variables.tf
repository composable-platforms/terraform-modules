variable "stage" {
  description = "Name of the SDLC environment (example: dev, stage, prod)"

}

variable "cidr_block" {
  description = "CIDR block used as the basis of the VPC"
  type        = string
  default     = "10.0.0.0/16" # la
}

variable "aws_region" {
  description = "The AWS region to operate in"
  default     = "us-west-2"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = 2
}

variable "tunnel_ami" {
  description = "AMI of the EC2 tunnel instance (Default is Amazon Linux 2 for us-west-2)"
  default     = "ami-083ac7c7ecf9bb9b0"
}

variable "tunnel_instance_type" {
  description = "The instance type for the EC2 tunnel."
  default     = "t3.micro"
}

variable "certificate_arn" {
  description = "Certificate ARN for the ALB's public listener"
  default     = null
}