#!/bin/bash

set -e

# Default configuration
APP_NAME="bun-app"
ENVIRONMENT="playground"  # Default environment

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -e|--environment)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [-e|--environment <environment>]"
      echo "  -e, --environment: Environment to deploy (playground or production)"
      echo "  -h, --help: Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "playground" && "$ENVIRONMENT" != "production" ]]; then
  echo -e "${RED}Error: Invalid environment '$ENVIRONMENT'. Must be 'playground' or 'production'.${NC}"
  exit 1
fi

echo -e "${YELLOW}Starting deployment of $APP_NAME to AWS ECS in $ENVIRONMENT environment...${NC}"

# Step 1: Select or create the appropriate Terraform workspace
echo -e "${GREEN}Setting up Terraform workspace for $ENVIRONMENT...${NC}"
CURRENT_WORKSPACE=$(terraform workspace show)

if [[ "$CURRENT_WORKSPACE" != "$ENVIRONMENT" ]]; then
  # Check if the workspace exists
  WORKSPACE_EXISTS=$(terraform workspace list | grep -c "$ENVIRONMENT")

  if [[ $WORKSPACE_EXISTS -eq 0 ]]; then
    echo -e "${YELLOW}Creating new workspace: $ENVIRONMENT${NC}"
    terraform workspace new "$ENVIRONMENT"
  else
    echo -e "${YELLOW}Switching to workspace: $ENVIRONMENT${NC}"
    terraform workspace select "$ENVIRONMENT"
  fi
else
  echo -e "${GREEN}Already using workspace: $ENVIRONMENT${NC}"
fi

# Step 2: Initialize Terraform
echo -e "${GREEN}Initializing Terraform...${NC}"
terraform init

# Step 3: Deploy the infrastructure
echo -e "${GREEN}Deploying the infrastructure for $ENVIRONMENT environment...${NC}"
terraform apply -var="environment=$ENVIRONMENT"

# Step 4: Get the ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${YELLOW}Your application is available at: http://$ALB_DNS${NC}"
echo -e "${GREEN}Make sure you've pushed your Docker image to the repository specified${NC}"
echo -e "${GREEN}And uploaded the appropriate .env file to the S3 bucket for $ENVIRONMENT environment${NC}"
