#!/bin/bash

set -e

# Configuration
APP_NAME="bun-app"      # Should match your app_name in terraform.tfvars

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment of $APP_NAME infrastructure to AWS ECS...${NC}"

# Step 1: Initialize Terraform
echo -e "${GREEN}Initializing Terraform...${NC}"
terraform init

# Step 2: Deploy the infrastructure
echo -e "${GREEN}Deploying the infrastructure...${NC}"
terraform apply

# Step 3: Get the ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${YELLOW}Your application is available at: http://$ALB_DNS${NC}"
echo -e "${GREEN}Make sure you've pushed your Docker image to the repository specified in terraform.tfvars${NC}"
