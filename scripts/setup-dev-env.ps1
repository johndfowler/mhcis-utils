# Development Environment Setup Script
# Run this script to configure your development environment

param(
    [switch]$SkipGitHooks
)

Write-Host "🚀 Setting up development environment..." -ForegroundColor Green

# ===========================================
# Git Hooks Setup
# ===========================================
if (-not $SkipGitHooks) {
    Write-Host "`n📝 Setting up Git hooks..." -ForegroundColor Yellow

    if (-not (Test-Path ".git")) {
        Write-Host "❌ .git directory not found. Are you in a Git repository?" -ForegroundColor Red
        exit 1
    }

    # Create .husky directory if it doesn't exist
    if (-not (Test-Path ".husky")) {
        New-Item -ItemType Directory -Path ".husky" -Force | Out-Null
        Write-Host "  📁 Created .husky directory" -ForegroundColor Gray
    }

    # Initialize Husky if not already done
    if (-not (Test-Path ".husky/_")) {
        try {
            # Use npx to run husky init
            $initResult = & npx husky init 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ Husky initialized successfully" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  Husky init failed, setting up manually..." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  ⚠️  npx husky init failed, setting up manually..." -ForegroundColor Yellow
        }
    }

    # Set up pre-commit hook
    $preCommitHook = ".husky/pre-commit"
    if (-not (Test-Path $preCommitHook)) {
        # Create pre-commit hook that runs our validation
        @"
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Run lint-staged
npx lint-staged

# Run infrastructure tests (critical ones only)
pwsh -ExecutionPolicy Bypass -File tests/infra/run-tests.ps1 -CI

# Run script validation
pwsh -ExecutionPolicy Bypass -File scripts/pre-commit.ps1
"@ | Out-File -FilePath $preCommitHook -Encoding UTF8

        # Make the hook executable on Unix-like systems
        if ($IsLinux -or $IsMacOS) {
            & chmod +x $preCommitHook
        }

        Write-Host "  ✅ Pre-commit hook created" -ForegroundColor Green
    } else {
        Write-Host "  ✅ Pre-commit hook already exists" -ForegroundColor Green
    }

    # Set up commit-msg hook for conventional commits
    $commitMsgHook = ".husky/commit-msg"
    if (-not (Test-Path $commitMsgHook)) {
        @"
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Validate commit message format
pwsh -ExecutionPolicy Bypass -File scripts/commit-msg.ps1 `$1
"@ | Out-File -FilePath $commitMsgHook -Encoding UTF8

        # Make the hook executable on Unix-like systems
        if ($IsLinux -or $IsMacOS) {
            & chmod +x $commitMsgHook
        }

        Write-Host "  ✅ Commit message hook created" -ForegroundColor Green
    } else {
        Write-Host "  ✅ Commit message hook already exists" -ForegroundColor Green
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

# Check Node.js for Prettier and Husky
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version 2>$null
    Write-Host "  ✅ Node.js is available ($nodeVersion)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Node.js not found" -ForegroundColor Red
    Write-Host "    Install from: https://nodejs.org/" -ForegroundColor Gray
}

# Check npm
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmVersion = npm --version 2>$null
    Write-Host "  ✅ npm is available ($npmVersion)" -ForegroundColor Green
} else {
    Write-Host "  ❌ npm not found (should come with Node.js)" -ForegroundColor Red
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
Write-Host "  • Modern Husky Git hooks for code quality" -ForegroundColor White
Write-Host "  • Bicep linting and validation" -ForegroundColor White
Write-Host "  • JSON/YAML validation" -ForegroundColor White
Write-Host "  • Prettier code formatting" -ForegroundColor White
Write-Host "  • Infrastructure testing framework" -ForegroundColor White
Write-Host "  • CI/CD workflows for GitHub Actions" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run 'npm run format' to format all files" -ForegroundColor White
Write-Host "  2. Run 'npm run validate' to test all validations" -ForegroundColor White
Write-Host "  3. Run 'npm run test' to run the testing framework" -ForegroundColor White
Write-Host "  4. Make a test commit to validate Git hooks" -ForegroundColor White
Write-Host "  5. Push to GitHub to test CI/CD workflows" -ForegroundColor White
Write-Host ""
Write-Host "📚 Useful commands:" -ForegroundColor Cyan
Write-Host "  • npm run format                           # Format all files with Prettier" -ForegroundColor White
Write-Host "  • npm run lint                            # Run all linting checks" -ForegroundColor White
Write-Host "  • npm run validate                        # Run comprehensive validation" -ForegroundColor White
Write-Host "  • npm run test                            # Run all tests" -ForegroundColor White
Write-Host "  • npm run test:infra                      # Run infrastructure tests" -ForegroundColor White
Write-Host "  • npm run test:scripts                    # Run script tests" -ForegroundColor White
Write-Host "  • az bicep build --file infra/main.bicep   # Build Bicep templates" -ForegroundColor White
Write-Host "  • azd up                                  # Deploy with Azure Developer CLI" -ForegroundColor White
