variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project/name prefix for resource tagging"
  type        = string
  default     = "backfronting1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name for SSH access"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "Optional: existing VPC ID to deploy into. If null, default VPC is used"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Optional: existing public subnet ID in the chosen VPC. If null, attempts to use a default VPC public subnet"
  type        = string
  default     = null
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "github_repo_url" {
  description = "Git repository URL to clone and deploy"
  type        = string
  default     = "https://github.com/mstohnii/BackFronting1.git"
}

variable "compose_file" {
  description = "docker-compose file path to use (relative to repo root). For prod, use deploy/docker-compose.prod.yml"
  type        = string
  default     = "docker-compose.yml"
}

variable "use_prod_compose" {
  description = "If true, use deploy/docker-compose.prod.yml"
  type        = bool
  default     = true
}


