#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="california-plate-validator:local"

cd "${ROOT_DIR}"

docker build -f docker/Dockerfile -t "${IMAGE_NAME}" ./app
exec docker run --rm -p 8080:8080 "${IMAGE_NAME}"
