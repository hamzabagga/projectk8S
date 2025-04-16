
locals {
  env = terraform.workspace
  public_sg_rules_ingress = {
    for id, rule in csvdecode(file("./sg_rules.csv")) :
    id => rule if rule["sg_name"] == "public_sg" && rule["rule_type"] == "ingress"
  }
  private_sg_rules_ingress = {
    for id, rule in csvdecode(file("./sg_rules.csv")) :
    id => rule if rule["sg_name"] == "private_sg" && rule["rule_type"] == "ingress"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.vpc_name}-${local.env}"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnets[count.index].cidr_block
  availability_zone = var.public_subnets[count.index].availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.public_subnets[count.index].name}-${local.env}"
  }
  depends_on = [aws_vpc.main]
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnets[count.index].cidr_block
  availability_zone = var.private_subnets[count.index].availability_zone
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.private_subnets[count.index].name}-${local.env}"
  }
  depends_on = [aws_vpc.main]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.igw_name}-${local.env}"
  }
  depends_on = [aws_vpc.main]
}

resource "aws_eip" "nat_eip" {
  count = length(var.private_subnets)
  domain = "vpc"
  tags = {
    Name = "hamza-nat-eip-${count.index}-${local.env}"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  count = length(var.private_subnets)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id = aws_subnet.public[count.index].id
  tags = {
    Name = "hamza-nat-${count.index}-${local.env}"
  }
  depends_on = [aws_eip.nat_eip, aws_subnet.public]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "hamza-public-route-table-${local.env}"
  }
  depends_on = [aws_internet_gateway.igw, aws_subnet.public]
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)
  subnet_id = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
  depends_on = [aws_route_table.public, aws_subnet.public]
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "hamza-private-route-table-${count.index}-${local.env}"
  }
  depends_on = [aws_nat_gateway.nat, aws_subnet.private]
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)
  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, count.index)
  depends_on = [aws_route_table.private, aws_subnet.private]
}

resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "web-sg"
  }
  depends_on = [aws_subnet.public]
}

resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow private access"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "web-sg"
  }
  depends_on = [aws_subnet.private]
}

resource "aws_security_group_rule" "sg_rules" {
  for_each = merge(local.public_sg_rules_ingress, local.private_sg_rules_ingress)

  type              = each.value.rule_type
  from_port         = tonumber(split("-", each.value.port_range)[0])
  to_port           = tonumber(split("-", each.value.port_range)[1])
  protocol          = each.value.protocol
  security_group_id = each.value.sg_name == "public_sg" ? aws_security_group.public_sg.id : aws_security_group.private_sg.id

  cidr_blocks = (each.value.dst_cidr != "" && each.value.dst_sg == "") ? [each.value.dst_cidr] : null

  source_security_group_id = (each.value.dst_sg != "" && each.value.dst_cidr == "") ? (
    each.value.dst_sg == "public_sg" ? aws_security_group.public_sg.id :
    each.value.dst_sg == "private_sg" ? aws_security_group.private_sg.id : null
  ) : null

  depends_on = [aws_security_group.public_sg, aws_security_group.private_sg]
}
