#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Pre-commit hook for PowerShell
.DESCRIPTION
    Runs linting and validation before commits
#>

Write-Host "🔍 Running pre-commit validation..." -ForegroundColor Green

# Ensure we're in the project root (assuming hook is in .git/hooks/)
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $ProjectRoot

# Run the linting script
try {
    & "$ProjectRoot/scripts/lint.ps1" -CI
    Write-Host "✅ Pre-commit validation passed!" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "❌ Pre-commit validation failed!" -ForegroundColor Red
    Write-Host "Please fix the issues above before committing." -ForegroundColor Red
    exit 1
}
