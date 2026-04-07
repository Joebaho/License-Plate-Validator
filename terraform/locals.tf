locals {
  project_name = var.project_name

  # Common tags
  common_tags = {
    Project     = local.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Application = "License Plate Validator"
  }

  # Naming conventions
  name_prefix = "${local.project_name}-${var.environment}"

  # Container configuration
  container_config = {
    name   = "${local.name_prefix}-container"
    port   = var.container_port
    cpu    = var.container_cpu
    memory = var.container_memory
  }

  # ECS configuration
  ecs_config = {
    cluster_name = "${local.name_prefix}-cluster"
    service_name = "${local.name_prefix}-service"
  }

  # ALB configuration
  alb_config = {
    name              = "${local.name_prefix}-alb"
    target_group_name = "${local.name_prefix}-tg"
    listener_port     = 80
  }

  # VPC configuration
  vpc_config = {
    name = "${local.name_prefix}-vpc"
    cidr = var.vpc_cidr
  }

  # CodePipeline configuration
  pipeline_config = {
    name         = "${local.name_prefix}-pipeline"
    source_stage = "Source"
    build_stage  = "Build"
    deploy_stage = "Deploy"
  }

  # ECR configuration
  ecr_config = {
    name = "${local.name_prefix}"
  }
}