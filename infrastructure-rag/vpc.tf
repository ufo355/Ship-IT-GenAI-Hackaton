locals {
  vpc_id = ""
}


resource "aws_route_table" "private" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "172.31.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_subnet" "private1" {
  vpc_id                  = local.vpc_id
  cidr_block              = "172.31.48.0/20"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id                  = local.vpc_id
  cidr_block              = "172.31.80.0/20"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_route_table_association" "private_association_1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_association_2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "vpc_endpoint_sg" {
  vpc_id      = local.vpc_id
  name        = "vpc-endpoint-sg"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id = local.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = [aws_route_table.private.id]
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id             = local.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private1.id, 
    aws_subnet.private2.id
  ]
}

resource "aws_vpc_endpoint" "bedrock" {
  vpc_id             = local.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.bedrock-runtime"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private1.id, 
    aws_subnet.private2.id
  ]
}

resource "aws_vpc_endpoint" "textract" {
  vpc_id             = local.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.textract"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private1.id, 
    aws_subnet.private2.id
  ]
}