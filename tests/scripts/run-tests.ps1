# ===========================================
# Script Test Runner
# ===========================================
# Runs comprehensive script validation tests using Pester

param(
    [switch]$CI,
    [string]$ScriptsPath = "$PSScriptRoot/../../scripts",
    [string]$OutputPath = "$PSScriptRoot/results"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($CI) { "SilentlyContinue" } else { "Continue" }

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Test configuration
$testConfig = @{
    ScriptsPath = $ScriptsPath
    OutputPath = $OutputPath
    CI = $CI
    TestResults = @()
}

Write-Host "🧪 Starting Script Tests..." -ForegroundColor Cyan
Write-Host "Scripts Path: $($testConfig.ScriptsPath)" -ForegroundColor Gray
Write-Host "Output Path: $($testConfig.OutputPath)" -ForegroundColor Gray
Write-Host ""

# ===========================================
# Check Pester Installation
# ===========================================
Write-Host "📦 Checking Pester Installation" -ForegroundColor Yellow

try {
    $pesterModule = Get-Module -Name Pester -ListAvailable
    if (-not $pesterModule) {
        Write-Host "Installing Pester..." -ForegroundColor Gray
        Install-Module -Name Pester -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module Pester -MinimumVersion 5.0.0
    Write-Host "✅ Pester is ready" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install/load Pester: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please install Pester manually: Install-Module -Name Pester -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

# ===========================================
# Test 1: Script Syntax Validation
# ===========================================
Write-Host "`n📝 Test 1: Script Syntax Validation" -ForegroundColor Yellow

$testResult = Test-ScriptSyntax -ScriptsPath $testConfig.ScriptsPath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ All scripts have valid syntax" -ForegroundColor Green
} else {
    Write-Host "❌ Script syntax validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 2: Script Best Practices
# ===========================================
Write-Host "`n🔧 Test 2: Script Best Practices" -ForegroundColor Yellow

$testResult = Test-ScriptBestPractices -ScriptsPath $testConfig.ScriptsPath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ Scripts follow best practices" -ForegroundColor Green
} else {
    Write-Host "❌ Best practices validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 3: Pester Unit Tests
# ===========================================
Write-Host "`n🧪 Test 3: Pester Unit Tests" -ForegroundColor Yellow

$testResult = Test-PesterTests -ScriptsPath $testConfig.ScriptsPath -OutputPath $testConfig.OutputPath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ All Pester tests passed" -ForegroundColor Green
} else {
    Write-Host "❌ Pester tests failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 4: Script Dependencies
# ===========================================
Write-Host "`n🔗 Test 4: Script Dependencies" -ForegroundColor Yellow

$testResult = Test-ScriptDependencies -ScriptsPath $testConfig.ScriptsPath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ All script dependencies are available" -ForegroundColor Green
} else {
    Write-Host "❌ Dependency validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 5: Script Documentation
# ===========================================
Write-Host "`n📚 Test 5: Script Documentation" -ForegroundColor Yellow

$testResult = Test-ScriptDocumentation -ScriptsPath $testConfig.ScriptsPath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ Scripts are properly documented" -ForegroundColor Green
} else {
    Write-Host "❌ Documentation validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test Results Summary
# ===========================================
Write-Host "`n📊 Script Test Results Summary" -ForegroundColor Cyan
Write-Host "=".PadRight(50, "=") -ForegroundColor Cyan

$passedTests = ($testConfig.TestResults | Where-Object { $_.Passed }).Count
$totalTests = $testConfig.TestResults.Count
$failedTests = $totalTests - $passedTests

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red

if ($failedTests -eq 0) {
    Write-Host "`n🎉 All script tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Some tests failed. Review the output above." -ForegroundColor Red

    # Show detailed failures
    Write-Host "`n📋 Failed Tests:" -ForegroundColor Yellow
    foreach ($result in ($testConfig.TestResults | Where-Object { -not $_.Passed })) {
        Write-Host "  - $($result.TestName): $($result.Error)" -ForegroundColor Red
    }

    exit 1
}
