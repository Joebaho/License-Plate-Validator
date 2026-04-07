#!/bin/bash

# California Plate Validator - Setup Script
# This script sets up the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_message "Detected macOS system"
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_message "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install required tools
    print_message "Installing required tools..."
    brew update
    brew install terraform awscli jq docker docker-compose python3 nodejs
    
    # Install Python packages
    print_message "Installing Python packages..."
    pip3 install flask gunicorn boto3 requests python-dotenv
    
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_message "Detected Linux system"
    
    # Update package list
    sudo apt-get update
    
    # Install required tools
    print_message "Installing required tools..."
    sudo apt-get install -y \
        terraform \
        awscli \
        jq \
        docker.io \
        docker-compose \
        python3 \
        python3-pip \
        nodejs \
        npm
    
    # Install Python packages
    print_message "Installing Python packages..."
    pip3 install flask gunicorn boto3 requests python-dotenv
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    print_warning "Please log out and log back in for Docker group changes to take effect"
else
    print_error "Unsupported operating system"
    exit 1
fi

# Create project directory structure
print_message "Creating project structure..."
mkdir -p app docker terraform/modules/{ecs,codepipeline,networking} scripts tests

# Create Python virtual environment
print_message "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
print_message "Installing Python dependencies..."
pip install -r app/requirements.txt

# Initialize Git repository
if [ ! -d .git ]; then
    print_message "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit: California Plate Validator"
    
    # Create .gitignore
    cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
.env
.venv

# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
.terraform.tfstate.lock.info

# Docker
docker-compose.override.yml

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
EOF
fi

# Create environment file
print_message "Creating environment configuration..."
cat > .env.example << EOF
# AWS Configuration
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_DEFAULT_REGION=us-west-2

# Application Configuration
ENVIRONMENT=development
DEBUG=True
PORT=8080

# Docker Configuration
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_PASSWORD=your_dockerhub_password

# GitHub Configuration (for CI/CD)
GITHUB_TOKEN=your_github_token
GITHUB_REPO=yourusername/california-plate-validator
GITHUB_BRANCH=main
EOF

cp .env.example .env
print_warning "Please update .env file with your actual credentials"

# Make scripts executable
print_message "Making scripts executable..."
chmod +x scripts/*.sh

# Test installations
print_message "Testing installations..."

# Test Python
python3 --version
pip --version

# Test Terraform
terraform version

# Test AWS CLI
aws --version

# Test Docker
docker --version
docker-compose --version

# Create initial Terraform files
print_message "Creating initial Terraform configuration..."

# Create terraform.tfvars example
cat > terraform/terraform.tfvars.example << EOF
# AWS Configuration
aws_region = "us-west-2"
environment = "development"

# Project Configuration
project_name = "california-plate-validator"
container_port = 8080
container_cpu = 256
container_memory = 512
desired_count = 1

# Network Configuration
vpc_cidr = "10.0.0.0/16"
allowed_cidr_blocks = ["0.0.0.0/0"]

# GitHub Configuration
github_repo = "https://github.com/yourusername/california-plate-validator.git"
github_branch = "main"

# DockerHub Configuration
dockerhub_username = "yourdockerhub"
EOF

cp terraform/terraform.tfvars.example terraform/terraform.tfvars
print_warning "Please update terraform/terraform.tfvars with your actual values"

print_success "Setup completed successfully!"
print_message "Next steps:"
echo "1. Update .env file with your credentials"
echo "2. Update terraform/terraform.tfvars with your configuration"
echo "3. Run: source venv/bin/activate"
echo "4. Run: python app/app.py (to test the application)"
echo "5. Run: ./scripts/deploy.sh (to deploy to AWS)"