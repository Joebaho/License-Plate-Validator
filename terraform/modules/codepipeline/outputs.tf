output "artifact_bucket_name" {
  description = "Name of the S3 artifact bucket"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifact_bucket_arn" {
  description = "ARN of the S3 artifact bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.main.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.main.arn
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.main.name
}

output "codepipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.main.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild IAM role"
  value       = aws_iam_role.codebuild.arn
}

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline IAM role"
  value       = aws_iam_role.codepipeline.arn
}

output "codestar_connection_arn" {
  description = "ARN of the CodeStar connection"
  value       = var.codestar_connection_arn != "" ? var.codestar_connection_arn : aws_codestarconnections_connection.github[0].arn
}

output "codestar_connection_status" {
  description = "Status of the CodeStar connection"
  value       = var.codestar_connection_arn != "" ? "EXTERNAL" : aws_codestarconnections_connection.github[0].connection_status
}

output "github_webhook_url" {
  description = "GitHub webhook URL"
  value       = "https://webhooks.${var.region}.amazonaws.com/github/${aws_codepipeline.main.name}"
}