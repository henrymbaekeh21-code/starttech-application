#!/bin/bash
# ============================================================================
# Health Check Script
# ============================================================================
# Checks application health endpoints and infrastructure status.
# ============================================================================

set -euo pipefail

API_URL="${API_URL:-http://localhost:8080}"
ALB_DNS="${ALB_DNS:-}"

if [ -n "$ALB_DNS" ]; then
  API_URL="http://$ALB_DNS"
fi

echo "========================================="
echo "  Health Check - $API_URL"
echo "========================================="
echo ""

# Backend health check
echo "1. Backend Health:"
if curl -sf "${API_URL}/health" > /dev/null 2>&1; then
  HEALTH=$(curl -sf "${API_URL}/health" 2>/dev/null)
  echo "   PASS - $HEALTH"
else
  echo "   FAIL - Backend is not responding"
  exit 1
fi

# Ping check
echo ""
echo "2. Ping Check:"
if curl -sf "${API_URL}/ping" > /dev/null 2>&1; then
  echo "   PASS - pong"
else
  echo "   FAIL - No response"
fi

# K8s pod status (if running locally)
if command -v kubectl &> /dev/null && kubectl get pods &> /dev/null; then
  echo ""
  echo "3. Kubernetes Pods:"
  kubectl get pods -n muchtodo 2>/dev/null || echo "   No pods in muchtodo namespace"
fi

# AWS resources (if configured)
if command -v aws &> /dev/null; then
  echo ""
  echo "4. AWS Resources:"
  
  # Check ALB target health
  if [ -n "${ALB_DNS:-}" ]; then
    TG_ARN=$(aws elbv2 describe-target-groups --query "TargetGroups[?contains(LoadBalancerArns[0], '$ALB_DNS')].TargetGroupArn" --output text 2>/dev/null || true)
    if [ -n "$TG_ARN" ]; then
      echo "   Target Health:"
      aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --query "TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]" --output table 2>/dev/null || echo "   Unable to fetch target health"
    fi
  fi
fi

echo ""
echo "========================================="
echo "  All checks complete!"
echo "========================================="
