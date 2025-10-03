# BackFronting1 Deployment Guide

This guide covers all deployment options for the BackFronting1 full-stack application.

## 🚀 Quick Start

### Option 1: Terraform Deployment (Recommended)

**One-command deployment to AWS:**

```bash
./scripts/deploy-terraform.sh deploy
```

### Option 2: Local Development

```bash
make dev
```

### Option 3: Docker Production

```bash
make prod
```

## 📋 Prerequisites

### For Terraform Deployment

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **SSH Key Pair** in AWS account
5. **Git** for cloning the repository

### For Local Development

1. **Docker** and **Docker Compose**
2. **Node.js** >= 18 (optional, for local development)
3. **Git** for cloning the repository

## 🏗️ Infrastructure Architecture

### Terraform Deployment

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CloudFront    │    │   EC2 Instance  │    │   GitHub Repo  │
│   (CDN)         │◄───┤   (Docker)      │◄───┤   (Source)     │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   Global Users  │    │   VPC Network   │
│   (HTTPS)       │    │   (Security)    │
└─────────────────┘    └─────────────────┘
```

### Components

- **VPC**: Custom network with public subnet
- **EC2**: Single instance running Docker containers
- **Security Groups**: HTTP/HTTPS/SSH access
- **CloudFront**: Global CDN with SSL termination
- **Elastic IP**: Static public IP address
- **CloudWatch**: Monitoring and logging

## 🛠️ Deployment Methods

### Method 1: Terraform (Production)

**Best for:** Production deployments, AWS infrastructure

```bash
# 1. Clone the repository
git clone https://github.com/mstohnii/BackFronting1
cd BackFronting1

# 2. Configure AWS CLI
aws configure

# 3. Deploy infrastructure
./scripts/deploy-terraform.sh deploy

# 4. Access your application
# The script will output the URLs
```

**Features:**
- ✅ Automated infrastructure provisioning
- ✅ CloudFront CDN for global performance
- ✅ SSL/TLS termination
- ✅ Monitoring and logging
- ✅ Auto-scaling ready
- ✅ Production-grade security

### Method 2: Docker Compose (Local/Dev)

**Best for:** Local development, testing

```bash
# 1. Clone the repository
git clone https://github.com/mstohnii/BackFronting1
cd BackFronting1

# 2. Start development environment
make dev
# or
docker-compose up -d

# 3. Access application
open http://localhost
```

**Features:**
- ✅ Fast local development
- ✅ Hot reloading
- ✅ Easy debugging
- ✅ No AWS costs

### Method 3: Manual EC2 Deployment

**Best for:** Custom configurations, learning

```bash
# 1. Launch EC2 instance (Amazon Linux 2)
# 2. Install Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# 3. Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. Clone and deploy
git clone https://github.com/mstohnii/BackFronting1
cd BackFronting1
docker-compose -f deploy/docker-compose.prod.yml up -d
```

## 🔧 Configuration

### Environment Variables

#### Backend
```bash
NODE_ENV=production
PORT=3000
```

#### Frontend
```bash
VITE_API_URL=http://localhost/api
```

### Terraform Variables

Create `terraform/terraform.tfvars`:

```hcl
aws_region = "us-east-1"
project_name = "backfronting1"
instance_type = "t3.micro"
github_repo = "https://github.com/mstohnii/BackFronting1"
public_key_path = "~/.ssh/id_rsa.pub"
```

### Docker Configuration

#### Development
```yaml
# docker-compose.yml
services:
  backend:
    build: ./backend
    ports:
      - "3000:3000"
  frontend:
    build: ./frontend
    ports:
      - "80:80"
```

#### Production
```yaml
# deploy/docker-compose.prod.yml
services:
  backend:
    build: ./backend
    restart: unless-stopped
  frontend:
    build: ./frontend
    ports:
      - "80:80"
    restart: unless-stopped
```

## 📊 Monitoring & Logging

### CloudWatch Integration

The Terraform deployment includes:

- **System Metrics**: CPU, Memory, Disk usage
- **Application Logs**: Docker container logs
- **Health Checks**: Application endpoint monitoring
- **Custom Metrics**: Application-specific metrics

### Log Locations

```bash
# Application logs
docker-compose logs -f

# System logs
sudo journalctl -u backfronting1

# CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/backfronting1
```

### Health Checks

```bash
# Application health
curl http://localhost/api/health

# Container status
docker ps

# System status
/home/ec2-user/monitor.sh
```

## 🔒 Security

### Network Security

- **VPC**: Isolated network environment
- **Security Groups**: Restrictive firewall rules
- **HTTPS**: SSL/TLS termination at CloudFront
- **SSH**: Key-based authentication only

### Application Security

- **Helmet**: Security headers
- **CORS**: Configured for cross-origin requests
- **Input Validation**: Request body validation
- **Error Handling**: Secure error responses

### Data Security

- **Encrypted Storage**: EBS volume encryption
- **Secure Communication**: HTTPS everywhere
- **Access Control**: IAM-based permissions

## 🚀 Scaling

### Horizontal Scaling

```bash
# Add more EC2 instances
terraform apply -var="instance_count=3"

# Use Application Load Balancer
# Configure auto-scaling groups
# Add RDS for database persistence
```

### Vertical Scaling

```bash
# Increase instance size
terraform apply -var="instance_type=t3.large"

# Add more memory/CPU
# Optimize Docker container resources
```

### Performance Optimization

- **CloudFront**: Global CDN caching
- **Docker**: Multi-stage builds
- **Nginx**: Static file serving
- **Compression**: Gzip compression enabled

## 🛠️ Troubleshooting

### Common Issues

#### 1. Application Not Starting

```bash
# Check Docker status
sudo systemctl status docker

# View application logs
docker-compose logs -f

# Restart application
sudo systemctl restart backfronting1
```

#### 2. Health Check Failures

```bash
# Test backend API
curl http://localhost:3000/api/health

# Test frontend
curl http://localhost/

# Check container health
docker ps
```

#### 3. CloudFront Issues

```bash
# Check distribution status
aws cloudfront get-distribution --id <DISTRIBUTION_ID>

# Invalidate cache
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
```

#### 4. Network Connectivity

```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <SECURITY_GROUP_ID>

# Test connectivity
telnet <EC2_IP> 80
telnet <EC2_IP> 443
```

### Debug Commands

```bash
# SSH into EC2
ssh -i ~/.ssh/id_rsa ec2-user@<EC2_IP>

# Check system resources
top
df -h
free -h

# View all logs
sudo journalctl -f

# Docker debugging
docker system df
docker system prune
```

## 📈 Performance

### Optimization Tips

1. **Enable CloudFront caching** for static assets
2. **Use multi-stage Docker builds** for smaller images
3. **Configure Nginx caching** for static files
4. **Enable Gzip compression** for text assets
5. **Use CDN** for global content delivery

### Monitoring Metrics

- **Response Time**: API endpoint performance
- **Throughput**: Requests per second
- **Error Rate**: Failed request percentage
- **Resource Usage**: CPU, Memory, Disk utilization

## 🔄 CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy with Terraform
        run: ./scripts/deploy-terraform.sh deploy
```

### Automated Deployment

```bash
# Trigger deployment on push
git push origin main

# Deploy specific branch
git push origin feature-branch

# Rollback deployment
git revert <commit-hash>
```

## 📚 Additional Resources

- [Terraform Documentation](terraform/README.md)
- [Docker Documentation](https://docs.docker.com/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)

## 🆘 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review application logs
3. Check AWS CloudWatch logs
4. Verify security group configurations
5. Test network connectivity

## 📄 License

MIT License - feel free to use this project as a starting point for your own applications!
