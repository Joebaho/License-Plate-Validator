output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.ecs.alb_dns_name}"
}

output "application_url_https" {
  description = "HTTPS URL to access the application (if SSL enabled)"
  value       = var.enable_alb_ssl && var.certificate_arn != "" ? "https://${module.ecs.alb_dns_name}" : null
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.app_repo.arn
}

output "pipeline_url" {
  description = "URL to view the CodePipeline"
  value       = "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${local.name_prefix}-pipeline/view"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.ecs.task_definition_arn
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_logs.arn
}

output "route53_record" {
  description = "Route53 record (if DNS is enabled)"
  value       = var.create_dns && var.domain_name != "" ? "${var.subdomain}.${var.domain_name}" : null
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.networking.vpc_cidr
}

output "security_group_ids" {
  description = "Security group IDs"
  value       = module.networking.security_group_ids
}

output "subnet_ids" {
  description = "Subnet IDs"
  value = {
    public  = module.networking.public_subnet_ids
    private = module.networking.private_subnet_ids
  }
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.networking.availability_zones
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.codepipeline.codebuild_project_name
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.codepipeline.codepipeline_name
}

output "codestar_connection_status" {
  description = "Status of the CodeStar connection"
  value       = module.codepipeline.codestar_connection_status
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.ecs.alb_zone_id
}

output "alb_listener_arns" {
  description = "ARNs of the ALB listeners"
  value       = module.ecs.alb_listener_arns
}

output "alb_target_group_arns" {
  description = "ARNs of the ALB target groups"
  value       = module.ecs.alb_target_group_arns
}

output "autoscaling_group_name" {
  description = "Autoscaling target resource ID (if enabled)"
  value       = module.ecs.autoscaling_target_arn
}

output "iam_roles" {
  description = "IAM roles created"
  value = {
    ecs_task_execution_role = aws_iam_role.ecs_task_execution_role.arn
    ecs_task_role           = aws_iam_role.ecs_task_role.arn
    codebuild_role          = module.codepipeline.codebuild_role_arn
    codepipeline_role       = module.codepipeline.codepipeline_role_arn
  }
  sensitive = true
}

output "s3_bucket_names" {
  description = "S3 bucket names"
  value = {
    terraform_state = var.create_terraform_state_bucket ? aws_s3_bucket.terraform_state[0].bucket : null
    artifacts       = module.codepipeline.artifact_bucket_name
  }
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = var.create_terraform_state_lock ? aws_dynamodb_table.terraform_state_lock[0].name : null
}

output "container_configuration" {
  description = "Container configuration"
  value = {
    port   = var.container_port
    cpu    = var.container_cpu
    memory = var.container_memory
    image  = "${aws_ecr_repository.app_repo.repository_url}:latest"
  }
}

output "github_webhook_url" {
  description = "GitHub webhook URL (if using webhooks)"
  value       = module.codepipeline.github_webhook_url
  sensitive   = true
}

output "ssm_parameters" {
  description = "SSM parameters created"
  value = {
    dockerhub_password = var.dockerhub_password != "" ? aws_ssm_parameter.dockerhub_password[0].name : null
  }
  sensitive = true
}
