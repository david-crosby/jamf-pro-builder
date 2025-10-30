# Example Usage Scenario

This document provides a real-world example of setting up a Jamf Pro tenancy for a fictional company "Acme Corporation".

## Company Profile

**Acme Corporation**
- 500 Mac computers across 3 offices
- Using Microsoft Azure AD for identity management
- Office 365 for email
- Purchasing new Macs through Apple Business Manager
- Security requirement: CIS Level 1 compliance
- IT team of 5 people

## Pre-Setup Checklist

- [x] Jamf Pro instance: `acme.jamfcloud.com`
- [x] Azure AD tenant configured
- [x] Apple Business Manager account active
- [x] Office 365 SMTP relay configured
- [x] API client created in Jamf Pro
- [x] All 5 IT team members identified

## Configuration File

Here's the complete `jamf-config.conf` for Acme Corporation:

```bash
# ============================================================================
# Acme Corporation - Jamf Pro Configuration
# ============================================================================

# ----------------------------------------------------------------------------
# Jamf Pro Instance Configuration
# ----------------------------------------------------------------------------
JAMF_URL="https://acme.jamfcloud.com"
JAMF_CLIENT_ID="acme-setup-client-2024"
JAMF_CLIENT_SECRET="super-secret-key-abc123xyz"

# ----------------------------------------------------------------------------
# SSO Configuration
# ----------------------------------------------------------------------------
ENABLE_SSO="true"
SSO_PROVIDER="Azure AD"

# Azure AD Configuration
AZURE_TENANT_ID="12345678-1234-1234-1234-123456789abc"
AZURE_CLIENT_ID="87654321-4321-4321-4321-cba987654321"
AZURE_CLIENT_SECRET="azure-client-secret-def456"

# ----------------------------------------------------------------------------
# Mail Server Configuration
# ----------------------------------------------------------------------------
MAIL_SERVER_ADDRESS="smtp.office365.com"
MAIL_SERVER_PORT="587"
MAIL_SENDER_EMAIL="[email protected]"
MAIL_USERNAME="[email protected]"
MAIL_PASSWORD="office365-app-password"
MAIL_USE_TLS="true"

# ----------------------------------------------------------------------------
# Automated Device Enrolment (ADE) Configuration
# ----------------------------------------------------------------------------
ADE_TOKEN_FILE_PATH="/Users/admin/Desktop/AcmeADE_Token.p7m"
ADE_INSTANCE_NAME="Acme Corporation ADE"

# ----------------------------------------------------------------------------
# PreStage Enrolment Configuration
# ----------------------------------------------------------------------------
PRESTAGE_NAME="Acme Zero Touch Deployment"

# Skip these Setup Assistant screens for faster deployment
SKIP_SETUP_ASSISTANT_SCREENS="true"
SKIP_ACCESSIBILITY="false"     # Keep for accessibility needs
SKIP_APPEARANCE="true"
SKIP_APPLE_ID="true"           # Managed devices don't need Apple ID
SKIP_BIOMETRIC="false"         # Keep for Touch ID setup
SKIP_DIAGNOSTICS="true"
SKIP_DISPLAY_TONE="true"
SKIP_LOCATION="true"
SKIP_PAYMENT="true"
SKIP_PRIVACY="true"
SKIP_REGISTRATION="true"
SKIP_RESTORE="true"
SKIP_SCREEN_TIME="true"
SKIP_SIRI="true"
SKIP_TOS="false"               # Keep for legal compliance

# ----------------------------------------------------------------------------
# Jamf Connect Configuration
# ----------------------------------------------------------------------------
ENABLE_JAMF_CONNECT="true"
JAMF_CONNECT_OIDC_PROVIDER="https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0"
JAMF_CONNECT_CLIENT_ID="${AZURE_CLIENT_ID}"
JAMF_CONNECT_REDIRECT_URI="https://127.0.0.1/jamfconnect"

# ----------------------------------------------------------------------------
# Platform SSO Configuration
# ----------------------------------------------------------------------------
ENABLE_PLATFORM_SSO="false"  # Will enable after testing Jamf Connect

# ----------------------------------------------------------------------------
# Smart Groups Configuration
# ----------------------------------------------------------------------------
# Current: macOS 15 Sequoia
# Previous: macOS 14 Sonoma, macOS 13 Ventura
MACOS_CURRENT_VERSION="15"
MACOS_CURRENT_NAME="Sequoia"
MACOS_PREVIOUS_VERSION_1="14"
MACOS_PREVIOUS_NAME_1="Sonoma"
MACOS_PREVIOUS_VERSION_2="13"
MACOS_PREVIOUS_NAME_2="Ventura"

# ----------------------------------------------------------------------------
# CIS Benchmarks Configuration
# ----------------------------------------------------------------------------
ENABLE_CIS_LEVEL_1="true"
ENABLE_CIS_LEVEL_2="false"  # Will enable after Level 1 is stable
CIS_LEVEL_1_MODE="monitor"  # Start with monitor, move to enforce later

# ----------------------------------------------------------------------------
# User Accounts Configuration
# ----------------------------------------------------------------------------
JAMF_USERS=(
    "john.smith:John Smith:[email protected]:administrator"
    "jane.doe:Jane Doe:[email protected]:administrator"
    "bob.jones:Bob Jones:[email protected]:administrator"
    "alice.wilson:Alice Wilson:[email protected]:custom"
    "charlie.brown:Charlie Brown:[email protected]:auditor"
)

# ----------------------------------------------------------------------------
# Organisational Settings
# ----------------------------------------------------------------------------
ORGANISATION_NAME="Acme Corporation"
ORGANISATION_CONTACT_NAME="John Smith"
ORGANISATION_CONTACT_EMAIL="[email protected]"
ORGANISATION_CONTACT_PHONE="+44 121 496 0000"

# ----------------------------------------------------------------------------
# Additional Settings
# ----------------------------------------------------------------------------
AUTO_DEVICE_NAMING="true"
DEVICE_NAME_PREFIX="ACME"
AUTO_INVENTORY_UPDATE="true"
INVENTORY_UPDATE_FREQUENCY="86400"
ENABLE_PUSH_NOTIFICATIONS="true"

LOG_FILE="/tmp/jamf-setup-$(date +%Y%m%d-%H%M%S).log"
DRY_RUN="false"
```

## Execution Steps

### Step 1: Preparation (Day 1)

```bash
# Create directory for setup
mkdir ~/acme-jamf-setup
cd ~/acme-jamf-setup

# Copy all scripts and config
# (scripts downloaded from repository)

# Make scripts executable
chmod +x jamf-*.sh

# Edit configuration
nano jamf-config.conf
# (paste the configuration above)
```

### Step 2: Dry Run (Day 1)

```bash
# Test the configuration without making changes
./jamf-setup.sh --dry-run

# Review output for any errors
# Fix any configuration issues
```

Expected output:
```
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║               Jamf Pro Tenancy Setup Automation Script                  ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

[2025-10-30 10:00:00] [INFO] Configuration file: /Users/admin/acme-jamf-setup/jamf-config.conf
[2025-10-30 10:00:00] [INFO] Jamf Pro URL: https://acme.jamfcloud.com
[2025-10-30 10:00:00] [WARNING] DRY RUN MODE: No changes will be made to Jamf Pro

Press Enter to begin setup...

[2025-10-30 10:00:05] [INFO] Running pre-flight checks...
[2025-10-30 10:00:05] [SUCCESS] All required commands are available
[2025-10-30 10:00:05] [SUCCESS] Configuration validation complete
[2025-10-30 10:00:06] [SUCCESS] Bearer token obtained
[2025-10-30 10:00:06] [SUCCESS] Pre-flight checks completed successfully
```

### Step 3: Execute Setup (Day 1)

```bash
# Run the actual setup
./jamf-setup.sh

# Monitor progress
# The script will take 5-10 minutes to complete
```

### Step 4: ADE Configuration (Day 1-2)

```bash
# The script downloaded the public key
# Upload to Apple Business Manager:
# 1. Log into business.apple.com
# 2. Go to Settings → MDM Server Management
# 3. Click "Add MDM Server"
# 4. Name: "Acme Jamf Pro"
# 5. Upload: /tmp/jamf-ade-public-key.pem
# 6. Download token: AcmeADE_Token.p7m
# 7. Save to Desktop

# Re-run ADE setup with token
./jamf-ade-prestage.sh
```

### Step 5: Post-Setup (Day 2)

```bash
# Store user credentials securely
cat /tmp/jamf-credentials.txt
# Copy to password manager
rm /tmp/jamf-credentials.txt

# Test SSO login
# Navigate to https://acme.jamfcloud.com
# Log in using Azure AD credentials

# Test mail server
# Send a test notification from Jamf Pro
```

### Step 6: Create Jamf Connect Profile (Day 2)

Manually create the Jamf Connect configuration profile:

1. In Jamf Pro, navigate to **Configuration Profiles**
2. Click **New**
3. Add **Application & Custom Settings** payload
4. Configure with:
   - OIDC Provider: `https://login.microsoftonline.com/12345678-1234-1234-1234-123456789abc/v2.0`
   - Client ID: `87654321-4321-4321-4321-cba987654321`
   - Redirect URI: `https://127.0.0.1/jamfconnect`
5. Add to PreStage enrolment

### Step 7: Test Deployment (Day 3)

```bash
# Enrol test device
# 1. Add Mac to Apple Business Manager
# 2. Assign to Acme Jamf Pro MDM server
# 3. Erase and power on Mac
# 4. Verify zero-touch enrolment
# 5. Check Jamf Connect authentication
# 6. Confirm policies apply correctly
```

## Results

After completion, Acme Corporation has:

✅ **Smart Groups Created**:
- macOS 15 - Sequoia
- macOS 14 - Sonoma
- macOS 13 - Ventura
- macOS - Outdated (Not 15, 14, or 13)

✅ **CIS Benchmark Enabled**:
- CIS Level 1 in monitor mode
- 150+ security controls being tracked
- Compliance reports available

✅ **SSO Configured**:
- Azure AD integration active
- User attributes mapping correctly
- Groups synchronising

✅ **Mail Server Working**:
- Notifications sending successfully
- Reports delivering to [email protected]

✅ **Zero-Touch Deployment Active**:
- ADE connected to Apple Business Manager
- PreStage enrolment configured
- Setup Assistant optimised

✅ **5 User Accounts Created**:
- 3 administrators (John, Jane, Bob)
- 1 custom access user (Alice)
- 1 read-only auditor (Charlie)

## Timeline Summary

| Day | Tasks | Duration |
|-----|-------|----------|
| Day 1 | API setup, configuration, dry run, execution | 2 hours |
| Day 1-2 | ADE setup in Apple Business Manager | 30 minutes |
| Day 2 | Post-setup verification, Jamf Connect profile | 1 hour |
| Day 3 | Test device enrolment | 30 minutes |
| **Total** | | **4 hours** |

## Maintenance

After initial setup, Acme maintains their tenancy with:

1. **Monthly reviews** of CIS compliance reports
2. **Quarterly updates** to smart groups for new macOS versions
3. **Annual renewal** of ADE server token
4. **Ongoing** policy and profile management

## Lessons Learned

1. **Start with monitor mode** for CIS benchmarks before enforcing
2. **Test SSO thoroughly** before requiring it for all users
3. **Have ADE token ready** before running setup to save time
4. **Keep credentials secure** immediately after generation
5. **Document customisations** made after automated setup

## Cost Savings

Estimated time saved vs manual setup:
- Manual setup: 2-3 days (16-24 hours)
- Automated setup: 4 hours
- **Time saved: 12-20 hours** (75-83% reduction)

## Next Steps for Acme

1. Deploy software packages (Microsoft Office, Chrome, etc.)
2. Create additional policies for security and compliance
3. Roll out to remaining 500 Macs over next month
4. Train IT team on Jamf Pro management
5. Move CIS Level 1 from monitor to enforce mode after 30 days
6. Enable CIS Level 2 for executive devices

---

This example demonstrates how a real company can use these scripts to rapidly deploy enterprise-grade Mac management infrastructure.
