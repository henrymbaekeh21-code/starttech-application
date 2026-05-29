#!/bin/bash
# ============================================================================
# Deploy Frontend Script
# ============================================================================
# Builds React app and deploys to S3 + CloudFront invalidation.
# ============================================================================

set -euo pipefail

S3_BUCKET="${S3_BUCKET:-}"
CLOUDFRONT_ID="${CLOUDFRONT_ID:-}"
API_URL="${API_URL:-}"

if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_ID" ]; then
  echo "Usage: S3_BUCKET=mybucket CLOUDFRONT_ID=E1234567890ABC API_URL=https://api.example.com ./scripts/deploy-frontend.sh"
  exit 1
fi

echo "=== Building frontend ==="
cd frontend
npm ci
REACT_APP_API_URL="$API_URL" npm run build

echo "=== Deploying to S3 ==="
aws s3 sync build/ "s3://$S3_BUCKET" \
  --delete \
  --cache-control "max-age=31536000,immutable" \
  --exclude "index.html"

aws s3 cp build/index.html "s3://$S3_BUCKET/index.html" \
  --cache-control "no-cache, no-store, must-revalidate"

echo "=== Invalidating CloudFront cache ==="
aws cloudfront create-invalidation \
  --distribution-id "$CLOUDFRONT_ID" \
  --paths "/*"

echo "=== Frontend deployed successfully! ==="
