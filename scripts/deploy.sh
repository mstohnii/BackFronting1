#!/bin/bash

# Full Stack App Deployment Script
set -e

echo "🚀 Full Stack App Deployment Script"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Parse command line arguments
ENVIRONMENT=${1:-development}

if [ "$ENVIRONMENT" = "production" ]; then
    COMPOSE_FILE="deploy/docker-compose.prod.yml"
    print_status "Deploying in PRODUCTION mode"
else
    COMPOSE_FILE="docker-compose.yml"
    print_status "Deploying in DEVELOPMENT mode"
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose -f $COMPOSE_FILE down

# Build and start services
print_status "Building and starting services..."
docker-compose -f $COMPOSE_FILE up -d --build

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Health check
print_status "Performing health checks..."

# Check if frontend is responding
if curl -s http://localhost > /dev/null; then
    print_status "Frontend is responding"
else
    print_error "Frontend is not responding"
    exit 1
fi

# Check if backend API is responding
if curl -s http://localhost/api/health > /dev/null; then
    print_status "Backend API is responding"
else
    print_error "Backend API is not responding"
    exit 1
fi

# Show running containers
print_status "Running containers:"
docker-compose -f $COMPOSE_FILE ps

# Show logs
print_warning "Recent logs:"
docker-compose -f $COMPOSE_FILE logs --tail=20

echo ""
print_status "🎉 Deployment successful!"
echo "Frontend: http://localhost"
echo "Backend API: http://localhost/api/health"
echo ""
echo "To view logs: docker-compose -f $COMPOSE_FILE logs -f"
echo "To stop: docker-compose -f $COMPOSE_FILE down"
