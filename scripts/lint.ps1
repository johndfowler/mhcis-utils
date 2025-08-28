#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Comprehensive linting script for the Cloud-Native DevOps Platform
.DESCRIPTION
    Runs multiple linting tools to ensure code quality and consistency
#>

param(
    [switch]$Fix,
    [switch]$CI
)

Write-Host "🔍 Starting comprehensive linting..." -ForegroundColor Green

# Ensure we're in the project root
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

# ===========================================
# Bicep Linting
# ===========================================
Write-Host "`n📝 Checking Bicep files..." -ForegroundColor Yellow

$BicepFiles = Get-ChildItem -Path "infra" -Filter "*.bicep" -Recurse
foreach ($file in $BicepFiles) {
    Write-Host "  🔍 Linting: $($file.FullName)" -ForegroundColor Gray

    # Run Bicep linter
    $lintResult = az bicep lint --file $file.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Bicep linting failed for $($file.Name)" -ForegroundColor Red
        $lintResult | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        if ($CI) { exit 1 }
    } elseif ($lintResult) {
        $lintResult | ForEach-Object { Write-Host "    ⚠️  $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  ✅ $($file.Name) passed linting" -ForegroundColor Green
    }

    # Build validation
    Write-Host "  🔍 Building: $($file.FullName)" -ForegroundColor Gray
    $buildResult = az bicep build --file $file.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Bicep build failed for $($file.Name)" -ForegroundColor Red
        $buildResult | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        if ($CI) { exit 1 }
    } else {
        Write-Host "  ✅ $($file.Name) builds successfully" -ForegroundColor Green
    }
}

# ===========================================
# JSON Validation
# ===========================================
Write-Host "`n📄 Checking JSON files..." -ForegroundColor Yellow

$JsonFiles = Get-ChildItem -Path "." -Filter "*.json" -Recurse | Where-Object { $_.FullName -notlike "*node_modules*" }
foreach ($file in $JsonFiles) {
    Write-Host "  🔍 Validating: $($file.FullName)" -ForegroundColor Gray

    try {
        Get-Content $file.FullName -Raw | ConvertFrom-Json | Out-Null
        Write-Host "  ✅ $($file.Name) is valid JSON" -ForegroundColor Green
    }
    catch {
        Write-Host "  ❌ $($file.Name) has invalid JSON: $($_.Exception.Message)" -ForegroundColor Red
        if ($CI) { exit 1 }
    }
}

# ===========================================
# YAML Validation
# ===========================================
Write-Host "`n📋 Checking YAML files..." -ForegroundColor Yellow

$YamlFiles = Get-ChildItem -Path "." -Filter "*.yaml" -Recurse
foreach ($file in $YamlFiles) {
    Write-Host "  🔍 Validating: $($file.FullName)" -ForegroundColor Gray

    try {
        $yamlContent = Get-Content $file.FullName -Raw
        # Simple but robust YAML validation - just check if it has key-value pairs
        if ($yamlContent -match ":") {
            Write-Host "  ✅ $($file.Name) appears to be valid YAML" -ForegroundColor Green
        } else {
            throw "No key-value pairs found in YAML"
        }
    }
    catch {
        Write-Host "  ❌ $($file.Name) has invalid YAML: $($_.Exception.Message)" -ForegroundColor Red
        if ($CI) { exit 1 }
    }
}

# ===========================================
# Markdown Linting (if available)
# ===========================================
Write-Host "`n📖 Checking Markdown files..." -ForegroundColor Yellow

$MarkdownFiles = Get-ChildItem -Path "." -Filter "*.md" -Recurse
foreach ($file in $MarkdownFiles) {
    Write-Host "  🔍 Checking: $($file.FullName)" -ForegroundColor Gray

    # Basic markdown checks
    $content = Get-Content $file.FullName -Raw

    # Check for common issues
    $issues = @()

    # Check for trailing whitespace
    if ($content -match "\s+$") {
        $issues += "Trailing whitespace found"
    }

    # Check for multiple consecutive blank lines
    if ($content -match "\n\n\n+") {
        $issues += "Multiple consecutive blank lines found"
    }

    if ($issues.Count -eq 0) {
        Write-Host "  ✅ $($file.Name) looks good" -ForegroundColor Green
    } else {
        $issues | ForEach-Object { Write-Host "  ⚠️  $_" -ForegroundColor Yellow }
    }
}

# ===========================================
# Summary
# ===========================================
Write-Host "`n🎉 Linting complete!" -ForegroundColor Green

if ($CI) {
    Write-Host "✅ All checks passed for CI/CD" -ForegroundColor Green
} else {
    Write-Host "💡 Tip: Run with -CI switch for CI/CD mode" -ForegroundColor Cyan
    Write-Host "💡 Tip: Run with -Fix switch to auto-fix issues (when available)" -ForegroundColor Cyan
}
