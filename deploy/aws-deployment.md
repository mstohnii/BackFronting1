# AWS Deployment Guide

This guide explains how to deploy your Full Stack application to AWS with CloudFront.

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Docker installed on your deployment machine
3. An AWS account with CloudFormation permissions

## Deployment Steps

### 1. Deploy to EC2 with Docker

```bash
# Create an EC2 instance (Ubuntu 20.04 LTS recommended)
# Install Docker and Docker Compose
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Clone your repository
git clone <your-repo-url>
cd BackFronting1

# Build and run the application
docker-compose -f deploy/docker-compose.prod.yml up -d

# Verify services are running
docker-compose -f deploy/docker-compose.prod.yml ps
```

### 2. Set up Application Load Balancer (ALB)

```bash
# Create ALB with the following configuration:
# - Target Group: Point to your EC2 instance on port 80
# - Health Check: HTTP /api/health
# - Security Group: Allow HTTP (80) and HTTPS (443) from 0.0.0.0/0
```

### 3. Deploy CloudFront Distribution

```bash
# Update the OriginDomainName parameter with your ALB domain
aws cloudformation deploy \
  --template-file cloudformation/cloudfront-stack.yaml \
  --stack-name fullstack-cloudfront \
  --parameter-overrides \
    OriginDomainName=your-alb-domain.us-east-1.elb.amazonaws.com \
  --region us-east-1
```

### 4. Get CloudFront URL

```bash
aws cloudformation describe-stacks \
  --stack-name fullstack-cloudfront \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomainName`].OutputValue' \
  --output text
```

## Security Considerations

1. **Security Groups**: Only allow necessary ports (80, 443, 22)
2. **IAM Roles**: Use least-privilege principle
3. **SSL/TLS**: Use ACM certificates for HTTPS
4. **Updates**: Regularly update Docker images and OS packages

## Monitoring

- CloudWatch for application metrics
- ALB access logs for request monitoring
- CloudFront metrics for CDN performance

## Scaling

- Use Auto Scaling Groups for horizontal scaling
- ECS or EKS for container orchestration at scale
- RDS for managed database services
