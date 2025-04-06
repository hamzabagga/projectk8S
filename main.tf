resource "aws_vpc" "main2" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "hamza-vpc"
  }
}