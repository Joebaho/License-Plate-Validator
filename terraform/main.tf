# Random ID for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  suffix              = random_id.suffix.hex
  ecr_repository_name = "${local.project_name}-${var.environment}"
}

# S3 Bucket for Terraform State (if creating new)
resource "aws_s3_bucket" "terraform_state" {
  count = var.create_terraform_state_bucket ? 1 : 0

  bucket = "${local.project_name}-terraform-state-${local.suffix}"

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-terraform-state"
  })
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count = var.create_terraform_state_bucket ? 1 : 0

  bucket = aws_s3_bucket.terraform_state[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count = var.create_terraform_state_bucket ? 1 : 0

  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count = var.create_terraform_state_bucket ? 1 : 0

  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  count = var.create_terraform_state_lock ? 1 : 0

  name         = "${local.project_name}-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-terraform-state-lock"
  })
}

# ECR Repository
resource "aws_ecr_repository" "app_repo" {
  name         = local.ecr_repository_name
  force_delete = true

  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-ecr"
  })
}

resource "aws_ecr_lifecycle_policy" "app_repo" {
  repository = aws_ecr_repository.app_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countNumber = 7
          countUnit   = "days"
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# IAM Roles
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-task-role"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-logs"
  })
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_name         = local.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  allowed_cidr_blocks  = var.allowed_cidr_blocks
  container_port       = var.container_port # ✅ ADD THIS
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints
  region               = var.aws_region # ✅ ADD THIS

  tags = local.common_tags
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  project_name              = local.project_name
  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  public_subnet_ids         = module.networking.public_subnet_ids
  container_port            = var.container_port
  container_cpu             = var.container_cpu
  container_memory          = var.container_memory
  desired_count             = var.desired_count
  min_capacity              = var.min_capacity
  max_capacity              = var.max_capacity
  ecr_repository_url        = aws_ecr_repository.app_repo.repository_url
  task_execution_role_arn   = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn             = aws_iam_role.ecs_task_role.arn
  log_group_name            = aws_cloudwatch_log_group.app_logs.name
  enable_autoscaling        = var.enable_autoscaling
  scaling_cpu_threshold     = var.scaling_cpu_threshold
  scaling_memory_threshold  = var.scaling_memory_threshold
  enable_container_insights = var.enable_container_insights
  enable_alb_ssl            = var.enable_alb_ssl
  certificate_arn           = var.create_dns && var.domain_name != "" ? aws_acm_certificate_validation.app[0].certificate_arn : var.certificate_arn
  allowed_cidr_blocks       = var.allowed_cidr_blocks
  security_group_ids = {
    alb = module.networking.security_group_ids.alb
    ecs = module.networking.security_group_ids.ecs
  }
  region = var.aws_region # ✅ ADD THIS

  tags = local.common_tags
}

# CodePipeline Module
module "codepipeline" {
  source = "./modules/codepipeline"

  project_name            = local.project_name
  environment             = var.environment
  region                  = var.aws_region
  github_owner            = var.github_owner
  github_repo_name        = var.github_repo_name
  github_branch           = var.github_branch
  github_token            = var.github_token
  codestar_connection_arn = var.codestar_connection_arn
  ecr_repository_arn      = aws_ecr_repository.app_repo.arn
  ecr_repository_url      = aws_ecr_repository.app_repo.repository_url
  ecr_repository_name     = local.ecr_repository_name # ✅ FIXED
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  dockerhub_username      = var.dockerhub_username
  dockerhub_password      = var.dockerhub_password
  build_timeout           = var.build_timeout
  build_compute_type      = var.build_compute_type
  vpc_id                  = module.networking.vpc_id
  subnet_ids              = module.networking.private_subnet_ids
  security_group_ids      = [module.networking.security_group_ids.default]
  enable_vpc_config       = false
  aws_account_id          = data.aws_caller_identity.current.account_id # ✅ Use data source

  tags = local.common_tags
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}

# Route53 — look up the existing hosted zone (must already exist in your account)
data "aws_route53_zone" "main" {
  count        = var.create_dns && var.domain_name != "" ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# ACM Certificate
resource "aws_acm_certificate" "app" {
  count             = var.create_dns && var.domain_name != "" ? 1 : 0
  domain_name       = "${var.subdomain}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-cert"
  })
}

# Route53 records for ACM DNS validation
resource "aws_route53_record" "cert_validation" {
  for_each = var.create_dns && var.domain_name != "" ? {
    for dvo in aws_acm_certificate.app[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = data.aws_route53_zone.main[0].zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

# Wait for certificate to be issued
resource "aws_acm_certificate_validation" "app" {
  count                   = var.create_dns && var.domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route53 A record — subdomain → ALB
resource "aws_route53_record" "app" {
  count = var.create_dns && var.domain_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.ecs.alb_dns_name
    zone_id                = module.ecs.alb_zone_id
    evaluate_target_health = true
  }
}

# SSM Parameter Store for DockerHub credentials (optional)
resource "aws_ssm_parameter" "dockerhub_password" {
  count = var.dockerhub_password != "" ? 1 : 0

  name        = "/${local.project_name}/${var.environment}/dockerhub/password"
  description = "DockerHub password for CI/CD pipeline"
  type        = "SecureString"
  value       = var.dockerhub_password

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-dockerhub-password"
  })
}
