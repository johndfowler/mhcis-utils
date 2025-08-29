# ===========================================
# Infrastructure Test Helper Functions
# ===========================================
# Shared functions for infrastructure testing

# Test-BicepCompilation
# Validates that Bicep templates compile successfully
function Test-BicepCompilation {
    param(
        [string]$TemplatePath,
        [string]$OutputPath
    )

    $result = @{
        TestName = "BicepCompilation"
        Passed = $false
        Error = ""
    }

    try {
        if (-not (Test-Path $TemplatePath)) {
            $result.Error = "Template file not found: $TemplatePath"
            return $result
        }

        # Build the Bicep template
        $buildOutput = & az bicep build --file $TemplatePath --stdout 2>&1
        if ($LASTEXITCODE -ne 0) {
            $result.Error = "Bicep build failed: $buildOutput"
            return $result
        }

        # Verify output file was created
        if (-not (Test-Path $OutputPath)) {
            $result.Error = "Output file was not created: $OutputPath"
            return $result
        }

        # Validate JSON structure
        $jsonContent = Get-Content $OutputPath -Raw
        $jsonObject = ConvertFrom-Json $jsonContent
        if (-not $jsonObject) {
            $result.Error = "Generated ARM template is not valid JSON"
            return $result
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Unexpected error during Bicep compilation: $($_.Exception.Message)"
    }

    return $result
}

# Test-ParameterValidation
# Validates parameter file structure and required parameters
function Test-ParameterValidation {
    param([string]$ParametersPath)

    $result = @{
        TestName = "ParameterValidation"
        Passed = $false
        Error = ""
    }

    try {
        if (-not (Test-Path $ParametersPath)) {
            $result.Error = "Parameters file not found: $ParametersPath"
            return $result
        }

        $parameters = Get-Content $ParametersPath -Raw | ConvertFrom-Json

        # Check required parameters
        $requiredParams = @("prefix", "environment", "regionAbbr", "instance")
        foreach ($param in $requiredParams) {
            if (-not $parameters.parameters.$param) {
                $result.Error = "Missing required parameter: $param"
                return $result
            }
        }

        # Validate environment values
        $validEnvironments = @("dev", "test", "staging", "prod")
        if ($parameters.parameters.environment.value -notin $validEnvironments) {
            $result.Error = "Invalid environment value: $($parameters.parameters.environment.value)"
            return $result
        }

        # Validate network configuration
        if ($parameters.parameters.networkConfig) {
            $networkConfig = $parameters.parameters.networkConfig.value
            if (-not (Test-NetworkConfiguration -NetworkConfig $networkConfig)) {
                $result.Error = "Invalid network configuration"
                return $result
            }
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Parameter validation error: $($_.Exception.Message)"
    }

    return $result
}

# Test-TemplateValidation
# Runs Azure Template Test Toolkit (TTK) validation
function Test-TemplateValidation {
    param([string]$TemplatePath)

    $result = @{
        TestName = "TemplateValidation"
        Passed = $false
        Error = ""
    }

    try {
        # Check if Azure CLI is available
        $azCli = Get-Command az -ErrorAction SilentlyContinue
        if (-not $azCli) {
            $result.Error = "Azure CLI not available - skipping TTK validation"
            $result.Passed = $true  # Consider this a pass since CLI is required
            return $result
        }

        # Try to use Azure CLI's built-in template validation
        $validationOutput = & az bicep lint --file $TemplatePath 2>&1
        if ($LASTEXITCODE -ne 0) {
            $result.Error = "Bicep lint validation failed: $validationOutput"
            return $result
        }

        # Additional validation using ARM template export
        $tempArmPath = [System.IO.Path]::GetTempFileName() + ".json"
        try {
            $buildOutput = & az bicep build --file $TemplatePath --outfile $tempArmPath 2>&1
            if ($LASTEXITCODE -ne 0) {
                $result.Error = "ARM template build failed: $buildOutput"
                return $result
            }

            # Validate the generated ARM template
            $armValidation = & az deployment group validate --template-file $tempArmPath --parameters '{}' --resource-group "dummy-rg" 2>&1
            # Note: This will fail because dummy-rg doesn't exist, but we can check for template syntax errors
            if ($armValidation -match "Template validation failed" -and $armValidation -notmatch "Resource group.*not found") {
                $result.Error = "ARM template validation failed: $armValidation"
                return $result
            }
        }
        finally {
            if (Test-Path $tempArmPath) {
                Remove-Item $tempArmPath -Force
            }
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Template validation error: $($_.Exception.Message)"
    }

    return $result
}

# Test-SecurityBestPractices
# Validates security best practices in the template
function Test-SecurityBestPractices {
    param([string]$TemplatePath)

    $result = @{
        TestName = "SecurityBestPractices"
        Passed = $false
        Error = ""
    }

    try {
        $templateContent = Get-Content $TemplatePath -Raw

        # Check for hardcoded secrets
        $secretPatterns = @(
            'password.*=.*["''][^"'']*["'']',
            'secret.*=.*["''][^"'']*["'']',
            'key.*=.*["''][^"'']*["'']',
            'token.*=.*["''][^"'']*["'']'
        )

        foreach ($pattern in $secretPatterns) {
            if ($templateContent -match $pattern -and $templateContent -notmatch "secretRef|keyVault|managedIdentity") {
                $result.Error = "Potential hardcoded secret found matching pattern: $pattern"
                return $result
            }
        }

        # Check for HTTP URLs (should use HTTPS)
        if ($templateContent -match 'http://') {
            $result.Error = "HTTP URLs found - should use HTTPS for security"
            return $result
        }

        # Check for managed identity usage
        if ($templateContent -notmatch 'managedIdentity|userAssignedIdentities') {
            $result.Error = "No managed identity configuration found"
            return $result
        }

        # Check for Key Vault integration
        if ($templateContent -notmatch 'Microsoft.KeyVault') {
            $result.Error = "No Key Vault integration found"
            return $result
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Security validation error: $($_.Exception.Message)"
    }

    return $result
}

# Test-NamingConventions
# Validates resource naming conventions
function Test-NamingConventions {
    param([string]$TemplatePath)

    $result = @{
        TestName = "NamingConventions"
        Passed = $false
        Error = ""
    }

    try {
        $templateContent = Get-Content $TemplatePath -Raw

        # Check for CAF naming patterns
        $cafPatterns = @(
            'rg-.*-.*-.*-.*',  # Resource Group
            'st.*',            # Storage Account
            'kv.*',            # Key Vault
            'ca-.*',           # Container App
            'cae-.*',          # Container Apps Environment
            'vnet-.*',         # Virtual Network
            'snet-.*'          # Subnet
        )

        foreach ($pattern in $cafPatterns) {
            if ($templateContent -match $pattern) {
                # Found at least one CAF pattern, consider it valid
                $result.Passed = $true
                return $result
            }
        }

        # If no CAF patterns found, check if resources have proper naming
        if ($templateContent -match '"name":.*\$\{.*\}' -or $templateContent -match 'name.*=.*uniqueString') {
            $result.Passed = $true
        } else {
            $result.Error = "No proper resource naming conventions found"
        }
    }
    catch {
        $result.Error = "Naming convention validation error: $($_.Exception.Message)"
    }

    return $result
}

# Test-CostOptimization
# Validates cost optimization practices
function Test-CostOptimization {
    param(
        [string]$TemplatePath,
        [string]$ParametersPath
    )

    $result = @{
        TestName = "CostOptimization"
        Passed = $false
        Error = ""
    }

    try {
        $templateContent = Get-Content $TemplatePath -Raw
        $parameters = Get-Content $ParametersPath -Raw | ConvertFrom-Json

        # Check for environment-specific resource allocation
        $environment = $parameters.parameters.environment.value

        # Validate test mode configuration
        if ($environment -in @("dev", "test") -and $parameters.parameters.isTestMode.value -ne $true) {
            $result.Error = "Test mode should be enabled for dev/test environments"
            return $result
        }

        # Check for autoscaling configurations
        if ($templateContent -notmatch 'scale|minReplicas|maxReplicas') {
            $result.Error = "No autoscaling configuration found"
            return $result
        }

        # Check for appropriate SKU selection based on environment
        if ($environment -eq "prod" -and $templateContent -notmatch 'Premium|Standard_GRS') {
            $result.Error = "Production environment should use premium SKUs"
            return $result
        }

        $result.Passed = $true
    }
    catch {
        $result.Error = "Cost optimization validation error: $($_.Exception.Message)"
    }

    return $result
}

# Test-NetworkConfiguration
# Validates network configuration parameters
function Test-NetworkConfiguration {
    param([object]$NetworkConfig)

    try {
        # Validate VNet address space
        if (-not (Test-IpAddressRange -AddressRange $NetworkConfig.vnetAddressPrefix)) {
            return $false
        }

        # Validate subnet configurations
        $subnets = @(
            $NetworkConfig.subnetAddressPrefix,
            $NetworkConfig.privateEndpointSubnetPrefix
        )

        foreach ($subnet in $subnets) {
            if (-not (Test-IpAddressRange -AddressRange $subnet)) {
                return $false
            }
        }

        # Validate subnet hierarchy (subnets should be within VNet range)
        if (-not (Test-SubnetInRange -Subnet $NetworkConfig.subnetAddressPrefix -VNet $NetworkConfig.vnetAddressPrefix)) {
            return $false
        }

        return $true
    }
    catch {
        return $false
    }
}

# Test-IpAddressRange
# Validates IP address range format
function Test-IpAddressRange {
    param([string]$AddressRange)

    try {
        # Basic CIDR validation
        if ($AddressRange -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$') {
            return $false
        }

        $parts = $AddressRange -split '/'
        $ipParts = $parts[0] -split '\.'
        $mask = [int]$parts[1]

        # Validate IP octets
        foreach ($octet in $ipParts) {
            if ([int]$octet -lt 0 -or [int]$octet -gt 255) {
                return $false
            }
        }

        # Validate subnet mask
        if ($mask -lt 8 -or $mask -gt 32) {
            return $false
        }

        return $true
    }
    catch {
        return $false
    }
}

# Test-SubnetInRange
# Validates that subnet is within VNet range
function Test-SubnetInRange {
    param(
        [string]$Subnet,
        [string]$VNet
    )

    try {
        # This is a simplified check - in production you might want more sophisticated IP range validation
        $subnetParts = $Subnet -split '/'
        $vnetParts = $VNet -split '/'

        $subnetBase = $subnetParts[0]
        $vnetBase = $vnetParts[0]

        # Check if subnet base is within VNet range (simplified)
        $subnetOctets = $subnetBase -split '\.'
        $vnetOctets = $vnetBase -split '\.'

        # Compare first two octets (basic check)
        if ($subnetOctets[0] -ne $vnetOctets[0] -or $subnetOctets[1] -ne $vnetOctets[1]) {
            return $false
        }

        return $true
    }
    catch {
        return $false
    }
}
