# ===========================================
# Infrastructure Test Runner
# ===========================================
# Runs comprehensive infrastructure validation tests

param(
    [switch]$CI,
    [string]$TemplatePath = "$PSScriptRoot/../../infra/main.bicep",
    [string]$ParametersPath = "$PSScriptRoot/../../infra/main.parameters.json",
    [string]$OutputPath = "$PSScriptRoot/../../infra/main.json"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($CI) { "SilentlyContinue" } else { "Continue" }

# Import shared test functions
. "$PSScriptRoot/../shared/Test-Helpers.ps1"

# Test configuration
$testConfig = @{
    TemplatePath = $TemplatePath
    ParametersPath = $ParametersPath
    OutputPath = $OutputPath
    CI = $CI
    TestResults = @()
}

Write-Host "🧪 Starting Infrastructure Tests..." -ForegroundColor Cyan
Write-Host "Template: $($testConfig.TemplatePath)" -ForegroundColor Gray
Write-Host "Parameters: $($testConfig.ParametersPath)" -ForegroundColor Gray
Write-Host ""

# ===========================================
# Test 1: Bicep Template Compilation
# ===========================================
Write-Host "📝 Test 1: Bicep Template Compilation" -ForegroundColor Yellow

$testResult = Test-BicepCompilation -TemplatePath $testConfig.TemplatePath -OutputPath $testConfig.OutputPath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ Bicep template compiles successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Bicep template compilation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 2: Parameter Validation
# ===========================================
Write-Host "`n📋 Test 2: Parameter Validation" -ForegroundColor Yellow

$testResult = Test-ParameterValidation -ParametersPath $testConfig.ParametersPath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ Parameters are valid" -ForegroundColor Green
} else {
    Write-Host "❌ Parameter validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 3: Azure Template Test Toolkit (TTK)
# ===========================================
Write-Host "`n🔧 Test 3: Azure Template Test Toolkit (TTK)" -ForegroundColor Yellow

$testResult = Test-TemplateValidation -TemplatePath $testConfig.TemplatePath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ TTK validation passed" -ForegroundColor Green
} else {
    Write-Host "❌ TTK validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 4: Security Best Practices
# ===========================================
Write-Host "`n🔒 Test 4: Security Best Practices" -ForegroundColor Yellow

$testResult = Test-SecurityBestPractices -TemplatePath $testConfig.TemplatePath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ Security best practices validated" -ForegroundColor Green
} else {
    Write-Host "❌ Security validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 5: Resource Naming Conventions
# ===========================================
Write-Host "`n🏷️ Test 5: Resource Naming Conventions" -ForegroundColor Yellow

$testResult = Test-NamingConventions -TemplatePath $testConfig.TemplatePath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ Naming conventions validated" -ForegroundColor Green
} else {
    Write-Host "❌ Naming convention validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test 6: Cost Optimization
# ===========================================
Write-Host "`n💰 Test 6: Cost Optimization" -ForegroundColor Yellow

$testResult = Test-CostOptimization -TemplatePath $testConfig.TemplatePath -ParametersPath $testConfig.ParametersPath
$testConfig.TestResults += $testResult

if ($testResult.Passed) {
    Write-Host "✅ Cost optimization validated" -ForegroundColor Green
} else {
    Write-Host "❌ Cost optimization validation failed: $($testResult.Error)" -ForegroundColor Red
}

# ===========================================
# Test Results Summary
# ===========================================
Write-Host "`n📊 Test Results Summary" -ForegroundColor Cyan
Write-Host "=".PadRight(50, "=") -ForegroundColor Cyan

$passedTests = ($testConfig.TestResults | Where-Object { $_.Passed }).Count
$totalTests = $testConfig.TestResults.Count
$failedTests = $totalTests - $passedTests

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red

if ($failedTests -eq 0) {
    Write-Host "`n🎉 All infrastructure tests passed!" -ForegroundColor Green
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
