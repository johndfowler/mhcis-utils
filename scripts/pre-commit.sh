#!/bin/bash

# Pre-commit hook for Bash
# Runs linting and validation before commits

set -e

echo "🔍 Running pre-commit validation..."

# Ensure we're in the project root (assuming hook is in .git/hooks/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Run the linting script
if [ -f "scripts/lint.sh" ]; then
    if bash "scripts/lint.sh" --ci; then
        echo "✅ Pre-commit validation passed!"
        exit 0
    else
        echo "❌ Pre-commit validation failed!"
        echo "Please fix the issues above before committing."
        exit 1
    fi
else
    echo "❌ Linting script not found at scripts/lint.sh"
    exit 1
fi
