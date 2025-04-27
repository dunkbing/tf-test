#!/bin/bash

set -e

# Configuration
AWS_REGION="us-west-1"  # Your AWS region
APP_NAME="bun-app"      # Should match your app_name in terraform.tfvars

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting ACM certificate validation process...${NC}"

# Step 1: Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
  echo -e "${GREEN}Initializing Terraform...${NC}"
  terraform init
fi

# Step 2: Apply the configuration to create the certificate (without HTTPS listener)
echo -e "${GREEN}Creating ACM certificate...${NC}"
terraform apply -target=aws_acm_certificate.cert -auto-approve

# Step 3: Get the validation details
echo -e "${YELLOW}Certificate created. Here are the validation details:${NC}"
terraform output -json certificate_validation_details | jq

# Step 4: Get certificate ARN directly from AWS
echo -e "${GREEN}Getting certificate ARN...${NC}"
DOMAIN=$(terraform output -json domain_name | jq -r .)
SUBDOMAIN=$(terraform output -json subdomain | jq -r .)
FQDN="${SUBDOMAIN}.${DOMAIN}"

CERT_ARN=$(aws acm list-certificates --region $AWS_REGION | jq -r --arg FQDN "$FQDN" '.CertificateSummaryList[] | select(.DomainName==$FQDN) | .CertificateArn')

if [ -z "$CERT_ARN" ]; then
  echo -e "${RED}Could not find certificate ARN for $FQDN. Please check your AWS Console.${NC}"
  exit 1
fi

echo -e "${GREEN}Found certificate ARN: $CERT_ARN${NC}"

echo -e "\n${YELLOW}IMPORTANT: You need to add the validation records to your DNS provider (Cloudflare).${NC}"
echo -e "${YELLOW}Once you've added the records, wait a few minutes for DNS propagation.${NC}"
echo -e "${YELLOW}Then press Enter to continue...${NC}"
read -p ""

# Step 5: Check certificate validation status
echo -e "${GREEN}Checking certificate validation status...${NC}"

echo -e "${YELLOW}Waiting for certificate validation (this may take several minutes)...${NC}"
aws acm wait certificate-validated --certificate-arn $CERT_ARN --region $AWS_REGION

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Certificate successfully validated!${NC}"
  echo -e "${GREEN}You can now deploy the full infrastructure with HTTPS support:${NC}"
  echo -e "${YELLOW}Run: terraform apply${NC}"
else
  echo -e "${RED}Certificate validation timed out.${NC}"
  echo -e "${YELLOW}Please check your DNS records again and try later.${NC}"
  echo -e "${YELLOW}You can check certificate status with:${NC}"
  echo -e "aws acm describe-certificate --certificate-arn $CERT_ARN --region $AWS_REGION"
fi
