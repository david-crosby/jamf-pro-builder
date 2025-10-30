# Quick Start Guide

This guide will help you get your Jamf Pro tenancy setup automation running in under 15 minutes.

## Prerequisites Checklist

Before starting, ensure you have:
- [ ] Access to a Jamf Pro instance (10.49.0 or later)
- [ ] Administrator rights in Jamf Pro
- [ ] `jq` installed (`brew install jq`)
- [ ] Access to Apple Business Manager (for ADE)
- [ ] SSO provider details (if using SSO)
- [ ] SMTP server details (if using email notifications)

## Step-by-Step Setup

### 1. Create API Client in Jamf Pro (5 minutes)

1. Log into Jamf Pro: `https://yourcompany.jamfcloud.com`
2. Navigate to: **Settings → System → API Roles and Clients**
3. **Create API Role**:
   - Click **"+ New"** under API Roles
   - Name: "Tenancy Setup - Full Access"
   - Select **all privileges** or at minimum:
     - Computer Groups (Create, Read, Update)
     - Configuration Profiles (Create, Read, Update)
     - Policies (Create, Read, Update)
     - PreStage Enrolments (Create, Read, Update)
     - User Accounts (Create, Read, Update)
     - SSO Settings (Read, Update)
     - SMTP Server Settings (Read, Update)
     - Automated Device Enrolment (Read, Update)
   - Click **Save**
4. **Create API Client**:
   - Click **"+ New"** under API Clients
   - Name: "Tenancy Setup Automation"
   - Select the role created above
   - Click **Save**
   - **IMPORTANT**: Copy the Client ID and Client Secret immediately!

### 2. Download and Configure Scripts (5 minutes)

1. Download all scripts to a directory:
   ```bash
   mkdir ~/jamf-setup
   cd ~/jamf-setup
   # Copy all .sh files and jamf-config.conf here
   ```

2. Make scripts executable:
   ```bash
   chmod +x jamf-*.sh
   ```

3. Edit the configuration file:
   ```bash
   nano jamf-config.conf
   ```

4. **Minimum Required Configuration**:
   ```bash
   # Jamf Pro Instance
   JAMF_URL="https://yourcompany.jamfcloud.com"
   JAMF_CLIENT_ID="paste-your-client-id-here"
   JAMF_CLIENT_SECRET="paste-your-client-secret-here"
   
   # Organisation
   ORGANISATION_NAME="Your Company Name"
   ORGANISATION_CONTACT_EMAIL="[email protected]"
   ```

5. **Optional but Recommended**:
   ```bash
   # macOS Versions (update as needed)
   MACOS_CURRENT_VERSION="15"
   MACOS_CURRENT_NAME="Sequoia"
   
   # CIS Benchmarks
   ENABLE_CIS_LEVEL_1="true"
   CIS_LEVEL_1_MODE="monitor"  # Start with monitor mode
   ```

### 3. Test Configuration (2 minutes)

Run a dry-run to test without making changes:
```bash
./jamf-setup.sh --dry-run
```

Expected output:
- ✓ Pre-flight checks pass
- ✓ API authentication succeeds
- ✓ All modules are found

If you see errors, fix them before proceeding.

### 4. Run the Setup (3-10 minutes)

Execute the full setup:
```bash
./jamf-setup.sh
```

The script will:
1. Create smart groups for macOS versions
2. Enable CIS benchmarks (if configured)
3. Configure SSO (if configured)
4. Set up mail server (if configured)
5. Prepare ADE integration
6. Create PreStage enrolment
7. Create user accounts

### 5. Post-Setup Tasks

1. **Review the log**:
   ```bash
   cat /tmp/jamf-setup-*.log
   ```

2. **Store credentials securely**:
   ```bash
   cat /tmp/jamf-credentials.txt
   # Store these passwords in your password manager
   rm /tmp/jamf-credentials.txt
   ```

3. **Complete ADE setup** (if not done):
   - The script downloaded a public key to `/tmp/jamf-ade-public-key.pem`
   - Upload this to Apple Business Manager
   - Download the server token (.p7m)
   - Update `ADE_TOKEN_FILE_PATH` in config
   - Re-run: `./jamf-ade-prestage.sh`

4. **Verify SSO** (if configured):
   - Test login through Jamf Pro
   - Verify user attributes are mapping correctly

5. **Test mail server** (if configured):
   - Send a test notification
   - Check email receipt

## Common First-Time Issues

### Issue: "jq: command not found"
**Fix**: Install jq
```bash
brew install jq
```

### Issue: "Failed to obtain bearer token"
**Fix**: Verify credentials in config file
- Check JAMF_URL is correct (include https://)
- Verify Client ID and Secret are correct
- Ensure API client exists in Jamf Pro

### Issue: "Permission denied" errors
**Fix**: Ensure API client has all required permissions
- Review API role in Jamf Pro
- Grant missing permissions
- Try again

### Issue: Some modules fail
**Solution**: This is normal for initial setup
- Review which modules failed
- Check configuration for those specific modules
- Run individual modules to fix issues:
  ```bash
  ./jamf-smart-groups.sh
  ./jamf-sso.sh
  # etc.
  ```

## What's Next?

After successful setup:

1. **Enrol a Test Device**:
   - Add a device to Apple Business Manager
   - Assign to your Jamf Pro MDM server
   - Power on and test zero-touch enrolment

2. **Configure Jamf Connect** (if using):
   - Create configuration profile manually
   - Add to PreStage enrolment
   - Test authentication

3. **Review CIS Compliance**:
   - Check compliance reports
   - Adjust settings as needed
   - Move from monitor to enforce mode when ready

4. **Create Additional Policies**:
   - Software deployment
   - Configuration management
   - Security policies

5. **Set Up Monitoring**:
   - Configure notifications
   - Set up reporting schedules
   - Create dashboards

## Getting Help

If you need assistance:
1. Check the main README.md for detailed documentation
2. Review log files for specific errors
3. Test individual modules to isolate issues
4. Refer to [Jamf Pro API documentation](https://developer.jamf.com/jamf-pro/docs)

## Feedback

Found a bug? Have a suggestion? 
- GitHub: https://github.com/david-crosby
- LinkedIn: https://www.linkedin.com/in/david-bing-crosby/

---

**Congratulations!** You've completed the quick start. Your Jamf Pro tenancy is now set up with modern, enterprise-grade configuration! 🎉
