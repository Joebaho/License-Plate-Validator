provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "California-Plate-Validator"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "https://github.com/${var.github_owner}/${var.github_repo_name}"
    }
  }
}

provider "random" {}

provider "archive" {}

provider "local" {}