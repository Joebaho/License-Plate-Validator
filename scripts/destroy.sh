#!/usr/bin/env bash

set -euo pipefail

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

PROJECT_NAME="license-plate-validator"
ENVIRONMENT="${ENVIRONMENT:-dev}"
REGION="${AWS_DEFAULT_REGION:-us-west-2}"
TERRAFORM_DIR="terraform"
BACKEND_BUCKET="${TF_BACKEND_BUCKET:-${PROJECT_NAME}-terraform-state}"
BACKEND_KEY="${TF_BACKEND_KEY:-terraform.tfstate}"
BACKEND_DDB_TABLE="${TF_BACKEND_DDB_TABLE:-${PROJECT_NAME}-terraform-state-lock}"
PURGE_BACKEND="${PURGE_BACKEND:-false}"

if [ "${ENVIRONMENT}" = "development" ]; then
  ENVIRONMENT="dev"
fi

print_info() { echo "[INFO] $1"; }
print_success() { echo "[SUCCESS] $1"; }
print_warn() { echo "[WARNING] $1"; }
print_error() { echo "[ERROR] $1"; }

check_prerequisites() {
  command -v aws >/dev/null || { print_error "AWS CLI is not installed"; exit 1; }
  command -v terraform >/dev/null || { print_error "Terraform is not installed"; exit 1; }
  aws sts get-caller-identity >/dev/null 2>&1 || { print_error "AWS credentials are not configured or invalid"; exit 1; }
}

init_terraform() {
  cd "${TERRAFORM_DIR}"
  terraform init \
    -backend-config="bucket=${BACKEND_BUCKET}" \
    -backend-config="key=${BACKEND_KEY}" \
    -backend-config="region=${REGION}" \
    -backend-config="dynamodb_table=${BACKEND_DDB_TABLE}" \
    -reconfigure
  cd - >/dev/null
}

purge_backend() {
  if [ "${PURGE_BACKEND}" != "true" ]; then
    print_info "Skipping backend purge. Set PURGE_BACKEND=true to remove backend S3/DynamoDB."
    return
  fi

  if ! command -v jq >/dev/null; then
    print_warn "jq is required to purge versioned backend S3 bucket. Skipping backend purge."
    return
  fi

  if aws s3api head-bucket --bucket "${BACKEND_BUCKET}" >/dev/null 2>&1; then
    print_info "Purging backend S3 bucket: ${BACKEND_BUCKET}"
    while true; do
      OBJECTS_JSON=$(aws s3api list-object-versions --bucket "${BACKEND_BUCKET}" --output json | \
        jq -c '{Objects: ([.Versions[]?, .DeleteMarkers[]?] | map({Key: .Key, VersionId: .VersionId}))}')
      OBJECT_COUNT=$(echo "${OBJECTS_JSON}" | jq '.Objects | length')

      if [ "${OBJECT_COUNT}" -eq 0 ]; then
        break
      fi

      aws s3api delete-objects --bucket "${BACKEND_BUCKET}" --delete "${OBJECTS_JSON}" >/dev/null
    done

    aws s3api delete-bucket --bucket "${BACKEND_BUCKET}" --region "${REGION}" >/dev/null
    print_success "Deleted backend bucket ${BACKEND_BUCKET}"
  fi

  if aws dynamodb describe-table --table-name "${BACKEND_DDB_TABLE}" --region "${REGION}" >/dev/null 2>&1; then
    aws dynamodb delete-table --table-name "${BACKEND_DDB_TABLE}" --region "${REGION}" >/dev/null
    print_success "Deleted backend lock table ${BACKEND_DDB_TABLE}"
  fi
}

main() {
  check_prerequisites
  init_terraform

  print_warn "This will destroy infrastructure for environment '${ENVIRONMENT}' in region '${REGION}'."
  read -r -p "Type 'yes' to continue: " confirmation
  if [ "${confirmation}" != "yes" ]; then
    print_info "Destruction cancelled."
    exit 0
  fi

  cd "${TERRAFORM_DIR}"
  terraform destroy \
    -var="environment=${ENVIRONMENT}" \
    -var="aws_region=${REGION}" \
    -var="create_terraform_state_bucket=false" \
    -var="create_terraform_state_lock=false" \
    -auto-approve
  cd - >/dev/null

  purge_backend
  print_success "Destroy completed."
}

main "$@"
