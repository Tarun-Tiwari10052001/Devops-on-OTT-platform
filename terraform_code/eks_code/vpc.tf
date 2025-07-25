# networking.tf
# -----------------------------

locals {
  eks_azs = ["ap-southeast-1a", "ap-southeast-1b"]
}

data "aws_region" "current" {}

resource "aws_vpc" "k8s-acc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "k8s-acc" {
  count = length(local.eks_azs)

  availability_zone       = local.eks_azs[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  vpc_id                  = aws_vpc.k8s-acc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_internet_gateway" "k8s-acc" {
  vpc_id = aws_vpc.k8s-acc.id

  tags = {
    Name = "eks-gateway"
  }
}

resource "aws_route_table" "k8s-acc" {
  vpc_id = aws_vpc.k8s-acc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s-acc.id
  }
}

resource "aws_route_table_association" "k8s-acc" {
  count = length(local.eks_azs)

  subnet_id      = aws_subnet.k8s-acc[count.index].id
  route_table_id = aws_route_table.k8s-acc.id
}
