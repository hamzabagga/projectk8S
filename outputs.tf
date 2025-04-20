output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
}

output "public_subnets_ids" {
  description = "IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "private_subnets_ids" {
  description = "IDs des subnets privés"
  value       = aws_subnet.private[*].id
}

output "security_group_ids" {
  description = "IDs des groupes de sécurité"
  value       = { for k, sg in aws_security_group.sgs : k => sg.id }
}
