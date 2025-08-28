#!/bin/bash

# Git Setup Script for Cloud-Native DevOps Platform
# This script initializes Git and sets up the repository with proper configuration

set -e

echo "🚀 Setting up Git repository..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if already a Git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Already a Git repository${NC}"
    echo "  Run 'git status' to see current status"
    exit 0
fi

# Initialize Git repository
echo -e "${YELLOW}📝 Initializing Git repository...${NC}"
git init

# Configure Git (optional)
echo -e "${YELLOW}⚙️  Configuring Git...${NC}"
git config core.autocrlf false  # For Windows compatibility
git config core.filemode false  # For cross-platform compatibility

# Add all files
echo -e "${YELLOW}📁 Adding files to Git...${NC}"
git add .

# Create initial commit
echo -e "${YELLOW}💾 Creating initial commit...${NC}"
git commit -m "Initial commit: Cloud-Native DevOps Platform

- Infrastructure as Code with Bicep templates
- Azure Container Apps environment setup
- Security hardening with managed identities
- Monitoring and observability with Application Insights
- CI/CD workflows and linting tools
- Comprehensive documentation and deployment guides"

# Set up remote if provided
if [ -n "$1" ]; then
    echo -e "${YELLOW}🔗 Setting up remote repository...${NC}"
    git remote add origin "$1"
    echo "  Remote 'origin' set to: $1"
fi

echo -e "\n${GREEN}🎉 Git repository setup complete!${NC}"
echo ""
echo "📋 What's configured:"
echo "  • Git repository initialized"
echo "  • All files added and committed"
echo "  • Pre-commit hooks ready"
echo "  • Cross-platform Git configuration"
echo ""
echo "🚀 Next steps:"
echo "  1. Review the initial commit: git log --oneline"
echo "  2. Make changes and test pre-commit hooks: git commit -m 'test'"
echo "  3. Push to remote: git push -u origin main"
echo ""
echo "📚 Useful commands:"
echo "  • git status                    # See current status"
echo "  • git log --oneline            # See commit history"
echo "  • git diff                     # See unstaged changes"
echo "  • .\scripts\lint.ps1           # Run linting manually"
