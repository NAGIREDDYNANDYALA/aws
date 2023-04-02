resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    instance_tenancy = var.tenancy
    tags = var.tags
}
# create public subnets
resource "aws_subnet" "public" {
    count = length(var.pub_sub_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.pub_sub_cidrs[count.index]
    availability_zone = local.az_names[count.index]
    tags = var.pub_sub_tag
    map_public_ip_on_launch = true
}
# create internet gateway
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {
        "Name" = "shn-i-g-public"
    }
}
# create route table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = {
        "Name" = "shn-public"
    }
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
# Associate public subnets to route table
resource "aws_route_table_association" "public" {
    count = length(var.pub_sub_cidrs)
    subnet_id = aws_subnet.public.*.id[count.index]
    route_table_id = aws_route_table.public.id
}
# create private subnets
resource "aws_subnet" "private" {
    count = length(var.pri_sub_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.pri_sub_cidrs[count.index]
    availability_zone = local.az_names[count.index]
    tags = var.pri_sub_tag
}
#Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.main]
  tags = {
    "Name" = "NAT Gateway EIP"
  }
}

#create Nat Gateway in public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  count = length(var.pub_sub_cidrs)
  subnet_id = aws_subnet.public.*.id[count.index]
  tags = {
    "Name" = "NAT Gateway"
  }
}

#create Route table for Private subnet
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    tags = {
        "Name" = "shn-private"
    }
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "aws_nat_gateway.nat.*.id"
  }
}

#Association between private subnet & private route table
resource "aws_route_table_association" "private" {
    count = length(var.pri_sub_cidrs)
    subnet_id = aws_subnet.private.*.id[count.index]
    route_table_id = aws_route_table.private.id
}
