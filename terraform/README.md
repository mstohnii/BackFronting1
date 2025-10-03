# BackFronting1 Terraform Infrastructure

This Terraform configuration deploys the BackFronting1 full-stack application on AWS EC2 with CloudFront CDN.

## Architecture

- **VPC**: Custom VPC with public subnet
- **EC2**: Single instance running Docker containers
- **Security Groups**: Configured for HTTP/HTTPS/SSH access
- **CloudFront**: CDN distribution for global content delivery
- **Monitoring**: CloudWatch agent for logs and metrics

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **SSH key pair** in your AWS account
4. **Public key file** available locally

## Quick Start

1. **Clone and navigate to terraform directory:**
   ```bash
   cd terraform
   ```

2. **Copy and customize variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure:**
   ```bash
   terraform apply
   ```

6. **Access your application:**
   - Direct EC2: `http://<EC2_PUBLIC_IP>`
   - CloudFront: `https://<CLOUDFRONT_DOMAIN>`

## Configuration

### Required Variables

- `public_key_path`: Path to your SSH public key file
- `github_repo`: GitHub repository URL (default: https://github.com/mstohnii/BackFronting1)

### Optional Variables

- `aws_region`: AWS region (default: us-east-1)
- `instance_type`: EC2 instance type (default: t3.micro)
- `project_name`: Project name for resource naming
- `domain_name`: Custom domain name (optional)

## Infrastructure Components

### Networking
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.1.0/24 CIDR block
- **Internet Gateway**: For public internet access
- **Route Tables**: Configured for public access

### Security
- **Security Group**: Allows HTTP (80), HTTPS (443), SSH (22)
- **Key Pair**: For SSH access to EC2 instance
- **Encrypted EBS**: Root volume encryption enabled

### Compute
- **EC2 Instance**: Amazon Linux 2 with Docker
- **Elastic IP**: Static public IP address
- **User Data**: Automated application deployment

### Application Deployment
- **Docker**: Installed and configured
- **Docker Compose**: For multi-container orchestration
- **Git**: For cloning the repository
- **Systemd Service**: For automatic startup

### CDN
- **CloudFront**: Global content delivery
- **Custom Origins**: EC2 instance as origin
- **Caching Rules**: API routes not cached, static assets cached

## Application Features

### Automated Deployment
- Clones repository on instance startup
- Builds and runs Docker containers
- Configures systemd service for auto-start
- Sets up health checks and monitoring

### Monitoring & Logging
- **CloudWatch Agent**: System and application metrics
- **Log Rotation**: Docker container logs
- **Health Checks**: Application endpoint monitoring
- **Backup Scripts**: Daily application backups

### Security Features
- **Encrypted Storage**: EBS volume encryption
- **Security Groups**: Restrictive firewall rules
- **HTTPS Redirect**: CloudFront SSL/TLS termination
- **CORS Configuration**: Backend CORS headers

## Management Commands

### SSH Access
```bash
# Get the SSH command from Terraform output
terraform output ssh_connection_command
```

### Application Management
```bash
# Check application status
sudo systemctl status backfronting1

# View application logs
docker-compose -f /home/ec2-user/app/docker-compose.prod.yml logs

# Restart application
sudo systemctl restart backfronting1

# Run health check
/home/ec2-user/health-check.sh
```

### Monitoring
```bash
# View system status
/home/ec2-user/monitor.sh

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/backfronting1
```

## Scaling Considerations

### Horizontal Scaling
- Use Application Load Balancer (ALB)
- Multiple EC2 instances in different AZs
- Auto Scaling Group for dynamic scaling
- RDS for database persistence

### Vertical Scaling
- Increase instance type (t3.small, t3.medium, etc.)
- Add more CPU/memory resources
- Optimize Docker container resources

## Cost Optimization

### Current Setup
- **t3.micro**: Free tier eligible (750 hours/month)
- **EBS**: 20GB gp3 storage
- **CloudFront**: Pay-per-use CDN
- **Data Transfer**: Minimal for small applications

### Cost Reduction Tips
- Use Spot Instances for non-critical workloads
- Implement auto-shutdown for development
- Use S3 for static asset storage
- Optimize CloudFront caching rules

## Troubleshooting

### Common Issues

1. **Application not starting:**
   ```bash
   # Check Docker status
   sudo systemctl status docker
   
   # View application logs
   docker-compose -f /home/ec2-user/app/docker-compose.prod.yml logs
   ```

2. **Health check failures:**
   ```bash
   # Test backend API
   curl http://localhost:3000/api/health
   
   # Test frontend
   curl http://localhost/
   ```

3. **CloudFront issues:**
   ```bash
   # Check CloudFront distribution status
   aws cloudfront get-distribution --id <DISTRIBUTION_ID>
   ```

### Log Locations
- **Application logs**: `/var/lib/docker/containers/*/`
- **System logs**: `/var/log/messages`
- **User data logs**: `/var/log/user-data.log`
- **CloudWatch logs**: AWS Console > CloudWatch > Logs

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review CloudWatch logs
3. Check application health endpoints
4. Verify security group configurations
