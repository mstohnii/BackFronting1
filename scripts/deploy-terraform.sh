#!/bin/bash

# Deployment script for BackFronting1 Terraform infrastructure
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "terraform/main.tf" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    # Check if aws cli is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI"
        exit 1
    fi
    
    # Check if aws is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure'"
        exit 1
    fi
    
    # Check if SSH key exists
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        print_error "SSH public key not found at ~/.ssh/id_rsa.pub"
        print_status "Please generate an SSH key pair:"
        print_status "ssh-keygen -t rsa -b 4096 -C 'your_email@example.com'"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    cd terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_status "Please edit terraform/terraform.tfvars with your values"
        print_status "At minimum, update the public_key_path if your SSH key is not at ~/.ssh/id_rsa.pub"
    fi
    
    terraform init
    print_success "Terraform initialized"
}

# Plan deployment
plan_deployment() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_success "Terraform plan created"
}

# Apply deployment
apply_deployment() {
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    print_success "Infrastructure deployed successfully"
}

# Get deployment info
get_deployment_info() {
    print_status "Getting deployment information..."
    
    echo ""
    echo "=========================================="
    echo "🚀 BackFronting1 Deployment Complete!"
    echo "=========================================="
    echo ""
    
    # Get outputs
    EC2_IP=$(terraform output -raw instance_public_ip)
    CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)
    SSH_CMD=$(terraform output -raw ssh_connection_command)
    
    echo "📱 Application URLs:"
    echo "   Direct EC2:    http://$EC2_IP"
    echo "   CloudFront:    $CLOUDFRONT_URL"
    echo ""
    echo "🔑 SSH Access:"
    echo "   $SSH_CMD"
    echo ""
    echo "📊 Monitoring:"
    echo "   AWS Console:   https://console.aws.amazon.com"
    echo "   CloudWatch:    https://console.aws.amazon.com/cloudwatch"
    echo ""
    echo "🛠️  Management Commands:"
    echo "   Check status:  ssh -i ~/.ssh/id_rsa ec2-user@$EC2_IP 'sudo systemctl status backfronting1'"
    echo "   View logs:     ssh -i ~/.ssh/id_rsa ec2-user@$EC2_IP 'docker-compose -f /home/ec2-user/app/docker-compose.prod.yml logs'"
    echo "   Health check:  ssh -i ~/.ssh/id_rsa ec2-user@$EC2_IP '/home/ec2-user/health-check.sh'"
    echo ""
    echo "=========================================="
}

# Wait for application to be ready
wait_for_application() {
    print_status "Waiting for application to be ready..."
    
    EC2_IP=$(terraform output -raw instance_public_ip)
    MAX_ATTEMPTS=30
    ATTEMPT=0
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if curl -s -f "http://$EC2_IP/api/health" > /dev/null 2>&1; then
            print_success "Application is ready!"
            return 0
        fi
        
        ATTEMPT=$((ATTEMPT + 1))
        print_status "Attempt $ATTEMPT/$MAX_ATTEMPTS - Waiting for application..."
        sleep 10
    done
    
    print_warning "Application may not be fully ready yet. Please check manually."
}

# Cleanup function
cleanup() {
    if [ -f "terraform/tfplan" ]; then
        rm terraform/tfplan
    fi
}

# Main deployment function
deploy() {
    print_status "Starting BackFronting1 Terraform deployment..."
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    check_prerequisites
    init_terraform
    plan_deployment
    
    # Ask for confirmation
    echo ""
    print_warning "This will create AWS resources that may incur costs."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled"
        exit 0
    fi
    
    apply_deployment
    wait_for_application
    get_deployment_info
    
    print_success "Deployment completed successfully!"
}

# Help function
show_help() {
    echo "BackFronting1 Terraform Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  deploy     Deploy the infrastructure (default)"
    echo "  destroy    Destroy the infrastructure"
    echo "  status     Show deployment status"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 destroy"
    echo "  $0 status"
}

# Destroy function
destroy_infrastructure() {
    print_status "Destroying infrastructure..."
    cd terraform
    
    print_warning "This will permanently delete all AWS resources!"
    read -p "Are you sure? Type 'yes' to confirm: " -r
    echo ""
    
    if [[ $REPLY == "yes" ]]; then
        terraform destroy -auto-approve
        print_success "Infrastructure destroyed"
    else
        print_status "Destruction cancelled"
    fi
}

# Status function
show_status() {
    print_status "Checking deployment status..."
    cd terraform
    
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "No Terraform state found. Infrastructure may not be deployed."
        exit 1
    fi
    
    echo ""
    echo "=========================================="
    echo "📊 Deployment Status"
    echo "=========================================="
    echo ""
    
    terraform output
    
    echo ""
    echo "=========================================="
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    destroy)
        destroy_infrastructure
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
