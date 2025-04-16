vpc_name   = "hamza-vpc"
cidr_block = "10.0.0.0/16"

public_subnets = [
  {
    name              = "hamza-public-subnet-1"
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1a"
  },
  {
    name              = "hamza-public-subnet-2"
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1b"
  }
]

private_subnets = [
  {
    name              = "hamza-private-subnet-1"
    cidr_block        = "10.0.3.0/24"
    availability_zone = "us-east-1a"
  },
  {
    name              = "hamza-private-subnet-2"
    cidr_block        = "10.0.4.0/24"
    availability_zone = "us-east-1b"
  }
]

igw_name          = "hamza-igw"
eip_name          = "hamza-nat-eip"
nat_gateway_name  = "hamza-nat"
