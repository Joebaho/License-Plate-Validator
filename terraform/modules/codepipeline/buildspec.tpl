version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: "${region}"
    IMAGE_REPO_NAME: "${project_name}-${environment}"
    IMAGE_TAG: "latest"
    ECR_REPOSITORY_URL: "${ecr_repository_url}"
    ECS_CLUSTER: "${ecs_cluster_name}"
    ECS_SERVICE: "${ecs_service_name}"
    ENVIRONMENT: "${environment}"
%{ if dockerhub_username != "" ~}
  parameter-store:
    DOCKERHUB_PASSWORD: "/${project_name}/${environment}/dockerhub/password"
%{ endif ~}

phases:
  pre_build:
    commands:
      - echo "Starting build process for ${project_name} in $${ENVIRONMENT} environment"
      - echo "Logging in to Amazon ECR..."
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL
      
      - echo "Verifying ECR repository exists..."
      - aws ecr describe-repositories --repository-names "$IMAGE_REPO_NAME" --region $AWS_DEFAULT_REGION
      
      - echo "Setting image tags..."
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=$${COMMIT_HASH:=latest}
      - IMAGE_URI=$ECR_REPOSITORY_URL:$IMAGE_TAG
      
      - echo "Logging in to DockerHub (if credentials provided)..."
      - |
        if [ -n "${dockerhub_username}" ] && [ -n "$DOCKERHUB_PASSWORD" ]; then
          echo "$DOCKERHUB_PASSWORD" | docker login --username "${dockerhub_username}" --password-stdin
        fi

  build:
    commands:
      - echo "Building Docker image..."
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG -t $IMAGE_REPO_NAME:latest -f docker/Dockerfile ./app
      - docker tag $IMAGE_REPO_NAME:latest $ECR_REPOSITORY_URL:latest
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $ECR_REPOSITORY_URL:$IMAGE_TAG
      
      - |
        if [ -n "${dockerhub_username}" ]; then
          echo "Tagging for DockerHub..."
          docker tag $IMAGE_REPO_NAME:latest ${dockerhub_username}/${project_name}:latest
          docker tag $IMAGE_REPO_NAME:$IMAGE_TAG ${dockerhub_username}/${project_name}:$IMAGE_TAG
        fi

  post_build:
    commands:
      - echo "Pushing images to ECR..."
      - docker push $ECR_REPOSITORY_URL:latest
      - docker push $ECR_REPOSITORY_URL:$IMAGE_TAG
      
      - |
        if [ -n "${dockerhub_username}" ]; then
          echo "Pushing images to DockerHub..."
          docker push ${dockerhub_username}/${project_name}:latest
          docker push ${dockerhub_username}/${project_name}:$IMAGE_TAG
        fi
      
      - echo "Writing image definitions file..."
      - printf '[{"name":"%s-container-%s","imageUri":"%s"}]' "${project_name}" "${environment}" "$ECR_REPOSITORY_URL:latest" > imagedefinitions.json
      
      - echo "Displaying image definitions:"
      - cat imagedefinitions.json
      
      - echo "Build completed successfully!"

artifacts:
  files:
    - imagedefinitions.json
  discard-paths: yes
