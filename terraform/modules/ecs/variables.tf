variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "container_cpu" {
  description = "Container CPU units"
  type        = number
}

variable "container_memory" {
  description = "Container memory in MiB"
  type        = number
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
}

variable "min_capacity" {
  description = "Minimum task count for autoscaling"
  type        = number
}

variable "max_capacity" {
  description = "Maximum task count for autoscaling"
  type        = number
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of ECS task role"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "region" { # ✅ ADD THIS
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "enable_autoscaling" {
  description = "Whether to enable autoscaling"
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

variable "enable_container_insights" {
  description = "Whether to enable Container Insights"
  type        = bool
  default     = true
}

variable "enable_alb_ssl" {
  description = "Whether to enable SSL on ALB"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of SSL certificate"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "Allowed CIDR blocks for ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_ids" {
  description = "Security group IDs"
  type = object({
    alb = string
    ecs = string
  })
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}