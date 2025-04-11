variable "vpc_name" {
  type        = string
  default     = "hamza-vpc"
  
}
variable "cidr_block" {
  type = string
  default = "10.0.0.0/16"
}