#!/bin/bash
# 🎓 Setup script for GitHub Actions with Azure OIDC
# This script configures passwordless authentication between GitHub and Azure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "======================================"
echo "🚀 GitHub Actions Azure OIDC Setup"
echo "======================================"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

command -v az >/dev/null 2>&1 || { print_error "Azure CLI is required but not installed."; exit 1; }
command -v gh >/dev/null 2>&1 || { print_error "GitHub CLI is required but not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { print_error "jq is required but not installed."; exit 1; }

print_success "Prerequisites check passed"

# Get inputs
echo ""
print_info "Please provide the following information:"
echo ""

read -p "GitHub Organization/Username: " GITHUB_ORG
read -p "GitHub Repository Name: " GITHUB_REPO
read -p "Azure Subscription ID: " SUBSCRIPTION_ID
read -p "Azure Resource Group Name [rg-ecommerce-dev]: " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-rg-ecommerce-dev}

read -p "Service Principal Name [github-actions-ecommerce]: " SP_NAME
SP_NAME=${SP_NAME:-github-actions-ecommerce}

# Login to Azure
echo ""
print_info "Logging in to Azure..."
az login --output none
az account set --subscription "$SUBSCRIPTION_ID"
print_success "Logged in to Azure"

# Create Service Principal
echo ""
print_info "Creating Service Principal..."

SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --sdk-auth)

CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.clientId')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenantId')
OBJECT_ID=$(az ad sp show --id $CLIENT_ID --query id -o tsv)

print_success "Service Principal created"
echo "  Client ID: $CLIENT_ID"
echo "  Tenant ID: $TENANT_ID"
echo "  Object ID: $OBJECT_ID"

# Configure Federated Credentials for OIDC
echo ""
print_info "Configuring OIDC Federated Credentials..."

# For main branch
print_info "Creating federated credential for main branch..."
cat > federated-credential-main.json << EOF
{
  "name": "github-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main",
  "description": "GitHub Actions for main branch",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az ad app federated-credential create \
  --id $CLIENT_ID \
  --parameters @federated-credential-main.json

print_success "Federated credential for main branch created"

# For develop branch
print_info "Creating federated credential for develop branch..."
cat > federated-credential-develop.json << EOF
{
  "name": "github-develop-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/develop",
  "description": "GitHub Actions for develop branch",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az ad app federated-credential create \
  --id $CLIENT_ID \
  --parameters @federated-credential-develop.json

print_success "Federated credential for develop branch created"

# For pull requests
print_info "Creating federated credential for pull requests..."
cat > federated-credential-pr.json << EOF
{
  "name": "github-pull-requests",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$GITHUB_ORG/$GITHUB_REPO:pull_request",
  "description": "GitHub Actions for Pull Requests",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az ad app federated-credential create \
  --id $CLIENT_ID \
  --parameters @federated-credential-pr.json

print_success "Federated credential for pull requests created"

# For environments (production)
print_info "Creating federated credential for production environment..."
cat > federated-credential-prod.json << EOF
{
  "name": "github-production-env",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$GITHUB_ORG/$GITHUB_REPO:environment:production",
  "description": "GitHub Actions for Production Environment",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az ad app federated-credential create \
  --id $CLIENT_ID \
  --parameters @federated-credential-prod.json

print_success "Federated credential for production environment created"

# Assign additional roles
echo ""
print_info "Assigning Azure roles..."

# Get resource IDs
ACR_NAME="acrecommercedev"
AKS_NAME="aks-ecommerce-dev"
KV_NAME="kv-ecommerce-dev"

# ACR Push/Pull permissions
if az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
  ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
  az role assignment create \
    --assignee $OBJECT_ID \
    --role "AcrPush" \
    --scope $ACR_ID
  print_success "ACR permissions granted"
else
  print_warning "ACR $ACR_NAME not found"
fi

# AKS permissions
if az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
  AKS_ID=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
  az role assignment create \
    --assignee $OBJECT_ID \
    --role "Azure Kubernetes Service Cluster User Role" \
    --scope $AKS_ID
  print_success "AKS permissions granted"
else
  print_warning "AKS $AKS_NAME not found"
fi

# Key Vault permissions
if az keyvault show --name $KV_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
  az keyvault set-policy \
    --name $KV_NAME \
    --object-id $OBJECT_ID \
    --secret-permissions get list \
    --key-permissions get list
  print_success "Key Vault permissions granted"
else
  print_warning "Key Vault $KV_NAME not found"
fi

# Configure GitHub Secrets
echo ""
print_info "Configuring GitHub Secrets..."

# Check if we're in a git repository
if [ -d .git ]; then
  print_info "Setting GitHub secrets using GitHub CLI..."
  
  gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
  gh secret set AZURE_TENANT_ID --body "$TENANT_ID"
  gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
  
  print_success "GitHub secrets configured"
else
  print_warning "Not in a git repository. Please set these secrets manually in GitHub:"
  echo ""
  echo "AZURE_CLIENT_ID=$CLIENT_ID"
  echo "AZURE_TENANT_ID=$TENANT_ID"
  echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
fi

# Create GitHub environments
echo ""
print_info "Creating GitHub environments..."

if [ -d .git ]; then
  # Create environments
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    /repos/$GITHUB_ORG/$GITHUB_REPO/environments/development \
    -f wait_timer=0
    
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    /repos/$GITHUB_ORG/$GITHUB_REPO/environments/staging \
    -f wait_timer=0
    
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    /repos/$GITHUB_ORG/$GITHUB_REPO/environments/production \
    -f wait_timer=0 \
    -F 'reviewers[][type]=User' \
    -F 'reviewers[][id]=1'  # Add reviewer IDs
    
  print_success "GitHub environments created"
else
  print_warning "Please create environments manually in GitHub repository settings"
fi

# Test OIDC connection
echo ""
print_info "Testing OIDC connection..."

cat > test-oidc.yml << 'EOF'
name: Test OIDC Connection
on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: List Resource Groups
        run: az group list -o table
EOF

print_success "Test workflow created: test-oidc.yml"
print_info "Run this workflow to test the OIDC connection"

# Cleanup
rm -f federated-credential-*.json

# Summary
echo ""
echo "======================================"
echo "✅ Setup Complete!"
echo "======================================"
echo ""
echo "📋 Summary:"
echo "  • Service Principal: $SP_NAME"
echo "  • Client ID: $CLIENT_ID"
echo "  • Tenant ID: $TENANT_ID"
echo "  • Subscription: $SUBSCRIPTION_ID"
echo ""
echo "🔐 GitHub Secrets to Configure:"
echo "  • AZURE_CLIENT_ID ✅"
echo "  • AZURE_TENANT_ID ✅"
echo "  • AZURE_SUBSCRIPTION_ID ✅"
echo ""
echo "📦 Optional secrets to add:"
echo "  • MS_TEAMS_WEBHOOK"
echo "  • SLACK_WEBHOOK_URL"
echo "  • SONAR_TOKEN"
echo ""
echo "🎯 Next Steps:"
echo "  1. Commit and push the workflow files"
echo "  2. Run the test-oidc.yml workflow to verify connection"
echo "  3. Configure additional secrets as needed"
echo "  4. Start using the CI/CD pipeline!"
echo ""
print_success "Happy deploying! 🚀"