# ===========================================
# Infrastructure Testing Configuration
# ===========================================
# Configuration file for infrastructure testing framework

@{
    # Test Configuration
    TestSettings = @{
        # Enable/disable specific test categories
        EnableBicepTests = $true
        EnableParameterTests = $true
        EnableTTKTests = $true
        EnableSecurityTests = $true
        EnableNamingTests = $true
        EnableCostTests = $true
        EnableScriptTests = $true

        # Test execution settings
        FailOnWarning = $false
        ContinueOnError = $true
        VerboseOutput = $true

        # CI-specific settings
        CI = @{
            TimeoutMinutes = 30
            MaxParallelTests = 4
            GenerateReports = $true
            ReportFormats = @("NUnit", "JUnit")
        }
    }

    # Tool Configuration
    Tools = @{
        # Azure CLI settings
        AzureCLI = @{
            RequiredVersion = "2.50.0"
            TimeoutSeconds = 300
        }

        # Bicep CLI settings
        BicepCLI = @{
            RequiredVersion = "0.20.0"
            TimeoutSeconds = 180
        }

        # Pester settings
        Pester = @{
            MinimumVersion = "5.0.0"
            Configuration = @{
                Run = @{
                    Path = @()
                    PassThru = $true
                }
                Output = @{
                    Verbosity = "Detailed"
                }
                TestResult = @{
                    Enabled = $true
                    OutputFormat = "NUnitXml"
                }
            }
        }

        # Azure Template Test Toolkit
        TTK = @{
            ModuleName = "AzTemplateToolkit"
            RequiredVersion = "1.0.0"
            TimeoutSeconds = 300
        }
    }

    # File Paths
    Paths = @{
        # Infrastructure files
        Infrastructure = @{
            MainTemplate = "infra/main.bicep"
            Parameters = "infra/main.parameters.json"
            CompiledTemplate = "infra/main.json"
            Modules = "infra/modules"
        }

        # Script files
        Scripts = @{
            Root = "scripts"
            Tests = "tests/scripts"
            Helpers = "tests/shared"
        }

        # Test output
        TestOutput = @{
            Root = "tests/results"
            Infrastructure = "tests/results/infra"
            Scripts = "tests/results/scripts"
            Reports = "tests/results/reports"
        }

        # Configuration files
        Config = @{
            BicepConfig = ".bicepconfig.json"
            PackageJson = "package.json"
            AzureYaml = "azure.yaml"
        }
    }

    # Test Categories
    TestCategories = @{
        Infrastructure = @{
            BicepCompilation = @{
                Name = "Bicep Template Compilation"
                Description = "Validates that Bicep templates compile successfully"
                Severity = "Critical"
                TimeoutSeconds = 180
            }
            ParameterValidation = @{
                Name = "Parameter Validation"
                Description = "Validates parameter files and required parameters"
                Severity = "High"
                TimeoutSeconds = 60
            }
            TemplateValidation = @{
                Name = "Azure Template Test Toolkit"
                Description = "Runs Microsoft TTK validation tests"
                Severity = "High"
                TimeoutSeconds = 300
            }
            SecurityBestPractices = @{
                Name = "Security Best Practices"
                Description = "Validates security configurations and best practices"
                Severity = "Critical"
                TimeoutSeconds = 120
            }
            NamingConventions = @{
                Name = "Resource Naming Conventions"
                Description = "Validates CAF naming conventions"
                Severity = "Medium"
                TimeoutSeconds = 60
            }
            CostOptimization = @{
                Name = "Cost Optimization"
                Description = "Validates cost optimization practices"
                Severity = "Medium"
                TimeoutSeconds = 90
            }
        }

        Scripts = @{
            SyntaxValidation = @{
                Name = "Script Syntax Validation"
                Description = "Validates PowerShell script syntax"
                Severity = "Critical"
                TimeoutSeconds = 60
            }
            BestPractices = @{
                Name = "Script Best Practices"
                Description = "Validates PowerShell best practices"
                Severity = "High"
                TimeoutSeconds = 90
            }
            PesterTests = @{
                Name = "Pester Unit Tests"
                Description = "Runs Pester unit tests for scripts"
                Severity = "High"
                TimeoutSeconds = 300
            }
            Dependencies = @{
                Name = "Script Dependencies"
                Description = "Validates script dependencies"
                Severity = "Medium"
                TimeoutSeconds = 60
            }
            Documentation = @{
                Name = "Script Documentation"
                Description = "Validates script documentation"
                Severity = "Low"
                TimeoutSeconds = 60
            }
        }
    }

    # Validation Rules
    ValidationRules = @{
        # Bicep-specific rules
        Bicep = @{
            RequiredParameters = @("prefix", "environment", "regionAbbr", "instance")
            ForbiddenPatterns = @(
                "password.*=.*[^$]",
                "secret.*=.*[^$]",
                "key.*=.*[^$]",
                "http://"
            )
            RequiredPatterns = @(
                "Microsoft.KeyVault",
                "Microsoft.Storage",
                "Microsoft.App"
            )
        }

        # Security rules
        Security = @{
            RequiredManagedIdentity = $true
            RequiredHttps = $true
            ForbiddenSharedKey = $true
            RequiredEncryption = $true
        }

        # Naming convention rules
        Naming = @{
            ResourceGroupPattern = 'rg-.*-.*-.*-.*'
            StorageAccountPattern = 'st.*'
            KeyVaultPattern = 'kv.*'
            ContainerAppPattern = 'ca-.*'
            VNetPattern = 'vnet-.*'
            SubnetPattern = 'snet-.*'
        }

        # Cost optimization rules
        Cost = @{
            MaxReplicas = 10
            MinReplicas = 0
            PreferredSku = "Standard_LRS"
            TestModeResourceReduction = 0.5
        }
    }

    # Environment-specific configurations
    Environments = @{
        dev = @{
            TestMode = $true
            PrivateEndpoints = $false
            ResourceReduction = 0.5
            MonitoringRetention = 30
        }
        test = @{
            TestMode = $true
            PrivateEndpoints = $false
            ResourceReduction = 0.7
            MonitoringRetention = 30
        }
        staging = @{
            TestMode = $false
            PrivateEndpoints = $true
            ResourceReduction = 0.8
            MonitoringRetention = 90
        }
        prod = @{
            TestMode = $false
            PrivateEndpoints = $true
            ResourceReduction = 1.0
            MonitoringRetention = 365
        }
    }

    # Reporting configuration
    Reporting = @{
        Formats = @("Console", "NUnit", "JUnit", "HTML")
        IncludeCodeCoverage = $true
        GenerateBadges = $true
        PublishResults = $true
        RetentionDays = 30
    }
}
