#!/bin/bash

# California Plate Validator - Build Script
# Builds Docker image and pushes to ECR/DockerHub

set -euo pipefail

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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
    echo -e "${RED}[WARNING]${NC} $1"
}

# Configuration
PROJECT_NAME="license-plate-validator"
VERSION="1.0.0"
REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME:-""}

if [ "$ENVIRONMENT" = "development" ]; then
    ENVIRONMENT="dev"
fi

# Function to login to ECR
login_to_ecr() {
    print_message "Logging in to Amazon ECR..."

    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS credentials not configured for AWS CLI"
        exit 1
    fi

    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
    ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

    print_success "Logged in to ECR successfully"
}

# Function to login to DockerHub
login_to_dockerhub() {
    if [ -n "$DOCKERHUB_USERNAME" ] && [ -n "${DOCKERHUB_PASSWORD:-}" ]; then
        print_message "Logging in to DockerHub..."
        if echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin; then
            print_success "Logged in to DockerHub successfully"
        else
            print_warning "DockerHub login failed. Continuing with ECR only."
            DOCKERHUB_USERNAME=""
        fi
    else
        print_message "DockerHub credentials not provided, skipping DockerHub login"
    fi
}

# Function to build Docker image
build_image() {
    print_message "Building Docker image..."

    BUILD_ARGS=""
    if [ -n "$ENVIRONMENT" ]; then
        BUILD_ARGS="$BUILD_ARGS --build-arg ENVIRONMENT=$ENVIRONMENT"
    fi

    docker build $BUILD_ARGS \
        -t ${PROJECT_NAME}:${VERSION} \
        -t ${PROJECT_NAME}:latest \
        -f docker/Dockerfile ./app

    print_success "Docker image built successfully"

    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
    ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME}-${ENVIRONMENT}"

    docker tag ${PROJECT_NAME}:latest ${ECR_REPO}:latest
    docker tag ${PROJECT_NAME}:${VERSION} ${ECR_REPO}:${VERSION}

    if [ -n "$DOCKERHUB_USERNAME" ]; then
        docker tag ${PROJECT_NAME}:latest ${DOCKERHUB_USERNAME}/${PROJECT_NAME}:latest
        docker tag ${PROJECT_NAME}:${VERSION} ${DOCKERHUB_USERNAME}/${PROJECT_NAME}:${VERSION}
    fi

    print_success "Docker images tagged successfully"
}

# Function to push to ECR
push_to_ecr() {
    print_message "Pushing images to ECR..."

    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
    ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME}-${ENVIRONMENT}"

    if ! aws ecr describe-repositories --repository-names "${PROJECT_NAME}-${ENVIRONMENT}" --region "$REGION" > /dev/null 2>&1; then
        print_message "Creating ECR repository..."
        aws ecr create-repository \
            --repository-name "${PROJECT_NAME}-${ENVIRONMENT}" \
            --region "$REGION" \
            --image-scanning-configuration scanOnPush=true \
            --image-tag-mutability MUTABLE > /dev/null
    fi

    docker push ${ECR_REPO}:latest
    docker push ${ECR_REPO}:${VERSION}

    print_success "Images pushed to ECR successfully"
}

# Function to push to DockerHub
push_to_dockerhub() {
    if [ -n "$DOCKERHUB_USERNAME" ]; then
        print_message "Pushing images to DockerHub..."

        docker push ${DOCKERHUB_USERNAME}/${PROJECT_NAME}:latest
        docker push ${DOCKERHUB_USERNAME}/${PROJECT_NAME}:${VERSION}

        print_success "Images pushed to DockerHub successfully"
    fi
}

# Function to run tests
run_tests() {
    print_message "Running tests..."

    if [ -d "tests" ]; then
        python -m pytest tests/ -v
    fi

    print_message "Testing container health..."
    docker rm -f test-container >/dev/null 2>&1 || true
    docker run -d --name test-container -p 8080:8080 ${PROJECT_NAME}:latest >/dev/null
    sleep 10

    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' test-container)

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        print_success "Container health check passed"
    else
        print_error "Container health check failed"
        docker logs test-container || true
        docker rm -f test-container >/dev/null 2>&1 || true
        exit 1
    fi

    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/health)

    if [ "$RESPONSE" = "200" ]; then
        print_success "API health check passed"
    else
        print_error "API health check failed"
        docker logs test-container || true
        docker rm -f test-container >/dev/null 2>&1 || true
        exit 1
    fi

    docker rm -f test-container >/dev/null 2>&1 || true
    print_success "All tests passed successfully"
}

# Function to scan image for vulnerabilities
scan_image() {
    print_message "Scanning image for vulnerabilities..."

    if command -v trivy &> /dev/null; then
        trivy image ${PROJECT_NAME}:latest
    else
        print_message "Trivy not installed, skipping vulnerability scan"
    fi
}

main() {
    print_message "Starting build process for California Plate Validator v${VERSION}"

    login_to_ecr
    login_to_dockerhub
    build_image
    run_tests
    scan_image
    push_to_ecr
    push_to_dockerhub

    print_message "Build completed successfully"
}

case "${1:-}" in
    "test")
        run_tests
        ;;
    "scan")
        scan_image
        ;;
    "push")
        push_to_ecr
        push_to_dockerhub
        ;;
    *)
        main
        ;;
esac
