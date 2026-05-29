# StartTech Application

> Month 3 Assessment - Full-Stack Application with CI/CD

## Overview

This repository contains the StartTech full-stack application:
- **Frontend**: React SPA deployed to S3 + CloudFront
- **Backend**: Golang API deployed to EC2 via Docker

## CI/CD Pipelines

| Pipeline | Trigger | Stages |
|----------|---------|--------|
| `frontend-ci-cd.yml` | Push to `frontend/**` | Lint → Test → Build → Security Audit → S3 Deploy → CF Invalidate |
| `backend-ci-cd.yml` | Push to `backend/**` | Lint → Test → Security Scan → Docker Build → ECR Push → Rolling Update |

## Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | IAM role for OIDC authentication |
| `S3_BUCKET_NAME` | Frontend S3 bucket name |
| `CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID |
| `CLOUDFRONT_DOMAIN` | CloudFront domain name |
| `REACT_APP_API_URL` | Backend API URL for frontend |
| `ECR_REPOSITORY` | ECR repository URI |
| `ASG_NAME` | Auto Scaling Group name |
| `ALB_DNS_NAME` | ALB DNS for smoke tests |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy-frontend.sh` | Manual frontend deployment |
| `scripts/deploy-backend.sh` | Manual backend deployment |
| `scripts/health-check.sh` | Application health check |
| `scripts/rollback.sh` | Rollback to previous version |

## Quick Start

```bash
# Health check
API_URL=https://your-api.com ./scripts/health-check.sh

# Manual frontend deploy
S3_BUCKET=my-bucket CLOUDFRONT_ID=E123 API_URL=https://api.example.com ./scripts/deploy-frontend.sh

# Manual backend deploy
ECR_REPO=123.dkr.ecr.us-east-1.amazonaws.com/repo ASG_NAME=my-asg ./scripts/deploy-backend.sh

# Rollback
ECR_REPO=123.dkr.ecr.us-east-1.amazonaws.com/repo ASG_NAME=my-asg ./scripts/rollback.sh
```

## Backend Configuration

Environment variables (set via Launch Template user-data):

| Variable | Description |
|----------|-------------|
| `PORT` | Server port (default: 8080) |
| `MONGO_URI` | MongoDB Atlas connection string |
| `REDIS_ADDR` | ElastiCache Redis endpoint |
| `JWT_SECRET_KEY` | JWT signing secret |
| `ENABLE_CACHE` | Enable Redis caching |
| `LOG_LEVEL` | Log verbosity (DEBUG/INFO/WARN/ERROR) |

## Monitoring

- **CloudWatch Logs**: `/starttech/production/backend`
- **CloudWatch Dashboard**: StartTech production dashboard
- **CloudWatch Alarms**: CPU, latency, 5xx errors, healthy hosts
- **SNS Notifications**: Email alerts for critical alarms
