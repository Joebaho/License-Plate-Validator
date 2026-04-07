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
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch"
  type        = string
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "codestar_connection_arn" {
  description = "CodeStar connection ARN"
  type        = string
  default     = ""
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = ""
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "dockerhub_username" {
  description = "DockerHub username"
  type        = string
  default     = ""
}

variable "dockerhub_password" {
  description = "DockerHub password"
  type        = string
  sensitive   = true
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
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for CodeBuild"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for CodeBuild"
  type        = list(string)
}

variable "enable_vpc_config" {
  description = "Whether to run CodeBuild inside VPC"
  type        = bool
  default     = false
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
