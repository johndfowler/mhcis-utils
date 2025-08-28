#!/bin/bash

# Setup script for Git hooks and development environment
# Run this script to configure your development environment

set -e

echo "🚀 Setting up development environment..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ===========================================
# Git Hooks Setup
# ===========================================
echo -e "\n${YELLOW}📝 Setting up Git hooks...${NC}"

# Create hooks directory if it doesn't exist
if [ ! -d ".git/hooks" ]; then
    echo -e "${RED}❌ .git/hooks directory not found. Are you in a Git repository?${NC}"
    exit 1
fi

# Backup existing hooks
if [ -f ".git/hooks/pre-commit" ]; then
    echo "  📁 Backing up existing pre-commit hook..."
    mv ".git/hooks/pre-commit" ".git/hooks/pre-commit.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Copy our hooks
if [ -f ".git/hooks/pre-commit.ps1" ]; then
    echo "  ✅ PowerShell pre-commit hook already exists"
else
    echo "  📝 Installing PowerShell pre-commit hook..."
    cp ".git/hooks/pre-commit.ps1" ".git/hooks/pre-commit.ps1"
fi

if [ -f ".git/hooks/pre-commit" ]; then
    echo "  ✅ Bash pre-commit hook already exists"
else
    echo "  📝 Installing Bash pre-commit hook..."
    cp ".git/hooks/pre-commit" ".git/hooks/pre-commit"
    chmod +x ".git/hooks/pre-commit"
fi

echo -e "${GREEN}✅ Git hooks configured${NC}"

# ===========================================
# Tools Validation
# ===========================================
echo -e "\n${YELLOW}🔧 Validating development tools...${NC}"

# Check Azure CLI
if command -v az &> /dev/null; then
    echo -e "  ${GREEN}✅ Azure CLI is installed$(az version --query '"azure-cli"' -o tsv)${NC}"
else
    echo -e "  ${RED}❌ Azure CLI not found${NC}"
    echo "    Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

# Check Bicep
if az bicep version &> /dev/null; then
    echo -e "  ${GREEN}✅ Bicep CLI is available${NC}"
else
    echo -e "  ${RED}❌ Bicep CLI not available${NC}"
    echo "    Install with: az bicep install"
fi

# Check PowerShell
if command -v pwsh &> /dev/null; then
    echo -e "  ${GREEN}✅ PowerShell is available${NC}"
else
    echo -e "  ${YELLOW}⚠️  PowerShell not found (optional for Windows development)${NC}"
fi

# Check Node.js for markdownlint
if command -v node &> /dev/null; then
    echo -e "  ${GREEN}✅ Node.js is available$(node --version)${NC}"
else
    echo -e "  ${YELLOW}⚠️  Node.js not found (optional for markdownlint)${NC}"
fi

# ===========================================
# Configuration Validation
# ===========================================
echo -e "\n${YELLOW}⚙️  Validating configuration...${NC}"

# Check .bicepconfig.json
if [ -f ".bicepconfig.json" ]; then
    echo -e "  ${GREEN}✅ Bicep configuration found${NC}"
else
    echo -e "  ${RED}❌ .bicepconfig.json not found${NC}"
fi

# Check azure.yaml
if [ -f "azure.yaml" ]; then
    echo -e "  ${GREEN}✅ Azure Developer CLI configuration found${NC}"
else
    echo -e "  ${RED}❌ azure.yaml not found${NC}"
fi

# Check main template
if [ -f "infra/main.bicep" ]; then
    echo -e "  ${GREEN}✅ Main Bicep template found${NC}"
else
    echo -e "  ${RED}❌ infra/main.bicep not found${NC}"
fi

# Check parameters file
if [ -f "infra/main.parameters.json" ]; then
    echo -e "  ${GREEN}✅ Parameters file found${NC}"
else
    echo -e "  ${RED}❌ infra/main.parameters.json not found${NC}"
fi

# ===========================================
# Test Validation
# ===========================================
echo -e "\n${YELLOW}🧪 Running test validation...${NC}"

# Test Bicep build
if [ -f "infra/main.bicep" ]; then
    if az bicep build --file infra/main.bicep --stdout > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Main template builds successfully${NC}"
    else
        echo -e "  ${RED}❌ Main template has build errors${NC}"
    fi
fi

# Test linting script
if [ -f "scripts/lint.sh" ]; then
    if [ -x "scripts/lint.sh" ]; then
        echo -e "  ${GREEN}✅ Linting script is executable${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Linting script is not executable${NC}"
        chmod +x scripts/lint.sh
        echo -e "  ${GREEN}✅ Fixed: Made linting script executable${NC}"
    fi
fi

# ===========================================
# Success Message
# ===========================================
echo -e "\n${GREEN}🎉 Development environment setup complete!${NC}"
echo ""
echo "📋 What's configured:"
echo "  • Git pre-commit hooks for code quality"
echo "  • Bicep linting and validation"
echo "  • JSON/YAML validation"
echo "  • CI/CD workflows for GitHub Actions"
echo ""
echo "🚀 Next steps:"
echo "  1. Run './scripts/lint.sh' to test linting"
echo "  2. Try 'az bicep build --file infra/main.bicep' to test builds"
echo "  3. Make a test commit to validate Git hooks"
echo "  4. Push to GitHub to test CI/CD workflows"
echo ""
echo "📚 Useful commands:"
echo "  • az bicep lint --file infra/main.bicep    # Lint Bicep files"
echo "  • az bicep build --file infra/main.bicep   # Build templates"
echo "  • ./scripts/lint.sh                       # Run all validations"
echo "  • azd up                                  # Deploy with Azure Developer CLI"
