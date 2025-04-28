#!/bin/bash

# Enable debugging and error tracing
set -ex

# Default configuration
AWS_REGION="us-west-1"  # Your AWS region
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
    -r|--region)
      AWS_REGION="$2"
      shift
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [-e|--environment <environment>] [-r|--region <aws-region>]"
      echo "  -e, --environment: Environment to validate certificate for (playground or production)"
      echo "  -r, --region: AWS region to use (default: us-west-1)"
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

echo -e "${YELLOW}Starting ACM certificate validation process for $ENVIRONMENT environment...${NC}"

# Step 1: Initialize Terraform first to ensure .terraform directory exists
echo -e "${GREEN}Initializing Terraform...${NC}"
terraform init

# Step 2: Select or create the appropriate Terraform workspace
echo -e "${GREEN}Setting up Terraform workspace for $ENVIRONMENT...${NC}"
CURRENT_WORKSPACE=$(terraform workspace show || echo "default")
echo "Current workspace: $CURRENT_WORKSPACE"

if [[ "$CURRENT_WORKSPACE" != "$ENVIRONMENT" ]]; then
  # Check if the workspace exists
  echo "Checking if workspace $ENVIRONMENT exists..."
  terraform workspace list

  # Try to select the workspace first
  if terraform workspace select "$ENVIRONMENT" 2>/dev/null; then
    echo -e "${GREEN}Switched to existing workspace: $ENVIRONMENT${NC}"
  else
    echo -e "${YELLOW}Creating new workspace: $ENVIRONMENT${NC}"
    terraform workspace new "$ENVIRONMENT"
  fi
else
  echo -e "${GREEN}Already using workspace: $ENVIRONMENT${NC}"
fi

# Verify workspace is correctly set
SELECTED_WORKSPACE=$(terraform workspace show)
echo "Selected workspace: $SELECTED_WORKSPACE"

# Step 3: Apply the configuration to create the certificate (without HTTPS listener)
echo -e "${GREEN}Creating ACM certificate for $ENVIRONMENT environment...${NC}"
terraform apply -target=aws_acm_certificate.cert -auto-approve

# Step 4: Get the validation details
echo -e "${YELLOW}Certificate created. Here are the validation details:${NC}"
terraform output -json certificate_validation_details || echo "No validation details available yet"

# Step 5: Get certificate ARN directly from AWS
echo -e "${GREEN}Getting certificate ARN...${NC}"
DOMAIN=$(terraform output -raw domain_name 2>/dev/null || echo "")
SUBDOMAIN=$(terraform output -raw subdomain 2>/dev/null || echo "")

if [ -z "$DOMAIN" ]; then
  echo "Domain name output not found. Will try to get the FQDN directly."
  FQDN=$(terraform output -raw fqdn 2>/dev/null || echo "")

  if [ -z "$FQDN" ]; then
    echo -e "${RED}Could not determine the domain name. Please check your Terraform configuration.${NC}"
    echo "Available outputs:"
    terraform output
    exit 1
  fi
else
  # Construct FQDN from domain and subdomain
  if [ -z "$SUBDOMAIN" ]; then
    echo "Subdomain output not found. Will use the domain as FQDN."
    FQDN="$DOMAIN"
  else
    FQDN="${SUBDOMAIN}.${DOMAIN}"
  fi
fi

echo -e "${GREEN}Looking for certificate for: $FQDN${NC}"

# List certificates to see what's available
echo "Listing available certificates in ACM:"
aws acm list-certificates --region $AWS_REGION

CERT_ARN=$(aws acm list-certificates --region $AWS_REGION | jq -r --arg FQDN "$FQDN" '.CertificateSummaryList[] | select(.DomainName==$FQDN) | .CertificateArn')

if [ -z "$CERT_ARN" ]; then
  echo -e "${RED}Could not find certificate ARN for $FQDN. Please check your AWS Console.${NC}"
  echo "The certificate might not have been created yet. Check the AWS ACM console and look for recent errors in Terraform output."
  exit 1
fi

echo -e "${GREEN}Found certificate ARN: $CERT_ARN${NC}"

echo -e "\n${YELLOW}IMPORTANT: You need to add the validation records to your DNS provider (Cloudflare).${NC}"
echo -e "${YELLOW}Once you've added the records, wait a few minutes for DNS propagation.${NC}"
echo -e "${YELLOW}Then press Enter to continue...${NC}"
read -p ""

# Step 6: Check certificate validation status
echo -e "${GREEN}Checking certificate validation status...${NC}"

echo -e "${YELLOW}Waiting for certificate validation (this may take several minutes)...${NC}"
aws acm wait certificate-validated --certificate-arn $CERT_ARN --region $AWS_REGION

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Certificate successfully validated!${NC}"
  echo -e "${GREEN}You can now deploy the full infrastructure with HTTPS support:${NC}"
  echo -e "${YELLOW}Run: ./deploy.sh --environment $ENVIRONMENT${NC}"
else
  echo -e "${RED}Certificate validation timed out.${NC}"
  echo -e "${YELLOW}Please check your DNS records again and try later.${NC}"
  echo -e "${YELLOW}You can check certificate status with:${NC}"
  echo -e "aws acm describe-certificate --certificate-arn $CERT_ARN --region $AWS_REGION"
fi
