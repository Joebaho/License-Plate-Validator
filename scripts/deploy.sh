#!/bin/bash

# California Plate Validator - Deployment Script
# Deploys infrastructure and application to AWS

set -euo pipefail

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuration
PROJECT_NAME="license-plate-validator"
ENVIRONMENT=${ENVIRONMENT:-"dev"}
REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
TERRAFORM_DIR="terraform"
BACKEND_BUCKET=${TF_BACKEND_BUCKET:-"${PROJECT_NAME}-terraform-state"}
BACKEND_KEY=${TF_BACKEND_KEY:-"terraform.tfstate"}
BACKEND_DDB_TABLE=${TF_BACKEND_DDB_TABLE:-"${PROJECT_NAME}-terraform-state-lock"}

if [ "$ENVIRONMENT" = "development" ]; then
    ENVIRONMENT="dev"
fi

check_prerequisites() {
    print_message "Checking prerequisites..."

    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi

    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured or invalid"
        exit 1
    fi

    print_success "All prerequisites met"
}

ensure_backend() {
    print_message "Ensuring Terraform backend resources exist..."

    if ! aws s3api head-bucket --bucket "$BACKEND_BUCKET" > /dev/null 2>&1; then
        print_message "Creating backend S3 bucket: $BACKEND_BUCKET"
        if [ "$REGION" = "us-west-2" ]; then
            aws s3api create-bucket --bucket "$BACKEND_BUCKET" > /dev/null
        else
            aws s3api create-bucket \
                --bucket "$BACKEND_BUCKET" \
                --region "$REGION" \
                --create-bucket-configuration LocationConstraint="$REGION" > /dev/null
        fi
        aws s3api put-bucket-versioning \
            --bucket "$BACKEND_BUCKET" \
            --versioning-configuration Status=Enabled > /dev/null
    fi

    if ! aws dynamodb describe-table --table-name "$BACKEND_DDB_TABLE" --region "$REGION" > /dev/null 2>&1; then
        print_message "Creating backend DynamoDB lock table: $BACKEND_DDB_TABLE"
        aws dynamodb create-table \
            --table-name "$BACKEND_DDB_TABLE" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION" > /dev/null
    fi

    print_success "Terraform backend is ready"
}

init_terraform() {
    print_message "Initializing Terraform..."

    cd "$TERRAFORM_DIR"

    terraform init \
        -backend-config="bucket=${BACKEND_BUCKET}" \
        -backend-config="key=${BACKEND_KEY}" \
        -backend-config="region=${REGION}" \
        -backend-config="dynamodb_table=${BACKEND_DDB_TABLE}" \
        -reconfigure

    cd ..

    print_success "Terraform initialized"
}

plan_terraform() {
    print_message "Planning Terraform changes..."

    cd "$TERRAFORM_DIR"

    terraform plan \
        -var="environment=${ENVIRONMENT}" \
        -var="aws_region=${REGION}" \
        -var="create_terraform_state_bucket=false" \
        -var="create_terraform_state_lock=false" \
        -out=tfplan

    cd ..

    print_success "Terraform plan created"
}

apply_terraform() {
    print_message "Applying Terraform changes..."

    cd "$TERRAFORM_DIR"

    terraform apply \
        -var="environment=${ENVIRONMENT}" \
        -var="aws_region=${REGION}" \
        -var="create_terraform_state_bucket=false" \
        -var="create_terraform_state_lock=false" \
        -auto-approve

    cd ..

    print_success "Terraform changes applied"
}

destroy_infrastructure() {
    print_warning "This will destroy all infrastructure!"
    read -r -p "Are you sure? (yes/no): " confirmation

    if [ "$confirmation" != "yes" ]; then
        print_message "Destruction cancelled"
        exit 0
    fi

    print_message "Destroying infrastructure..."

    cd "$TERRAFORM_DIR"

    terraform destroy \
        -var="environment=${ENVIRONMENT}" \
        -var="aws_region=${REGION}" \
        -var="create_terraform_state_bucket=false" \
        -var="create_terraform_state_lock=false" \
        -auto-approve

    cd ..

    print_success "Infrastructure destroyed"
}

deploy_application() {
    print_message "Deploying application..."

    ./scripts/build.sh

    print_message "Triggering ECS service update..."

    CLUSTER_NAME="${PROJECT_NAME}-cluster-${ENVIRONMENT}"
    SERVICE_NAME="${PROJECT_NAME}-service-${ENVIRONMENT}"

    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --force-new-deployment \
        --region "$REGION"

    print_message "Waiting for deployment to complete..."

    aws ecs wait services-stable \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region "$REGION"

    print_success "Application deployment completed"
}

get_status() {
    print_message "Getting deployment status..."

    cd "$TERRAFORM_DIR"
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Not deployed")
    ECR_REPO=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "Not deployed")
    cd ..

    print_message "Current deployment status:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Region: $REGION"
    echo "  ALB DNS: $ALB_DNS"
    echo "  ECR Repository: $ECR_REPO"
}

main_deployment() {
    print_message "Starting deployment for environment: $ENVIRONMENT"
    check_prerequisites
    ensure_backend
    init_terraform
    plan_terraform
    apply_terraform
    deploy_application
    get_status
    print_success "Deployment completed successfully!"
}

case "${1:-}" in
    "init")
        check_prerequisites
        ensure_backend
        init_terraform
        ;;
    "plan")
        check_prerequisites
        ensure_backend
        init_terraform
        plan_terraform
        ;;
    "apply")
        check_prerequisites
        ensure_backend
        init_terraform
        apply_terraform
        ;;
    "destroy")
        check_prerequisites
        ensure_backend
        init_terraform
        destroy_infrastructure
        ;;
    "deploy")
        deploy_application
        ;;
    "status")
        get_status
        ;;
    "full")
        main_deployment
        ;;
    *)
        print_message "Usage: $0 {init|plan|apply|destroy|deploy|status|full}"
        exit 1
        ;;
esac
