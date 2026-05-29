#!/bin/bash
# ============================================================================
# Deploy Backend Script
# ============================================================================
# Builds Docker image, pushes to ECR, triggers rolling update.
# ============================================================================

set -euo pipefail

ECR_REPO="${ECR_REPO:-}"
ASG_NAME="${ASG_NAME:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [ -z "$ECR_REPO" ] || [ -z "$ASG_NAME" ]; then
  echo "Usage: ECR_REPO=123.dkr.ecr.us-east-1.amazonaws.com/myrepo ASG_NAME=my-asg ./scripts/deploy-backend.sh"
  exit 1
fi

echo "=== Building Docker image ==="
cd backend
docker build -t "${ECR_REPO}:latest" .
docker tag "${ECR_REPO}:latest" "${ECR_REPO}:$(git rev-parse --short HEAD)"

echo "=== Pushing to ECR ==="
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${ECR_REPO%%/*}"
docker push "${ECR_REPO}:latest"
docker push "${ECR_REPO}:$(git rev-parse --short HEAD)"

echo "=== Triggering rolling update ==="
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --strategy Rolling \
  --preferences MinHealthyPercentage=50,InstanceWarmup=300

echo "=== Deployment started! ==="
echo "Monitor with: aws autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME"
