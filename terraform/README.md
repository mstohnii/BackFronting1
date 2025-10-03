# Terraform for BackFronting1 on EC2

This Terraform configuration provisions a single Ubuntu EC2 instance with SSM enabled, installs Docker via user data, clones the repository, and starts the containers using docker compose. The app exposes HTTP on port 80.

## Prerequisites

- Terraform >= 1.5
- AWS account with credentials configured (AWS_PROFILE or default)
- An existing EC2 key pair name if you want SSH access (optional)

## Files

- `versions.tf` – providers and required versions
- `variables.tf` – configurable inputs
- `main.tf` – EC2, IAM, SG, user data, outputs
- `userdata.sh` – boot script to install Docker and run the app

## Inputs

Key variables:

- `aws_region` (default `us-east-1`)
- `project_name` (default `backfronting1`)
- `instance_type` (default `t3.micro`)
- `key_name` (optional)
- `vpc_id`, `subnet_id` (optional, default VPC/subnet used if omitted)
- `allowed_ssh_cidr` (default `0.0.0.0/0`)
- `github_repo_url` (default `https://github.com/mstohnii/BackFronting1.git`)
- `use_prod_compose` (default `true`, uses `deploy/docker-compose.prod.yml`)
- `compose_file` (fallback compose path if not using prod file)

## Usage

```bash
cd terraform
terraform init
terraform plan -out=tfplan \
  -var "aws_region=us-east-1" \
  -var "instance_type=t3.small" \
  -var "key_name=YOUR_KEYPAIR_NAME" \
  -var "allowed_ssh_cidr=YOUR_IP/32"
terraform apply tfplan
```

After apply, outputs include `public_ip`, `public_dns`, `instance_id`, and `app_url` like `http://<dns-name>`.

## SSH (optional)

```bash
ssh -i /path/to/key.pem ubuntu@<public_ip>
```

## Destroy

```bash
terraform destroy -auto-approve
```

## Notes

- Instance uses the latest Ubuntu 22.04 LTS AMI.
- Security group opens ports 80/443 to the world and 22 to `allowed_ssh_cidr`.
- The user data clones the repo into `/opt/app/BackFronting1` and runs compose.
