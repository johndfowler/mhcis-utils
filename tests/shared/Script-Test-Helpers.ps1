# ===========================================
# Script Test Helper Functions
# ===========================================
# Shared functions for script testing

# Test-ScriptSyntax
# Validates PowerShell script syntax
function Test-ScriptSyntax {
    param([string]$ScriptsPath)

    $result = @{
        TestName = "ScriptSyntax"
        Passed = $false
        Error = ""
    }

    try {
        $scriptFiles = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse

        if ($scriptFiles.Count -eq 0) {
            $result.Error = "No PowerShell scripts found in $ScriptsPath"
            return $result
        }

        foreach ($scriptFile in $scriptFiles) {
            try {
                $scriptBlock = [ScriptBlock]::Create((Get-Content $scriptFile.FullName -Raw))
                $errors = $null
                $warnings = $null

                # Parse the script to check for syntax errors
                $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                    $scriptBlock.ToString(),
                    $scriptFile.FullName,
                    [ref]$errors,
                    [ref]$warnings
                )

                if ($errors.Count -gt 0) {
                    $result.Error = "Syntax error in $($scriptFile.Name): $($errors[0].Message)"
                    return $result
                }
            }
            catch {
                $result.Error = "Failed to parse $($scriptFile.Name): $($_.Exception.Message)"
                return $result
            }
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Script syntax validation error: $($_.Exception.Message)"
    }

    return $result
}

# Test-ScriptBestPractices
# Validates PowerShell best practices
function Test-ScriptBestPractices {
    param([string]$ScriptsPath)

    $result = @{
        TestName = "ScriptBestPractices"
        Passed = $false
        Error = ""
    }

    try {
        $scriptFiles = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse

        foreach ($scriptFile in $scriptFiles) {
            $content = Get-Content $scriptFile.FullName -Raw

            # Check for common best practice violations

            # 1. Check for Write-Host usage (should use Write-Output or Write-Verbose)
            if ($content -match 'Write-Host') {
                $result.Error = "$($scriptFile.Name): Use Write-Output or Write-Verbose instead of Write-Host"
                return $result
            }

            # 2. Check for hardcoded paths
            if ($content -match 'C:\\' -and $content -notmatch 'Get-Location|Resolve-Path') {
                $result.Error = "$($scriptFile.Name): Avoid hardcoded paths, use relative paths or environment variables"
                return $result
            }

            # 3. Check for missing error handling
            if ($content -notmatch '\$ErrorActionPreference|try|catch') {
                $result.Error = "$($scriptFile.Name): Missing error handling"
                return $result
            }

            # 4. Check for proper parameter validation
            if ($content -match 'param\(' -and $content -notmatch '\[Parameter\(|ValidateNotNullOrEmpty|ValidateSet') {
                $result.Error = "$($scriptFile.Name): Consider adding parameter validation attributes"
                return $result
            }

            # 5. Check for verbose output in CI scenarios
            if ($content -notmatch 'Write-Verbose|VerbosePreference' -and $content -match 'Write-Host|Write-Output') {
                # This is a warning, not an error - scripts should handle verbose output appropriately
            }
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Best practices validation error: $($_.Exception.Message)"
    }

    return $result
}

# Test-PesterTests
# Runs Pester tests for scripts
function Test-PesterTests {
    param(
        [string]$ScriptsPath,
        [string]$OutputPath
    )

    $result = @{
        TestName = "PesterTests"
        Passed = $false
        Error = ""
    }

    try {
        # Look for test files
        $testFiles = Get-ChildItem -Path $ScriptsPath -Filter "*.Tests.ps1" -Recurse

        if ($testFiles.Count -eq 0) {
            # No test files found - this is acceptable for now
            Write-Host "ℹ️ No Pester test files found - consider adding unit tests" -ForegroundColor Yellow
            $result.Passed = $true
            return $result
        }

        # Run Pester tests
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $testFiles.FullName
        $pesterConfig.Output.Verbosity = if ($CI) { "Minimal" } else { "Detailed" }
        $pesterConfig.Output.CIFormat = if ($CI) { "Auto" } else { "None" }

        if ($OutputPath) {
            $pesterConfig.TestResult.OutputPath = Join-Path $OutputPath "pester-results.xml"
            $pesterConfig.TestResult.OutputFormat = "NUnitXml"
        }

        $testResults = Invoke-Pester -Configuration $pesterConfig

        if ($testResults.FailedCount -gt 0) {
            $result.Error = "$($testResults.FailedCount) Pester test(s) failed"
            return $result
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Pester test execution error: $($_.Exception.Message)"
    }

    return $result
}

# Test-ScriptDependencies
# Validates script dependencies
function Test-ScriptDependencies {
    param([string]$ScriptsPath)

    $result = @{
        TestName = "ScriptDependencies"
        Passed = $false
        Error = ""
    }

    try {
        $scriptFiles = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse

        foreach ($scriptFile in $scriptFiles) {
            $content = Get-Content $scriptFile.FullName -Raw

            # Check for module imports
            $moduleImports = [regex]::Matches($content, 'Import-Module\s+["'']([^"'']+)["'']')
            foreach ($import in $moduleImports) {
                $moduleName = $import.Groups[1].Value
                try {
                    $module = Get-Module -Name $moduleName -ListAvailable
                    if (-not $module) {
                        $result.Error = "$($scriptFile.Name): Required module not found: $moduleName"
                        return $result
                    }
                }
                catch {
                    $result.Error = "$($scriptFile.Name): Error checking module $moduleName`: $($_.Exception.Message)"
                    return $result
                }
            }

            # Check for Azure CLI dependency
            if ($content -match 'az\s+') {
                try {
                    $azVersion = & az version 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        $result.Error = "$($scriptFile.Name): Azure CLI not available but required"
                        return $result
                    }
                }
                catch {
                    $result.Error = "$($scriptFile.Name): Azure CLI check failed: $($_.Exception.Message)"
                    return $result
                }
            }

            # Check for Bicep CLI dependency
            if ($content -match 'az bicep') {
                try {
                    $bicepVersion = & az bicep version 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        $result.Error = "$($scriptFile.Name): Bicep CLI not available but required"
                        return $result
                    }
                }
                catch {
                    $result.Error = "$($scriptFile.Name): Bicep CLI check failed: $($_.Exception.Message)"
                    return $result
                }
            }
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Dependency validation error: $($_.Exception.Message)"
    }

    return $result
}

# Test-ScriptDocumentation
# Validates script documentation
function Test-ScriptDocumentation {
    param([string]$ScriptsPath)

    $result = @{
        TestName = "ScriptDocumentation"
        Passed = $false
        Error = ""
    }

    try {
        $scriptFiles = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse

        foreach ($scriptFile in $scriptFiles) {
            $content = Get-Content $scriptFile.FullName -Raw

            # Check for basic documentation elements

            # 1. Check for script header comment
            if ($content -notmatch '^#.*?\.ps1|^<#.*?^#>|^<#' -and $scriptFile.Length -gt 1KB) {
                $result.Error = "$($scriptFile.Name): Missing script header documentation"
                return $result
            }

            # 2. Check for parameter documentation if parameters exist
            if ($content -match 'param\s*\(') {
                $paramMatches = [regex]::Matches($content, 'param\s*\((.*?)\)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($paramMatches.Count -gt 0) {
                    $paramBlock = $paramMatches[0].Groups[1].Value
                    if ($paramBlock -match '\[string\]|\[int\]|\[bool\]' -and $content -notmatch '#.*param|param.*#') {
                        $result.Error = "$($scriptFile.Name): Parameters found but not documented"
                        return $result
                    }
                }
            }

            # 3. Check for function documentation if functions exist
            if ($content -match 'function\s+\w+') {
                $functions = [regex]::Matches($content, 'function\s+(\w+)')
                foreach ($func in $functions) {
                    $funcName = $func.Groups[1].Value
                    $funcPattern = "(?s)#.*?$funcName|^function\s+$funcName"
                    if ($content -notmatch $funcPattern) {
                        $result.Error = "$($scriptFile.Name): Function '$funcName' lacks documentation"
                        return $result
                    }
                }
            }

            # 4. Check for error handling documentation
            if ($content -match 'try|catch|\$ErrorActionPreference') {
                if ($content -notmatch '#.*error|#.*exception|#.*handling') {
                    # This is a warning, not an error - error handling should be documented but isn't critical
                }
            }
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Documentation validation error: $($_.Exception.Message)"
    }

    return $result
}

# Helper function to format file size
function Format-FileSize {
    param([long]$Size)

    if ($Size -gt 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    } elseif ($Size -gt 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    } else {
        return "$Size bytes"
    }
}
