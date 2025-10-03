#!/bin/bash

# Terraform validation script for BackFronting1
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_status "Validating Terraform configuration..."

cd terraform

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    exit 1
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init -backend=false

# Validate configuration
print_status "Validating Terraform configuration..."
if terraform validate; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform configuration has errors"
    exit 1
fi

# Format check
print_status "Checking Terraform formatting..."
if terraform fmt -check -diff; then
    print_success "Terraform files are properly formatted"
else
    print_warning "Terraform files need formatting. Run 'terraform fmt' to fix"
fi

# Security scan (if tfsec is available)
if command -v tfsec &> /dev/null; then
    print_status "Running security scan..."
    if tfsec .; then
        print_success "No security issues found"
    else
        print_warning "Security issues found. Review the output above"
    fi
else
    print_warning "tfsec not installed. Install it for security scanning:"
    print_warning "  brew install tfsec  # macOS"
    print_warning "  go install github.com/aquasecurity/tfsec/cmd/tfsec@latest  # Go"
fi

# Check for required files
print_status "Checking required files..."

required_files=(
    "main.tf"
    "variables.tf"
    "outputs.tf"
    "versions.tf"
    "user_data.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ $file exists"
    else
        print_error "✗ $file is missing"
        exit 1
    fi
done

# Check if tfvars file exists
if [ -f "terraform.tfvars" ]; then
    print_success "✓ terraform.tfvars exists"
else
    print_warning "⚠ terraform.tfvars not found"
    print_warning "Copy terraform.tfvars.example to terraform.tfvars and customize it"
fi

# Check user_data.sh permissions
if [ -x "user_data.sh" ]; then
    print_success "✓ user_data.sh is executable"
else
    print_warning "⚠ user_data.sh is not executable"
    chmod +x user_data.sh
    print_success "✓ Fixed user_data.sh permissions"
fi

print_success "Terraform validation completed successfully!"
print_status "You can now run 'terraform plan' to see what will be created"
