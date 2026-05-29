#!/bin/bash
# ============================================================================
# Rollback Script
# ============================================================================
# Rolls back backend deployment to a previous version.
# ============================================================================

set -euo pipefail

ECR_REPO="${ECR_REPO:-}"
ASG_NAME="${ASG_NAME:-}"

if [ -z "$ECR_REPO" ] || [ -z "$ASG_NAME" ]; then
  echo "Usage: ECR_REPO=123.dkr.ecr.us-east-1.amazonaws.com/myrepo ASG_NAME=my-asg ./scripts/rollback.sh [VERSION]"
  echo "  VERSION: Docker image tag to rollback to (default: previous)"
  exit 1
fi

VERSION="${1:-previous}"

echo "=== Rollback: $ASG_NAME -> $VERSION ==="

if [ "$VERSION" = "previous" ]; then
  # Get second most recent image
  VERSION=$(aws ecr describe-images --repository-name "${ECR_REPO##*/}" \
    --query 'imageDetails[?imageTags[0]!=`latest`] | sort_by(@, &imagePushedAt) | [-2].imageTags[0]' \
    --output text)
  echo "Rolling back to: $VERSION"
fi

# Tag the rollback version as latest
echo "=== Tagging $VERSION as latest ==="
MANIFEST=$(aws ecr batch-get-image --repository-name "${ECR_REPO##*/}" \
  --image-ids imageTag="$VERSION" \
  --query 'images[0].imageManifest' --output text)

aws ecr put-image --repository-name "${ECR_REPO##*/}" \
  --image-tag latest \
  --image-manifest "$MANIFEST"

# Trigger rolling update
echo "=== Starting rolling update ==="
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --strategy Rolling \
  --preferences MinHealthyPercentage=50,InstanceWarmup=300

echo "=== Rollback initiated! ==="
