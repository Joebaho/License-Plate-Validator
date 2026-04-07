output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    alb     = aws_security_group.alb.id
    ecs     = aws_security_group.ecs.id
    default = aws_security_group.default.id
  }
}

output "vpc_endpoint_ids" {
  description = "IDs of VPC endpoints"
  value = {
    s3             = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
    ecr_api        = var.enable_vpc_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
    ecr_dkr        = var.enable_vpc_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
    logs           = var.enable_vpc_endpoints ? aws_vpc_endpoint.logs[0].id : null
    secretsmanager = var.enable_vpc_endpoints ? aws_vpc_endpoint.secretsmanager[0].id : null
  }
}