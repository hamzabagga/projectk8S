output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnets_ids" {
  value = aws_subnet.private[*].id
}

output "security_group_ids" {
  value = { for k, sg in aws_security_group.sgs : k => sg.id }
}
