variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of allowed CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "container_port" { # ✅ ADD THIS LINE
  description = "Container port for ECS service"
  type        = number
  default     = 8080
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to use single NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Whether to create VPC endpoints"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}