# Migration Guide: v1.0 to v2.0 (macOS 26 Support)

This guide helps you upgrade your existing Jamf Pro tenancy setup from v1.0 to v2.0, which adds comprehensive macOS 26 (Tahoe) support with simplified Platform SSO and enhanced ADE capabilities.

## 📋 What's Changing

### Version 2.0 Adds
- ✅ macOS 26 (Tahoe) as the current supported version
- ✅ Simplified Platform SSO that auto-inherits from SSO settings
- ✅ Declarative Device Management (DDM) by default
- ✅ Rapid Security Response (RSR) integration
- ✅ Managed Activation Lock support
- ✅ New Platform SSO module (`jamf-platform-sso.sh`)

### Backwards Compatibility
- ✅ Fully compatible with macOS 13-15 (legacy mode)
- ✅ Existing configurations continue to work
- ✅ No forced migration required
- ✅ Gradual rollout supported

## 🔄 Migration Paths

Choose the path that matches your situation:

### Path A: Fresh Installation (Recommended)
**Best for**: New Jamf Pro tenancies or those starting fresh

1. Download v2.0 scripts
2. Configure `jamf-config.conf` with macOS 26 settings
3. Run `./jamf-setup.sh`
4. Done!

### Path B: In-Place Upgrade (Existing Deployment)
**Best for**: Existing deployments that want macOS 26 features

Follow the steps below.

### Path C: Parallel Deployment
**Best for**: Testing v2.0 alongside existing v1.0

1. Deploy v2.0 to a separate test/pilot smart group
2. Validate functionality
3. Gradually expand scope
4. Deprecate v1.0 when ready

## 🚀 In-Place Upgrade Steps

### Pre-Migration Checklist

- [ ] Back up current `jamf-config.conf`
- [ ] Document existing smart groups
- [ ] Note current Platform SSO configuration (if any)
- [ ] Verify Jamf Pro version (11.8.0+ recommended)
- [ ] Create test device pool for validation

### Step 1: Back Up Current Configuration

```bash
# Back up your current configuration
cp jamf-config.conf jamf-config.conf.v1.backup

# Document current smart groups
# Navigate to Jamf Pro → Computer Management → Smart Computer Groups
# Export list for reference
```

### Step 2: Download v2.0 Scripts

```bash
# Back up current scripts
mkdir jamf-setup-v1-backup
cp jamf-*.sh jamf-setup-v1-backup/

# Download v2.0 scripts
# Replace existing files with v2.0 versions
```

### Step 3: Update Configuration File

Edit `jamf-config.conf` and update the macOS version section:

```bash
# Old (v1.0)
MACOS_CURRENT_VERSION="15"
MACOS_CURRENT_NAME="Sequoia"
MACOS_PREVIOUS_VERSION_1="14"
MACOS_PREVIOUS_NAME_1="Sonoma"
MACOS_PREVIOUS_VERSION_2="13"
MACOS_PREVIOUS_NAME_2="Ventura"

# New (v2.0)
MACOS_CURRENT_VERSION="26"
MACOS_CURRENT_NAME="Tahoe"
MACOS_PREVIOUS_VERSION_1="15"
MACOS_PREVIOUS_NAME_1="Sequoia"
MACOS_PREVIOUS_VERSION_2="14"
MACOS_PREVIOUS_NAME_2="Sonoma"
```

Add new Platform SSO settings:

```bash
# Add these new lines to the Platform SSO section
PLATFORM_SSO_AUTO_CONFIGURE="true"
PLATFORM_SSO_ACCOUNT_DISPLAY_NAME="${ORGANISATION_NAME}"
PLATFORM_SSO_USE_SHARED_DEVICE_KEYS="false"
PLATFORM_SSO_ENABLE_AUTHORIZATION="true"
PLATFORM_SSO_ENABLE_CREATE_USER_AT_LOGIN="true"
```

Add new ADE settings:

```bash
# Add these new lines to the ADE section
ADE_ENABLE_DDM="true"
ADE_DDM_AUTO_ACTIVATE="true"
ADE_ENABLE_RSR="true"
ADE_MANAGED_ACTIVATION_LOCK="true"
```

### Step 4: Run Smart Groups Update

Update smart groups to include macOS 26:

```bash
# Run only the smart groups module
source jamf-config.conf
source jamf-helpers.sh
./jamf-smart-groups.sh
```

Expected output:
```
[INFO] Creating smart group for macOS 26 (Tahoe)...
[SUCCESS] Smart group 'macOS 26 - Tahoe' created
```

### Step 5: Deploy Platform SSO (If Using SSO)

If you have SSO enabled:

```bash
# Run the new Platform SSO module
./jamf-platform-sso.sh
```

This will:
- Detect your Jamf Pro version
- Create version-specific smart groups
- Deploy simplified Platform SSO for macOS 26+
- Maintain legacy configuration for macOS 13-15

### Step 6: Update PreStage Enrolment (If Using ADE)

If you use ADE, update your PreStage enrolment:

```bash
# Option A: Update via script
./jamf-ade-prestage.sh

# Option B: Update manually in Jamf Pro
# Navigate to: Computers → PreStage Enrollments
# Edit existing PreStage
# Enable: Declarative Device Management
# Enable: Rapid Security Response
# Enable: Managed Activation Lock
```

### Step 7: Validate Configuration

Test with a pilot device:

```bash
# 1. Enrol a test macOS 26 device
# 2. Verify Platform SSO works
# 3. Check DDM is active in Jamf Pro
# 4. Confirm RSR updates deploy
# 5. Test Managed Activation Lock
```

### Step 8: Gradual Rollout

Expand to production:

```bash
# Week 1: IT team devices
# Week 2: Pilot group (10-20 users)
# Week 3: Department rollout
# Week 4: Full deployment
```

## 🔍 Verification Checklist

After migration, verify:

### Smart Groups
- [ ] macOS 26 - Tahoe group exists and populates
- [ ] macOS 15 - Sequoia group still works
- [ ] macOS 14 - Sonoma group still works
- [ ] Outdated macOS group updated with new criteria

### Platform SSO
- [ ] macOS 26+ devices use simplified Platform SSO
- [ ] macOS 13-15 devices use legacy Platform SSO (if applicable)
- [ ] Authentication works on both
- [ ] SSO token refresh functioning

### ADE and PreStage
- [ ] DDM active on new enrolments
- [ ] RSR updates appearing and installing
- [ ] Managed Activation Lock working
- [ ] Existing devices still enrol correctly

### CIS Benchmarks
- [ ] Still reporting correctly
- [ ] No disruption to compliance monitoring
- [ ] All rules still evaluate properly

## ⚠️ Common Issues and Solutions

### Issue: Smart Groups Not Creating

**Problem**: Script fails to create macOS 26 smart groups

**Solution**:
```bash
# Check API permissions
# Verify bearer token is valid
# Run with verbose logging
set -x
./jamf-smart-groups.sh
set +x
```

### Issue: Platform SSO Not Deploying

**Problem**: Platform SSO profile not appearing

**Solution**:
```bash
# Check Jamf Pro version
# Must be 11.8.0+ for simplified mode

# Verify SSO is configured
# Platform SSO requires active SSO

# Check logs
cat /tmp/jamf-setup-*.log | grep -i "platform sso"
```

### Issue: DDM Not Activating

**Problem**: Devices still using legacy MDM

**Solution**:
- Verify device is enrolled via ADE
- Check PreStage has DDM enabled
- Ensure device is macOS 26+
- Re-enrol device if necessary

### Issue: Existing Profiles Conflicting

**Problem**: Old profiles conflicting with new setup

**Solution**:
```bash
# Identify conflicting profiles
# Navigate to: Configuration Profiles
# Search for "Platform SSO" or "Extensible SSO"
# Remove or update conflicting profiles

# Re-deploy correct configuration
./jamf-platform-sso.sh
```

## 🔄 Rollback Procedure

If you need to rollback to v1.0:

### Step 1: Restore Configuration

```bash
# Restore v1.0 configuration
cp jamf-config.conf.v1.backup jamf-config.conf

# Restore v1.0 scripts
cp jamf-setup-v1-backup/*.sh ./
```

### Step 2: Remove v2.0 Additions

```bash
# Remove macOS 26 smart groups (optional)
# Navigate to Jamf Pro and delete manually

# Remove Platform SSO profiles (if desired)
# Navigate to Configuration Profiles and delete
```

### Step 3: Verify Functionality

```bash
# Test that v1.0 functionality restored
./jamf-setup.sh --dry-run
```

## 📊 Migration Timeline

Recommended migration schedule:

| Week | Activity | Audience |
|------|----------|----------|
| 0 | Plan and prepare | IT team |
| 1 | Deploy to IT test devices | IT team (5-10 devices) |
| 2 | Pilot with friendly users | Selected users (20-50 devices) |
| 3 | Department rollout | One department (~100 devices) |
| 4-6 | Gradual expansion | All users |
| 7 | Final review and cleanup | IT team |

## 🎯 Success Metrics

Track these metrics during migration:

### Before Migration (Baseline)
- Platform SSO setup time: ~2-3 hours per configuration
- Average enrolment time: ~30 minutes
- Security update deployment: 7-14 days
- Support tickets: (baseline number)

### After Migration (Target)
- Platform SSO setup time: <15 minutes
- Average enrolment time: <10 minutes
- Security update deployment: <24 hours (RSR)
- Support tickets: -30% (simplified config)

## 📚 Additional Resources

### Documentation
- [macOS 26 Features Guide](MACOS_26_FEATURES.md) - Detailed feature overview
- [README.md](README.md) - Complete documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick setup guide

### Support
- GitHub Issues: [Report migration issues](https://github.com/david-crosby/jamf-tenancy-setup/issues)
- LinkedIn: [David Crosby](https://www.linkedin.com/in/david-bing-crosby/)

### Community
- MacAdmins Slack: #jamf channel
- Jamf Nation: Community forums
- Reddit: r/jamf

## ✅ Post-Migration Tasks

After successful migration:

1. **Update documentation**
   - Note migration date
   - Document any custom changes
   - Update team runbooks

2. **Train IT team**
   - Review new Platform SSO process
   - Explain DDM benefits
   - Cover RSR monitoring

3. **Monitor for issues**
   - Watch for support tickets
   - Review Jamf Pro logs
   - Check device compliance

4. **Optimize configuration**
   - Fine-tune smart group criteria
   - Adjust Platform SSO settings
   - Update security policies

5. **Plan for macOS 27**
   - Review roadmap
   - Prepare for next version
   - Document lessons learned

## 🎉 Migration Complete!

Congratulations! Your Jamf Pro tenancy is now running v2.0 with full macOS 26 support.

Key improvements you now have:
- ✅ Simplified Platform SSO (90% faster setup)
- ✅ DDM for better performance
- ✅ RSR for rapid security updates
- ✅ Managed Activation Lock
- ✅ Ready for future macOS versions

---

**Questions?** Contact David Crosby
- GitHub: [@david-crosby](https://github.com/david-crosby)
- LinkedIn: [david-bing-crosby](https://www.linkedin.com/in/david-bing-crosby/)
