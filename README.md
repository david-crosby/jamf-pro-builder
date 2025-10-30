# Jamf Pro Tenancy Setup Automation

A comprehensive ZSH-based automation toolkit for building out a Jamf Pro tenancy from scratch. This suite of scripts handles everything from API authentication to zero-touch deployment configuration, enabling rapid deployment of enterprise-grade macOS management infrastructure.

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Modules](#modules)
- [Usage](#usage)
- [Post-Setup Tasks](#post-setup-tasks)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Licence](#licence)

## ✨ Features

This automation toolkit configures the following components in your Jamf Pro tenancy:

### Core Features
- **API Authentication**: OAuth 2.0 client credentials flow with automatic token management
- **Smart Groups**: macOS version tracking for current and last 2 major versions
- **CIS Benchmarks**: Automated deployment of CIS Level 1 and Level 2 compliance benchmarks
- **Single Sign-On**: SAML and Azure AD SSO integration for user authentication
- **Mail Server**: SMTP configuration for notifications and reports
- **Automated Device Enrolment**: Complete ADE setup with Apple Business Manager integration
- **Zero-Touch Deployment**: PreStage enrolment configuration with customisable Setup Assistant screens
- **User Management**: Automated creation of Jamf Pro user accounts with appropriate privileges

### Additional Capabilities
- **Jamf Connect Support**: Configuration scaffolding for Jamf Connect deployment
- **Platform SSO**: Support for macOS 13+ Platform SSO configuration
- **Dry Run Mode**: Test all operations without making actual changes
- **Comprehensive Logging**: Detailed logs of all operations for audit and troubleshooting
- **Modular Architecture**: Each component can be run independently or as part of the full setup

## 🔧 Prerequisites

### System Requirements
- macOS 10.15 or later
- ZSH shell (default on macOS Catalina+)
- Internet connectivity to reach your Jamf Pro instance

### Required Tools
The following command-line tools must be installed:
- `curl` - For API requests (pre-installed on macOS)
- `jq` - For JSON parsing ([install via Homebrew](https://stedolan.github.io/jq/))
- `openssl` - For secure password generation (pre-installed on macOS)

Install jq if not already present:
```bash
brew install jq
```

### Jamf Pro Requirements
- Jamf Pro 10.49.0 or later (for full API support)
- API client credentials with the following permissions:
  - Create, Read, Update Computer Groups
  - Create, Read, Update Configuration Profiles
  - Create, Read, Update Policies
  - Create, Read, Update PreStage Enrolments
  - Create, Read, Update User Accounts
  - Read, Update SSO Settings
  - Read, Update SMTP Server Settings
  - Read, Update Automated Device Enrolment

### Apple Business Manager
- Active Apple Business Manager account
- Administrator or Device Manager role
- Ability to download ADE server tokens

## 🚀 Quick Start

### 1. Download the Scripts

Clone or download all scripts to a directory:
```bash
git clone https://github.com/david-crosby/jamf-tenancy-setup.git
cd jamf-tenancy-setup
```

### 2. Create API Client in Jamf Pro

Before running the scripts, manually create an API client in Jamf Pro:

1. Log into your Jamf Pro instance
2. Navigate to Settings → System → API Roles and Clients
3. Click "+ New" to create a new API role
4. Grant all required permissions (see Prerequisites)
5. Click "+ New" under API Clients
6. Name the client (e.g., "Tenancy Setup Automation")
7. Assign the role created in step 4
8. Save and note the Client ID and Client Secret

### 3. Configure the Setup

Edit the configuration file:
```bash
nano jamf-config.conf
```

At minimum, set the following required variables:
```bash
JAMF_URL="https://yourcompany.jamfcloud.com"
JAMF_CLIENT_ID="your-client-id-here"
JAMF_CLIENT_SECRET="your-client-secret-here"
ORGANISATION_NAME="Your Company Name"
```

### 4. Run the Setup

Execute the main setup script:
```bash
./jamf-setup.sh
```

For a dry run (test without making changes):
```bash
./jamf-setup.sh --dry-run
```

## ⚙️ Configuration

The `jamf-config.conf` file contains all configuration parameters. Key sections include:

### Jamf Pro Instance
```bash
JAMF_URL="https://yourcompany.jamfcloud.com"
JAMF_CLIENT_ID="your-client-id"
JAMF_CLIENT_SECRET="your-client-secret"
```

### SSO Configuration
```bash
ENABLE_SSO="true"
SSO_PROVIDER="SAML"  # or "Azure AD", "Okta", "Google", "OneLogin"

# For SAML
SAML_ENTITY_ID="https://yourcompany.jamfcloud.com"
SAML_IDP_METADATA_URL="https://your-idp.com/metadata"
SAML_SSO_URL="https://your-idp.com/sso"

# For Azure AD
AZURE_TENANT_ID="your-tenant-id"
AZURE_CLIENT_ID="your-azure-client-id"
AZURE_CLIENT_SECRET="your-azure-secret"
```

### Mail Server
```bash
MAIL_SERVER_ADDRESS="smtp.gmail.com"
MAIL_SERVER_PORT="587"
MAIL_SENDER_EMAIL="[email protected]"
MAIL_USERNAME="[email protected]"
MAIL_PASSWORD="your-app-password"
MAIL_USE_TLS="true"
```

### ADE Configuration
```bash
ADE_TOKEN_FILE_PATH="/path/to/your-ade-token.p7m"
ADE_INSTANCE_NAME="Primary ADE Server"
```

### macOS Versions
```bash
MACOS_CURRENT_VERSION="15"
MACOS_CURRENT_NAME="Sequoia"
MACOS_PREVIOUS_VERSION_1="14"
MACOS_PREVIOUS_NAME_1="Sonoma"
MACOS_PREVIOUS_VERSION_2="13"
MACOS_PREVIOUS_NAME_2="Ventura"
```

### CIS Benchmarks
```bash
ENABLE_CIS_LEVEL_1="true"
ENABLE_CIS_LEVEL_2="true"
CIS_LEVEL_1_MODE="monitor"  # or "enforce"
CIS_LEVEL_2_MODE="monitor"  # or "enforce"
```

### User Accounts
```bash
JAMF_USERS=(
    "admin:Administrator:admin@company.com:administrator"
    "readonly:Read Only:readonly@company.com:auditor"
)
```

## 📦 Modules

The toolkit is organised into modular scripts:

### Core Scripts

#### `jamf-setup.sh` (Main Orchestrator)
The primary entry point that coordinates all modules and provides:
- Pre-flight checks
- Sequential module execution
- Progress tracking
- Summary reporting
- Error handling

#### `jamf-helpers.sh` (Helper Library)
Shared functions used across all modules:
- API authentication and token management
- HTTP request wrappers (GET, POST, PUT, DELETE)
- Logging functions
- Configuration validation
- Utility functions

### Module Scripts

#### `jamf-smart-groups.sh`
Creates smart groups for macOS version management:
- Groups for current and last 2 major macOS versions
- Group for outdated/unsupported macOS versions
- Optional groups for latest patches and update tracking

#### `jamf-cis-benchmarks.sh`
Configures CIS compliance benchmarks:
- Enables CIS Level 1 and Level 2 benchmarks
- Configures monitoring or enforcement mode
- Creates scope smart groups
- Deploys benchmark configurations

#### `jamf-sso.sh`
Sets up Single Sign-On integration:
- SAML 2.0 configuration
- Azure AD integration
- SSO enabling for user authentication
- Configuration testing

#### `jamf-mail-server.sh`
Configures SMTP mail server:
- SMTP server connection settings
- Authentication configuration
- TLS/SSL support
- Test email functionality

#### `jamf-ade-prestage.sh`
Manages ADE and PreStage enrolment:
- Downloads ADE public key
- Uploads ADE server token
- Creates zero-touch PreStage enrolment
- Configures Setup Assistant screens
- Jamf Connect and Platform SSO scaffolding

#### `jamf-users.sh`
Creates user accounts:
- Standard user account creation
- Privilege set assignment
- Secure password generation
- Credential management

## 🎯 Usage

### Running the Complete Setup

Standard execution:
```bash
./jamf-setup.sh
```

### Running Individual Modules

Each module can be run independently:

```bash
# Smart groups only
./jamf-smart-groups.sh

# CIS benchmarks only
./jamf-cis-benchmarks.sh

# SSO configuration only
./jamf-sso.sh

# Mail server only
./jamf-mail-server.sh

# ADE and PreStage only
./jamf-ade-prestage.sh

# User accounts only
./jamf-users.sh
```

### Command-Line Options

```bash
./jamf-setup.sh [OPTIONS]

OPTIONS:
    -h, --help          Display help message
    -c, --config FILE   Use alternate configuration file
    -d, --dry-run       Run in dry-run mode (no changes made)
    -v, --version       Display script version
```

### Examples

Test run without making changes:
```bash
./jamf-setup.sh --dry-run
```

Use a custom configuration file:
```bash
./jamf-setup.sh --config production-config.conf
```

Run only smart groups setup:
```bash
source jamf-config.conf
source jamf-helpers.sh
./jamf-smart-groups.sh
```

## 📝 Post-Setup Tasks

After running the automation, complete these manual tasks:

### 1. Review Logs
Check the log file for any warnings or errors:
```bash
cat /tmp/jamf-setup-*.log
```

### 2. Secure Credentials
Review and securely store generated user credentials:
```bash
cat /tmp/jamf-credentials.txt
# Then delete the file
rm /tmp/jamf-credentials.txt
```

### 3. Verify SSO
1. Log into Jamf Pro web interface
2. Test SSO authentication
3. Verify user attribute mapping
4. Confirm group synchronisation

### 4. Test Mail Server
Send test notifications to verify SMTP configuration

### 5. Complete ADE Setup
If not already done:
1. Upload the public key to Apple Business Manager
2. Download the server token (.p7m file)
3. Update `ADE_TOKEN_FILE_PATH` in configuration
4. Re-run the ADE module

### 6. Configure Jamf Connect
Create and deploy the Jamf Connect configuration profile with:
- OIDC provider settings
- Client ID and redirect URI
- Local password synchronisation
- Token refresh settings

### 7. Configure Platform SSO
For macOS 13+, create the Platform SSO configuration profile

### 8. Test Zero-Touch Deployment
Enrol a test device through ADE to verify the workflow

### 9. Review CIS Compliance
Check compliance reports and adjust benchmark settings as needed

## 🔍 Troubleshooting

### Common Issues

#### Authentication Failures
**Problem**: "Failed to obtain bearer token"

**Solutions**:
- Verify `JAMF_URL` is correct and accessible
- Check `JAMF_CLIENT_ID` and `JAMF_CLIENT_SECRET` are correct
- Ensure API client has necessary permissions
- Verify network connectivity to Jamf Pro instance

#### Missing Required Commands
**Problem**: "Required command 'jq' is not installed"

**Solution**:
```bash
brew install jq
```

#### API Permission Errors
**Problem**: "Failed to create..." or "403 Forbidden" errors

**Solution**:
- Review API client permissions in Jamf Pro
- Ensure all required permissions are granted
- Create a new API role with full permissions if needed

#### ADE Token Upload Failures
**Problem**: "Failed to upload ADE server token"

**Solutions**:
- Verify the token file path is correct
- Ensure the .p7m file is valid and not expired
- Check file permissions (readable by the script)

### Debug Mode

Enable verbose logging by adding debug flags:
```bash
set -x  # Enable command tracing
./jamf-setup.sh
set +x  # Disable command tracing
```

### Getting Help

If you encounter issues:
1. Review the log file (`/tmp/jamf-setup-*.log`)
2. Check the [Troubleshooting](#troubleshooting) section
3. Verify all prerequisites are met
4. Test individual modules to isolate issues
5. Open an issue on GitHub with:
   - Error message
   - Relevant log excerpts
   - Jamf Pro version
   - macOS version

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Follow Conventional Commits format
4. Add tests if applicable
5. Update documentation
6. Submit a pull request

## 📄 Licence

This project is provided as-is for educational and professional use. Please review and test thoroughly before using in production environments.

## 👤 Author

**David Crosby (Bing)**
- GitHub: [@david-crosby](https://github.com/david-crosby)
- LinkedIn: [david-bing-crosby](https://www.linkedin.com/in/david-bing-crosby/)

## 🙏 Acknowledgements

- Jamf Nation Community for API documentation and best practices
- macOS Security Compliance Project contributors
- CIS Benchmarks team

## 📚 Additional Resources

- [Jamf Pro API Documentation](https://developer.jamf.com/jamf-pro/docs)
- [Apple Business Manager User Guide](https://support.apple.com/guide/apple-business-manager)
- [CIS Benchmarks](https://www.cisecurity.org/benchmark/apple_os)
- [Jamf Nation Community](https://community.jamf.com/)

---

**Note**: This automation toolkit is designed for initial tenancy setup. For ongoing management, consider implementing additional automation, monitoring, and maintenance procedures.
