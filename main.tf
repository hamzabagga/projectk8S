locals {
  env = terraform.workspace

  all_sg_rules = {
    for idx, rule in csvdecode(file("./sg_rules.csv")) :
    "${idx}" => rule
  }

  # Extraire tous les noms de groupes de sécurité de manière unique
  sg_names = distinct([
    for rule in local.all_sg_rules : rule.sg_name
  ])
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.vpc_name}-${local.env}"
  }
}

# Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index].cidr_block
  availability_zone       = var.public_subnets[count.index].availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.public_subnets[count.index].name}-${local.env}"
  }
  depends_on = [aws_vpc.main]
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index].cidr_block
  availability_zone       = var.private_subnets[count.index].availability_zone
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.private_subnets[count.index].name}-${local.env}"
  }
  depends_on = [aws_vpc.main]
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.igw_name}-${local.env}"
  }
  depends_on = [aws_vpc.main]
}

# NAT + EIP
resource "aws_eip" "nat_eip" {
  count  = length(var.private_subnets)
  domain = "vpc"
  tags = {
    Name = "nat-eip-${count.index}-${local.env}"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnets)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "nat-${count.index}-${local.env}"
  }
  depends_on = [aws_eip.nat_eip, aws_subnet.public]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt-${local.env}"
  }
  depends_on = [aws_internet_gateway.igw, aws_subnet.public]
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
  depends_on     = [aws_route_table.public, aws_subnet.public]
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "private-rt-${count.index}-${local.env}"
  }
  depends_on = [aws_nat_gateway.nat, aws_subnet.private]
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
  depends_on     = [aws_route_table.private, aws_subnet.private]
}

# Groupes de sécurité générés dynamiquement depuis le fichier CSV
resource "aws_security_group" "dynamic_sg" {
  for_each    = toset(local.sg_names)
  name        = each.key
  description = "SG for ${each.key}"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${each.key}-${local.env}"
  }
  depends_on = [aws_vpc.main]
}

# Règles dynamiques par ligne CSV
resource "aws_security_group_rule" "sg_rules" {
  for_each = local.all_sg_rules

  type              = each.value.rule_type
  protocol          = each.value.protocol
  from_port         = tonumber(split("-", each.value.port_range)[0])
  to_port           = tonumber(split("-", each.value.port_range)[1])
  security_group_id = aws_security_group.dynamic_sg[each.value.sg_name].id

  cidr_blocks = (each.value.dst_cidr != "" && each.value.dst_sg == "") ? [each.value.dst_cidr] : null

  source_security_group_id = (each.value.dst_sg != "" && each.value.dst_cidr == "") ? aws_security_group.dynamic_sg[each.value.dst_sg].id : null

  depends_on = [aws_security_group.dynamic_sg]
}
