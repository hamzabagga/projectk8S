# Créer un VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "hamza-vpc"
  }
}

# Créer deux sous-réseaux publics
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "hamza-public-subnet-${count.index + 1}"
  }
}

# Créer deux sous-réseaux privés
resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)

  tags = {
    Name = "hamza-private-subnet-${count.index + 1}"
  }
}

# Créer une table de routage publique
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "hamza-public-route-table"
  }
}

# Associer les sous-réseaux publics à la table de routage publique
resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Créer une table de routage privée
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "hamza-private-route-table"
  }
}

# Associer les sous-réseaux privés à la table de routage privée
resource "aws_route_table_association" "private" {
  count = 2
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}