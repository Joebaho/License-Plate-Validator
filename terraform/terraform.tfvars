aws_region  = "us-west-2"
environment = "dev"

project_name     = "license-plate-validator"
container_port   = 8080
container_cpu    = 256
container_memory = 512
desired_count    = 1

vpc_cidr            = "10.0.0.0/16"
allowed_cidr_blocks = ["0.0.0.0/0"]

github_owner     = "Joebaho"
github_repo_name = "license-plate-lookup"
github_branch    = "main"

dockerhub_username = "joebaho2"

# Paste the ARN from Step 2
codestar_connection_arn = "arn:aws:codestar-connections:us-east-1:ACCOUNT_ID:connection/YOUR-ID"