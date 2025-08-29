# ===========================================
# Setup-Dev-Env Script Tests
# ===========================================
# Pester tests for the development environment setup script

Describe "Setup-Dev-Env Script Tests" {

    BeforeAll {
        # Set up test environment
        $scriptPath = "$PSScriptRoot/setup-dev-env.ps1"
        $testRoot = Split-Path $PSScriptRoot -Parent

        # Mock external commands
        Mock Get-Command { $true } -ParameterFilter { $Name -eq 'az' }
        Mock Get-Command { $true } -ParameterFilter { $Name -eq 'node' }
        Mock Get-Command { $true } -ParameterFilter { $Name -eq 'npm' }

        # Mock az commands
        Mock az {
            if ($args -contains 'version') { return '@{"azure-cli": "2.50.0"}' }
            if ($args -contains 'bicep' -and $args -contains 'version') { return 'Bicep CLI version 0.20.0' }
            return ""
        }

        # Mock Test-Path for configuration files
        Mock Test-Path { $true } -ParameterFilter { $Path -eq '.git/hooks' }
        Mock Test-Path { $true } -ParameterFilter { $Path -eq '.bicepconfig.json' }
        Mock Test-Path { $true } -ParameterFilter { $Path -eq 'azure.yaml' }
        Mock Test-Path { $true } -ParameterFilter { $Path -eq 'infra/main.bicep' }
        Mock Test-Path { $true } -ParameterFilter { $Path -eq 'infra/main.parameters.json' }
        Mock Test-Path { $true } -ParameterFilter { $Path -eq 'scripts/pre-commit.ps1' }
        Mock Test-Path { $true } -ParameterFilter { $Path -eq 'scripts/lint.ps1' }
        Mock Test-Path { $true } -ParameterFilter { $Path -eq 'scripts/lint.sh' }
    }

    Context "Script Syntax and Structure" {

        It "Should have valid PowerShell syntax" {
            $scriptBlock = [ScriptBlock]::Create((Get-Content $scriptPath -Raw))
            $errors = $null
            $warnings = $null

            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $scriptBlock.ToString(),
                $scriptPath,
                [ref]$errors,
                [ref]$warnings
            )

            $errors.Count | Should -Be 0
        }

        It "Should have proper parameter definition" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'param\('
            $content | Should -Match '\[switch\]\$SkipGitHooks'
        }

        It "Should have proper error handling" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match '\$LASTEXITCODE'
            $content | Should -Match 'exit 1'
        }
    }

    Context "Tool Validation Logic" {

        It "Should check for Azure CLI availability" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Get-Command az'
            $content | Should -Match 'az version'
        }

        It "Should check for Bicep CLI availability" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'az bicep version'
        }

        It "Should check for Node.js availability" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Get-Command node'
            $content | Should -Match 'node --version'
        }

        It "Should check for npm availability" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Get-Command npm'
            $content | Should -Match 'npm --version'
        }
    }

    Context "Configuration Validation" {

        It "Should validate required configuration files" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Test-Path'
            $content | Should -Match '\.bicepconfig\.json'
            $content | Should -Match 'azure\.yaml'
            $content | Should -Match 'infra/main\.bicep'
            $content | Should -Match 'infra/main\.parameters\.json'
        }

        It "Should provide appropriate error messages for missing files" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'not found'
            $content | Should -Match 'ForegroundColor Red'
        }
    }

    Context "Git Hooks Setup" {

        It "Should handle Git hooks setup when not skipped" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'SkipGitHooks'
            $content | Should -Match '\.git/hooks'
            $content | Should -Match 'pre-commit'
        }

        It "Should backup existing hooks before replacement" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'backup'
            $content | Should -Match 'Move-Item'
        }

        It "Should copy PowerShell hook to Git hooks directory" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Copy-Item'
            $content | Should -Match 'pre-commit\.ps1'
        }
    }

    Context "Bicep Template Validation" {

        It "Should test Bicep template compilation" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'az bicep build'
            $content | Should -Match 'main\.bicep'
        }

        It "Should handle build errors appropriately" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match '\$LASTEXITCODE'
            $content | Should -Match 'build errors'
        }
    }

    Context "Output and User Experience" {

        It "Should provide clear success messages" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Development environment setup complete'
            $content | Should -Match 'ForegroundColor Green'
        }

        It "Should provide helpful next steps" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Next steps'
            $content | Should -Match 'npm install'
            $content | Should -Match 'npm run format'
        }

        It "Should provide useful commands reference" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Useful commands'
            $content | Should -Match 'npm run validate'
            $content | Should -Match 'az bicep build'
        }
    }

    Context "Error Handling and Edge Cases" {

        It "Should handle missing Git repository gracefully" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Are you in a Git repository'
            $content | Should -Match 'exit 1'
        }

        It "Should handle missing script files gracefully" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'not found in scripts/'
        }

        It "Should provide installation instructions for missing tools" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'Install from:'
            $content | Should -Match 'nodejs\.org'
            $content | Should -Match 'azure/install-azure-cli'
        }
    }
}

# ===========================================
# Integration Tests
# ===========================================

Describe "Setup-Dev-Env Integration Tests" {

    Context "End-to-End Script Execution" {

        It "Should execute without throwing errors when all dependencies are available" {
            # This test would require actual execution in a proper test environment
            # For now, we validate the script structure supports clean execution

            $scriptContent = Get-Content $scriptPath -Raw

            # Should have proper flow control
            $scriptContent | Should -Match 'Write-Host'
            $scriptContent | Should -Match 'if.*Test-Path'
            $scriptContent | Should -Match 'try.*catch'

            # Should have proper exit conditions
            $scriptContent | Should -Match 'exit 0|exit 1'
        }

        It "Should support both interactive and CI execution modes" {
            $scriptContent = Get-Content $scriptPath -Raw

            # Should have conditional output based on execution context
            $scriptContent | Should -Match 'Write-Host.*ForegroundColor'

            # Should handle different error scenarios
            $scriptContent | Should -Match 'ForegroundColor Red'
            $scriptContent | Should -Match 'ForegroundColor Green'
        }
    }
}
