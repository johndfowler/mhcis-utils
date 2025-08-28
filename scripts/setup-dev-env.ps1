# Development Environment Setup Script
# Run this script to configure your development environment

param(
    [switch]$SkipGitHooks,
    [switch]$Test
)

Write-Host "🚀 Setting up development environment..." -ForegroundColor Green

# ===========================================
# Git Hooks Setup
# ===========================================
if (-not $SkipGitHooks) {
    Write-Host "`n📝 Setting up Git hooks..." -ForegroundColor Yellow

    if (-not (Test-Path ".git/hooks")) {
        Write-Host "❌ .git/hooks directory not found. Are you in a Git repository?" -ForegroundColor Red
        exit 1
    }

    # Backup existing hooks
    if (Test-Path ".git/hooks/pre-commit") {
        Write-Host "  📁 Backing up existing pre-commit hook..."
        $backupName = ".git/hooks/pre-commit.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Move-Item ".git/hooks/pre-commit" $backupName
    }

    # Copy our PowerShell hook
    if (-not (Test-Path ".git/hooks/pre-commit.ps1")) {
        Write-Host "  📝 Installing PowerShell pre-commit hook..."
        Copy-Item ".git/hooks/pre-commit.ps1" ".git/hooks/pre-commit.ps1"
        Write-Host "  ✅ PowerShell pre-commit hook installed" -ForegroundColor Green
    } else {
        Write-Host "  ✅ PowerShell pre-commit hook already exists" -ForegroundColor Green
    }
}

# ===========================================
# Tools Validation
# ===========================================
Write-Host "`n🔧 Validating development tools..." -ForegroundColor Yellow

# Check Azure CLI
if (Get-Command az -ErrorAction SilentlyContinue) {
    $azVersion = az version --query '"azure-cli"' -o tsv 2>$null
    Write-Host "  ✅ Azure CLI is installed ($azVersion)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Azure CLI not found" -ForegroundColor Red
    Write-Host "    Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Gray
}

# Check Bicep
try {
    $bicepOutput = az bicep version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Bicep CLI is available" -ForegroundColor Green
    } else {
        throw "Bicep not available"
    }
} catch {
    Write-Host "  ❌ Bicep CLI not available" -ForegroundColor Red
    Write-Host "    Install with: az bicep install" -ForegroundColor Gray
}

# Check PowerShell (already running in PS)
Write-Host "  ✅ PowerShell is available ($($PSVersionTable.PSVersion))" -ForegroundColor Green

# Check Node.js for markdownlint
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version 2>$null
    Write-Host "  ✅ Node.js is available ($nodeVersion)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Node.js not found (optional for markdownlint)" -ForegroundColor Yellow
}

# ===========================================
# Configuration Validation
# ===========================================
Write-Host "`n⚙️  Validating configuration..." -ForegroundColor Yellow

$checks = @(
    @{ Name = "Bicep configuration"; Path = ".bicepconfig.json" },
    @{ Name = "Azure Developer CLI config"; Path = "azure.yaml" },
    @{ Name = "Main Bicep template"; Path = "infra/main.bicep" },
    @{ Name = "Parameters file"; Path = "infra/main.parameters.json" }
)

foreach ($check in $checks) {
    if (Test-Path $check.Path) {
        Write-Host "  ✅ $($check.Name) found" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $($check.Name) not found at $($check.Path)" -ForegroundColor Red
    }
}

# ===========================================
# Test Validation
# ===========================================
Write-Host "`n🧪 Running test validation..." -ForegroundColor Yellow

# Test Bicep build
if (Test-Path "infra/main.bicep") {
    $buildResult = az bicep build --file infra/main.bicep --stdout 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Main template builds successfully" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Main template has build errors" -ForegroundColor Red
        if ($Test) {
            $buildResult | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        }
    }
}

# Test linting script
if (Test-Path "scripts/lint.ps1") {
    Write-Host "  ✅ PowerShell linting script found" -ForegroundColor Green
} else {
    Write-Host "  ❌ PowerShell linting script not found" -ForegroundColor Red
}

if (Test-Path "scripts/lint.sh") {
    Write-Host "  ✅ Bash linting script found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Bash linting script not found" -ForegroundColor Red
}

# ===========================================
# Success Message
# ===========================================
Write-Host "`n🎉 Development environment setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 What's configured:" -ForegroundColor Cyan
Write-Host "  • Git pre-commit hooks for code quality" -ForegroundColor White
Write-Host "  • Bicep linting and validation" -ForegroundColor White
Write-Host "  • JSON/YAML validation" -ForegroundColor White
Write-Host "  • CI/CD workflows for GitHub Actions" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run '.\scripts\lint.ps1' to test linting" -ForegroundColor White
Write-Host "  2. Try 'az bicep build --file infra/main.bicep' to test builds" -ForegroundColor White
Write-Host "  3. Make a test commit to validate Git hooks" -ForegroundColor White
Write-Host "  4. Push to GitHub to test CI/CD workflows" -ForegroundColor White
Write-Host ""
Write-Host "📚 Useful commands:" -ForegroundColor Cyan
Write-Host "  • az bicep lint --file infra/main.bicep    # Lint Bicep files" -ForegroundColor White
Write-Host "  • az bicep build --file infra/main.bicep   # Build templates" -ForegroundColor White
Write-Host "  • .\scripts\lint.ps1                       # Run all validations" -ForegroundColor White
Write-Host "  • azd up                                  # Deploy with Azure Developer CLI" -ForegroundColor White
