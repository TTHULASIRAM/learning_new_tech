terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

############################################
# VPC
############################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

############################################
# INTERNET GATEWAY
############################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

############################################
# PUBLIC SUBNETS
############################################

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-az1"
    Environment = "DEV"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-az2"
     Environment = "DEV"
  }
}

############################################
# WEB SUBNETS
############################################

resource "aws_subnet" "web_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "web-az1"
    Environment = "DEV"
  }
}

resource "aws_subnet" "web_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "web-az2"
    Environment = "DEV"
  }
}

############################################
# APP SUBNETS
############################################

resource "aws_subnet" "app_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "app-az1"
    Environment = "DEV"
  }
}

resource "aws_subnet" "app_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "app-az2"
    Environment = "DEV"
  }
}

############################################
# DB SUBNETS
############################################

resource "aws_subnet" "db_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "db-az1"
    Environment = "DEV"
  }
}

resource "aws_subnet" "db_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "db-az2"
    Environment = "DEV"
  }
}

############################################
# PUBLIC ROUTE TABLE
############################################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
    Environment = "DEV"
  }
}

############################################
# PUBLIC RT ASSOCIATIONS
############################################

resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# PRIVATE ROUTE TABLE AZ1
############################################

resource "aws_route_table" "private_rt_az1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt-az1"
    Environment = "DEV"
  }
}

############################################
# PRIVATE ROUTE TABLE AZ2
############################################

resource "aws_route_table" "private_rt_az2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt-az2"
    Environment = "DEV"
  }
}

############################################
# PRIVATE RT ASSOCIATIONS AZ1
############################################

resource "aws_route_table_association" "web_az1_assoc" {
  subnet_id      = aws_subnet.web_az1.id
  route_table_id = aws_route_table.private_rt_az1.id
}

resource "aws_route_table_association" "app_az1_assoc" {
  subnet_id      = aws_subnet.app_az1.id
  route_table_id = aws_route_table.private_rt_az1.id
}

resource "aws_route_table_association" "db_az1_assoc" {
  subnet_id      = aws_subnet.db_az1.id
  route_table_id = aws_route_table.private_rt_az1.id
}

############################################
# PRIVATE RT ASSOCIATIONS AZ2
############################################

resource "aws_route_table_association" "web_az2_assoc" {
  subnet_id      = aws_subnet.web_az2.id
  route_table_id = aws_route_table.private_rt_az2.id
}

resource "aws_route_table_association" "app_az2_assoc" {
  subnet_id      = aws_subnet.app_az2.id
  route_table_id = aws_route_table.private_rt_az2.id
}

resource "aws_route_table_association" "db_az2_assoc" {
  subnet_id      = aws_subnet.db_az2.id
  route_table_id = aws_route_table.private_rt_az2.id
}

############################################
# S3 GATEWAY ENDPOINT
############################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_rt_az1.id,
    aws_route_table.private_rt_az2.id
  ]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}

############################################
# DYNAMODB GATEWAY ENDPOINT
############################################

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_rt_az1.id,
    aws_route_table.private_rt_az2.id
  ]

  tags = {
    Name = "dynamodb-gateway-endpoint"
  }
}