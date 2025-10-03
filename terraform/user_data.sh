#!/bin/bash

# User data script for BackFronting1 application deployment
# This script will be executed when the EC2 instance starts

set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Git
yum install -y git

# Install Node.js (for potential local development)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create application directory
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Clone the repository
git clone ${github_repo} .

# Create production docker-compose file
cat > docker-compose.prod.yml << 'EOF'
services:
  backend:
    build: ./backend
    container_name: backend
    networks:
      - appnet
    expose:
      - "3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build: ./frontend
    container_name: frontend
    ports:
      - "80:80"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - appnet
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  appnet:
    driver: bridge
EOF

# Create systemd service for the application
cat > /etc/systemd/system/backfronting1.service << EOF
[Unit]
Description=BackFronting1 Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user/app
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
TimeoutStartSec=0
User=ec2-user

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable backfronting1.service

# Wait for Docker to be ready
sleep 30

# Start the application
systemctl start backfronting1.service

# Create a simple health check script
cat > /home/ec2-user/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for the application

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    echo "Docker is not running"
    exit 1
fi

# Check if the application containers are running
if ! docker ps | grep -q "backend\|frontend"; then
    echo "Application containers are not running"
    exit 1
fi

# Check if the application is responding
if ! curl -f http://localhost/api/health > /dev/null 2>&1; then
    echo "Application is not responding"
    exit 1
fi

echo "Application is healthy"
exit 0
EOF

chmod +x /home/ec2-user/health-check.sh

# Create a log rotation configuration
cat > /etc/logrotate.d/docker-containers << 'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# Set up CloudWatch agent (optional)
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/lib/docker/containers/*/*.log",
                        "log_group_name": "/aws/ec2/backfronting1/docker",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create a simple monitoring script
cat > /home/ec2-user/monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script

echo "=== System Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Memory Usage:"
free -h
echo "Disk Usage:"
df -h
echo "Docker Status:"
docker ps
echo "Application Health:"
/home/ec2-user/health-check.sh
EOF

chmod +x /home/ec2-user/monitor.sh

# Create a backup script
cat > /home/ec2-user/backup.sh << 'EOF'
#!/bin/bash
# Backup script for the application

BACKUP_DIR="/home/ec2-user/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup application code
tar -czf $BACKUP_DIR/app_$DATE.tar.gz -C /home/ec2-user app

# Keep only last 7 days of backups
find $BACKUP_DIR -name "app_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/app_$DATE.tar.gz"
EOF

chmod +x /home/ec2-user/backup.sh

# Set up cron job for daily backup
echo "0 2 * * * /home/ec2-user/backup.sh" | crontab -u ec2-user -

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log
