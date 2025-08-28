#!/bin/bash

# Simple linting script for cross-platform compatibility
# Usage: ./lint.sh [--fix] [--ci]

set -e

echo "🔍 Starting basic linting..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Azure CLI is available
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Please install Azure CLI.${NC}"
    exit 1
fi

# Check Bicep files
echo -e "\n${YELLOW}📝 Checking Bicep files...${NC}"

if [ -d "infra" ]; then
    for file in infra/*.bicep infra/modules/*.bicep; do
        if [ -f "$file" ]; then
            echo "  🔍 Linting: $file"
            if az bicep lint --file "$file" 2>&1; then
                echo -e "  ${GREEN}✅ $file passed linting${NC}"
            else
                echo -e "  ${RED}❌ $file has linting issues${NC}"
                if [ "$2" = "--ci" ]; then
                    exit 1
                fi
            fi
        fi
    done
fi

# Check JSON files
echo -e "\n${YELLOW}📄 Checking JSON files...${NC}"

for file in *.json infra/*.json; do
    if [ -f "$file" ]; then
        echo "  🔍 Validating: $file"
        if jq empty "$file" 2>/dev/null; then
            echo -e "  ${GREEN}✅ $file is valid JSON${NC}"
        else
            echo -e "  ${RED}❌ $file has invalid JSON${NC}"
            if [ "$2" = "--ci" ]; then
                exit 1
            fi
        fi
    fi
done

echo -e "\n${GREEN}🎉 Basic linting complete!${NC}"
