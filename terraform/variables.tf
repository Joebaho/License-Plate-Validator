# AWS Configuration
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}
# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "license-plate-validator"
}
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = ""
}
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner/Team name for tagging"
  type        = string
  default     = "DevOps"
}

# Application Configuration
variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "CPU units for the container (1024 units = 1 vCPU)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory for the container (in MiB)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks for autoscaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for autoscaling"
  type        = number
  default     = 4
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ECR Configuration
variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for ECR repository"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ecr_image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "ecr_scan_on_push" {
  description = "Whether to scan images on push to ECR"
  type        = bool
  default     = true
}

# CI/CD Configuration
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "cojocloud"
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "license-plate-lookup"
}

variable "github_branch" {
  description = "GitHub branch to trigger pipeline"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar connection to GitHub"
  type        = string
  default     = ""
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 30
}

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"

  validation {
    condition     = contains(["BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE"], var.build_compute_type)
    error_message = "build_compute_type must be one of: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE."
  }
}

# Docker Configuration
variable "dockerhub_username" {
  description = "DockerHub username for pushing images (leave empty to skip DockerHub)"
  type        = string
  default     = ""
}

variable "dockerhub_password" {
  description = "DockerHub password or access token"
  type        = string
  sensitive   = true
  default     = ""
}

# DNS Configuration (Optional)
variable "create_dns" {
  description = "Whether to create Route53 DNS records"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for Route53 record"
  type        = string
  default     = "cojocloud.com"
}

variable "subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "plates"
}

# Monitoring Configuration
variable "enable_container_insights" {
  description = "Whether to enable Container Insights for ECS"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# Security Configuration
variable "enable_alb_ssl" {
  description = "Whether to enable SSL on ALB"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
  default     = ""
}

# Autoscaling Configuration
variable "enable_autoscaling" {
  description = "Whether to enable autoscaling for ECS service"
  type        = bool
  default     = true
}

variable "scaling_cpu_threshold" {
  description = "CPU threshold for autoscaling"
  type        = number
  default     = 70
}

variable "scaling_memory_threshold" {
  description = "Memory threshold for autoscaling"
  type        = number
  default     = 80
}

# Feature Flags
variable "enable_vpc_endpoints" {
  description = "Whether to create VPC endpoints for private subnets"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true
}
# Add these to your variables.tf file if not already present

variable "create_terraform_state_bucket" {
  description = "Whether to create S3 bucket for Terraform state"
  type        = bool
  default     = false
}
variable "create_terraform_state_lock" {
  description = "Whether to create DynamoDB table for Terraform state locking"
  type        = bool
  default     = false
}
