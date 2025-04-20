module "network" {
  source             = "./modules/network"

  vpc_name           = var.vpc_name
  cidr_block         = var.cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  igw_name           = var.igw_name
  eip_name           = var.eip_name
  nat_gateway_name   = var.nat_gateway_name
}
