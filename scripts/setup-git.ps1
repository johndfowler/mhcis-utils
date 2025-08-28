# Git Setup Script for Cloud-Native DevOps Platform
# This script initializes Git and sets up the repository with proper configuration

param(
    [string]$RemoteUrl
)

Write-Host "🚀 Setting up Git repository..." -ForegroundColor Green

# Check if already a Git repository
try {
    git rev-parse --git-dir 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "⚠️  Already a Git repository" -ForegroundColor Yellow
        Write-Host "  Run 'git status' to see current status" -ForegroundColor Gray
        exit 0
    }
} catch {
    # Not a Git repository, continue with setup
}

# Initialize Git repository
Write-Host "`n📝 Initializing Git repository..." -ForegroundColor Yellow
git init

# Configure Git
Write-Host "⚙️  Configuring Git..." -ForegroundColor Yellow
git config core.autocrlf false  # For Windows compatibility
git config core.filemode false  # For cross-platform compatibility

# Add all files
Write-Host "📁 Adding files to Git..." -ForegroundColor Yellow
git add .

# Create initial commit
Write-Host "💾 Creating initial commit..." -ForegroundColor Yellow
$commitMessage = @"
Initial commit: Cloud-Native DevOps Platform

- Infrastructure as Code with Bicep templates
- Azure Container Apps environment setup
- Security hardening with managed identities
- Monitoring and observability with Application Insights
- CI/CD workflows and linting tools
- Comprehensive documentation and deployment guides
"@

git commit -m $commitMessage

# Set up remote if provided
if ($RemoteUrl) {
    Write-Host "🔗 Setting up remote repository..." -ForegroundColor Yellow
    git remote add origin $RemoteUrl
    Write-Host "  Remote 'origin' set to: $RemoteUrl" -ForegroundColor Gray
}

Write-Host "`n🎉 Git repository setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 What's configured:" -ForegroundColor Cyan
Write-Host "  • Git repository initialized" -ForegroundColor White
Write-Host "  • All files added and committed" -ForegroundColor White
Write-Host "  • Pre-commit hooks ready" -ForegroundColor White
Write-Host "  • Cross-platform Git configuration" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review the initial commit: git log --oneline" -ForegroundColor White
Write-Host "  2. Make changes and test pre-commit hooks: git commit -m 'test'" -ForegroundColor White
Write-Host "  3. Push to remote: git push -u origin main" -ForegroundColor White
Write-Host ""
Write-Host "📚 Useful commands:" -ForegroundColor Cyan
Write-Host "  • git status                    # See current status" -ForegroundColor White
Write-Host "  • git log --oneline            # See commit history" -ForegroundColor White
Write-Host "  • git diff                     # See unstaged changes" -ForegroundColor White
Write-Host "  • .\scripts\lint.ps1           # Run linting manually" -ForegroundColor White
