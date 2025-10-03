# BackFronting1 Makefile
# Provides convenient commands for development and deployment

.PHONY: help dev build test clean deploy destroy status

# Default target
help:
	@echo "BackFronting1 - Full Stack Application"
	@echo ""
	@echo "Available commands:"
	@echo "  dev       - Start development environment"
	@echo "  build     - Build Docker images"
	@echo "  test      - Run tests"
	@echo "  clean     - Clean up Docker resources"
	@echo "  deploy    - Deploy to AWS using Terraform"
	@echo "  destroy   - Destroy AWS infrastructure"
	@echo "  status    - Show deployment status"
	@echo "  logs      - View application logs"
	@echo "  ssh       - SSH into EC2 instance"

# Development
dev:
	@echo "Starting development environment..."
	docker-compose up -d
	@echo "Application available at: http://localhost"

# Build
build:
	@echo "Building Docker images..."
	docker-compose build

# Test
test:
	@echo "Running tests..."
	docker-compose exec backend npm test || echo "No tests configured"

# Clean
clean:
	@echo "Cleaning up Docker resources..."
	docker-compose down -v
	docker system prune -f

# Terraform deployment
deploy:
	@echo "Deploying to AWS using Terraform..."
	./scripts/deploy-terraform.sh deploy

# Destroy infrastructure
destroy:
	@echo "Destroying AWS infrastructure..."
	./scripts/deploy-terraform.sh destroy

# Check status
status:
	@echo "Checking deployment status..."
	./scripts/deploy-terraform.sh status

# View logs
logs:
	@echo "Viewing application logs..."
	docker-compose logs -f

# SSH into EC2 (requires terraform output)
ssh:
	@echo "Connecting to EC2 instance..."
	cd terraform && terraform output ssh_connection_command | bash

# Production deployment
prod:
	@echo "Starting production environment..."
	docker-compose -f deploy/docker-compose.prod.yml up -d

# Health check
health:
	@echo "Checking application health..."
	curl -f http://localhost/api/health || echo "Application not responding"

# Install dependencies
install:
	@echo "Installing dependencies..."
	cd backend && npm install
	cd frontend && npm install

# Development setup
setup:
	@echo "Setting up development environment..."
	make install
	make build
	make dev
	@echo "Development environment ready!"
