# Development Workflow

This document describes the development workflow and tools configured for the Shade Platform.

| Script                  | Description                             |
| ----------------------- | --------------------------------------- |
| `npm run format`        | Format all files with Prettier          |
| `npm run format:check`  | Check if files are properly formatted   |
| `npm run lint`          | Run all linting checks                  |
| `npm run lint:bicep`    | Lint Bicep templates                    |
| `npm run lint:json`     | Check JSON formatting                   |
| `npm run lint:yaml`     | Check YAML formatting                   |
| `npm run lint:markdown` | Check Markdown formatting               |
| `npm run validate`      | Run comprehensive validation            |
| `npm run test`          | Run all infrastructure and script tests |
| `npm run test:infra`    | Run infrastructure tests only           |
| `npm run test:scripts`  | Run script tests only                   |
| `npm run test:ci`       | Run tests in CI mode                    |
| `npm run dev:setup`     | Run development environment setup       |
| `npm run azure:deploy`  | Deploy to Azure with azd                |
| `npm run azure:down`    | Remove Azure resources                  |

## 🛠️ Development Tools

### Prettier

- **Purpose**: Automatic code formatting for JSON, YAML, and Markdown files
- **Configuration**: `.prettierrc` with project-specific rules
- **Usage**: `npm run format` to format all files

### Husky

- **Purpose**: Modern Git hooks for automated quality checks
- **Version**: v9+ (modern setup)
- **Hooks**:
  - `pre-commit`: Runs lint-staged, infrastructure tests, and script validation
  - `commit-msg`: Validates conventional commit message format
- **Setup**: Automatic initialization via `npm run dev:setup`

### Lint-staged

- **Purpose**: Runs linters on staged files only
- **Configuration**: Defined in `package.json`

### Infrastructure Testing Framework

- **Purpose**: Comprehensive testing for infrastructure and scripts
- **Components**:
  - **Azure Template Test Toolkit (TTK)**: Microsoft's official ARM/Bicep validation
  - **Pester**: PowerShell testing framework for script validation
  - **Custom Infrastructure Tests**: Security, naming, and cost optimization validation
- **Usage**: `npm run test` to run all tests

## 🚀 Quick Start

### Initial Setup

```bash
# Install development dependencies
npm install

# Run initial setup (configures modern Husky and Git hooks)
npm run dev:setup
```

### Daily Workflow

```bash
# Format all files
npm run format

# Run all linting checks
npm run lint

# Run comprehensive validation
npm run validate

# Run all tests
npm run test

# Deploy to Azure
npm run azure:deploy
```

## 📝 Commit Message Format

Use conventional commit format:

```
<type>[optional scope]: <description>

Examples:
feat: add Key Vault random name generation
fix(bicep): resolve BCP318 warning
docs: update deployment instructions
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`

## 🧪 Testing Framework

The project includes a comprehensive testing framework for both infrastructure and scripts:

### Infrastructure Tests

- **Bicep Template Compilation**: Validates templates compile successfully
- **Parameter Validation**: Ensures required parameters are present and valid
- **Azure Template Test Toolkit (TTK)**: Microsoft's official validation tests via Azure CLI
- **Security Best Practices**: Validates security configurations
- **Resource Naming Conventions**: Ensures CAF naming compliance
- **Cost Optimization**: Validates resource allocation and scaling

### Current Test Status

```
🧪 Infrastructure Tests: ✅ All 6/6 tests passing
📝 Bicep Template Compilation: ✅
📋 Parameter Validation: ✅
🔧 Azure Template Test Toolkit: ✅ (Fixed - now uses Azure CLI)
🔒 Security Best Practices: ✅
🏷️ Resource Naming Conventions: ✅
💰 Cost Optimization: ✅
```

### Script Tests

- **Syntax Validation**: Ensures PowerShell scripts are syntactically correct
- **Best Practices**: Validates PowerShell coding standards
- **Pester Unit Tests**: Runs unit tests for script functions
- **Dependency Validation**: Checks for required tools and modules
- **Documentation**: Validates script documentation quality

### Running Tests

```bash
# Run all tests
npm run test

# Run infrastructure tests only
npm run test:infra

# Run script tests only
npm run test:scripts

# Run tests in CI mode (less verbose)
npm run test:ci
```

### Test Configuration

Test settings are configured in `tests/test-config.psd1`:

- Enable/disable specific test categories
- Configure timeouts and parallel execution
- Set CI-specific options
- Define validation rules and patterns

## 🎯 Pre-commit Checks

When you commit, the following checks run automatically:

1. **Lint-staged**: Formats staged files with Prettier
2. **Bicep validation**: Ensures templates compile successfully
3. **Infrastructure tests**: Runs critical infrastructure validation tests
4. **Script validation**: Validates PowerShell script syntax and best practices
5. **PowerShell linting**: Runs comprehensive validation script
6. **Commit message**: Validates conventional commit format

If any check fails, the commit is rejected.

## 🔧 Configuration Files

- `.prettierrc` - Prettier formatting rules
- `.prettierignore` - Files to ignore during formatting
- `.bicepconfig.json` - Bicep linter configuration
- `.husky/pre-commit` - Pre-commit hook script
- `.husky/commit-msg` - Commit message validation
- `package.json` - npm scripts and lint-staged config

## 🆕 Recent Improvements

### Infrastructure Testing Framework Updates

#### Fixed Azure Template Test Toolkit (TTK) Integration

- **Issue**: Previous implementation attempted to install non-existent `AzTemplateToolkit` PowerShell module
- **Solution**: Updated to use Azure CLI's built-in validation tools (`az bicep lint`, `az deployment group validate`)
- **Impact**: All 6 infrastructure tests now pass consistently
- **Benefits**: No external dependencies, faster validation, more reliable testing

#### Enhanced Test Reliability

- Improved error handling in test helper functions
- Better parameter validation for network configurations
- More robust file path handling in test runner
- Graceful fallback for missing Azure CLI components

### Development Workflow Enhancements

#### Modern Husky v9+ Setup

- Removed deprecated `prepare` script from package.json
- Updated to use modern Husky initialization
- Improved Git hook reliability and performance

#### Comprehensive Validation Pipeline

- Pre-commit hooks now run all critical validation tests
- CI/CD integration with GitHub Actions
- Consistent validation across local development and CI environments

## 🎨 Code Style

### Prettier Configuration

- **Print Width**: 100 characters (120 for JSON/YAML)
- **Tab Width**: 2 spaces
- **Quotes**: Double quotes
- **Semicolons**: Always
- **Trailing Commas**: ES5 compatible
- **Line Endings**: LF (Unix-style)

### File-specific Rules

- **JSON**: 120 character width
- **YAML**: 120 character width, 2-space indentation
- **Markdown**: 100 character width, preserve prose wrapping
- **Bicep**: No formatting (handled by Bicep tooling)

## ⚠️ Expected Warnings

The following warnings are expected and intentional:

### `use-stable-resource-identifiers` (Key Vault)

- **Why**: We intentionally generate unique Key Vault names to avoid soft-delete conflicts
- **Status**: Suppressed in `.bicepconfig.json`
- **Impact**: None - this is the desired behavior

## 🔄 CI/CD Integration

The same linting and validation rules are enforced in:

- Pre-commit hooks (developer machine)
- GitHub Actions workflows (CI/CD pipeline)
- Manual validation via `npm run validate`

This ensures consistent code quality across all environments.
