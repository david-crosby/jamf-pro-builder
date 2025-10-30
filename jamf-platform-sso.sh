#!/bin/zsh
# ============================================================================
# Jamf Pro Platform SSO Configuration Module (macOS 26 Enhanced)
# ============================================================================
# This module configures Platform SSO for macOS devices.
# macOS 26 (Tahoe) introduces simplified Platform SSO that automatically
# integrates with Jamf Pro's SSO settings, eliminating the need for complex
# configuration profiles.
# ============================================================================

# Source the helper functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/jamf-helpers.sh"

# ----------------------------------------------------------------------------
# Platform SSO Detection Functions
# ----------------------------------------------------------------------------

# Detect if Platform SSO simplified mode is available
# Returns:
#   0 - Simplified mode available (Jamf Pro supports it)
#   1 - Legacy mode required
check_platform_sso_capability() {
    log_info "Checking Platform SSO capabilities..."
    
    # Check Jamf Pro version for Platform SSO support
    local version_info
    if version_info=$(api_get "/api/v1/jamf-pro-version"); then
        local version=$(echo "${version_info}" | jq -r '.version // empty')
        
        # Platform SSO simplified API available in Jamf Pro 11.8.0+
        if [[ -n "${version}" ]]; then
            local major=$(echo "${version}" | cut -d'.' -f1)
            local minor=$(echo "${version}" | cut -d'.' -f2)
            
            if [[ ${major} -gt 11 ]] || [[ ${major} -eq 11 && ${minor} -ge 8 ]]; then
                log_success "Platform SSO simplified mode available (Jamf Pro ${version})"
                return 0
            fi
        fi
    fi
    
    log_warning "Platform SSO simplified mode not available, using legacy configuration"
    return 1
}

# ----------------------------------------------------------------------------
# Platform SSO Configuration Functions (macOS 26+)
# ----------------------------------------------------------------------------

# Create simplified Platform SSO configuration for macOS 26+
# This leverages the new unified SSO approach in macOS 26
# Returns:
#   0 - Configuration created successfully
#   1 - Configuration failed
create_simplified_platform_sso() {
    log_info "Creating simplified Platform SSO configuration for macOS 26+..."
    
    # Validate that SSO is configured first
    local sso_config
    if ! sso_config=$(api_get "/api/v1/sso"); then
        log_error "SSO must be configured before enabling Platform SSO"
        log_info "Please run the SSO module first: ./jamf-sso.sh"
        return 1
    fi
    
    # Check if SSO is enabled
    local sso_enabled=$(echo "${sso_config}" | jq -r '.enabled // false')
    if [[ "${sso_enabled}" != "true" ]]; then
        log_error "SSO is not enabled. Platform SSO requires active SSO configuration."
        return 1
    fi
    
    log_success "SSO is configured and enabled"
    
    # Build simplified Platform SSO payload
    # In macOS 26, Platform SSO automatically uses the org's SSO configuration
    local payload=$(cat <<EOF
{
  "general": {
    "name": "Platform SSO - ${ORGANISATION_NAME}",
    "description": "Simplified Platform SSO configuration for macOS 26 (Tahoe) and later",
    "level": "Computer Level",
    "category": {
      "id": -1
    },
    "distribution": "Install Automatically",
    "userRemovable": false,
    "redeploy": "Newly Assigned"
  },
  "scope": {
    "allComputers": false,
    "computers": [],
    "computerGroups": [],
    "buildings": [],
    "departments": [],
    "limitations": {
      "networkSegments": [],
      "iBeacons": []
    },
    "exclusions": {
      "computers": [],
      "computerGroups": [],
      "buildings": [],
      "departments": [],
      "networkSegments": [],
      "iBeacons": []
    }
  },
  "platformSSO": {
    "enabled": true,
    "autoConfiguration": true,
    "extensionIdentifier": "${PLATFORM_SSO_EXTENSION_IDENTIFIER}",
    "accountDisplayName": "${PLATFORM_SSO_ACCOUNT_DISPLAY_NAME}",
    "useSharedDeviceKeys": ${PLATFORM_SSO_USE_SHARED_DEVICE_KEYS},
    "enableAuthorization": ${PLATFORM_SSO_ENABLE_AUTHORIZATION},
    "enableCreateUserAtLogin": ${PLATFORM_SSO_ENABLE_CREATE_USER_AT_LOGIN},
    "osVersionRequirement": "26.0"
  }
}
EOF
)
    
    # Create the configuration profile
    local response
    if response=$(api_post "/api/v2/configuration-profiles/platform-sso" "${payload}"); then
        local profile_id=$(echo "${response}" | jq -r '.id // empty')
        if [[ -n "${profile_id}" ]]; then
            log_success "Platform SSO configuration profile created with ID: ${profile_id}"
            echo "${profile_id}"
            return 0
        else
            log_error "Profile created but ID not returned"
            return 1
        fi
    else
        log_error "Failed to create Platform SSO configuration profile"
        return 1
    fi
}

# Create legacy Platform SSO configuration for macOS 13-15
# Returns:
#   0 - Configuration created successfully
#   1 - Configuration failed
create_legacy_platform_sso() {
    log_info "Creating legacy Platform SSO configuration for macOS 13-15..."
    
    # Validate required legacy configuration
    if [[ -z "${PLATFORM_SSO_TOKEN_URL}" || -z "${PLATFORM_SSO_CLIENT_ID}" ]]; then
        log_error "Legacy Platform SSO requires PLATFORM_SSO_TOKEN_URL and PLATFORM_SSO_CLIENT_ID"
        log_info "Please configure these values in jamf-config.conf"
        return 1
    fi
    
    log_warning "Legacy Platform SSO requires manual configuration profile creation"
    log_info "Please create a configuration profile with the following settings:"
    log_info "  - Extension Identifier: ${PLATFORM_SSO_EXTENSION_IDENTIFIER}"
    log_info "  - Token URL: ${PLATFORM_SSO_TOKEN_URL}"
    log_info "  - Client ID: ${PLATFORM_SSO_CLIENT_ID}"
    log_info "  - Screen Lock Extension: Enabled"
    log_info "  - New User Authorization Mode: Standard"
    
    return 0
}

# ----------------------------------------------------------------------------
# Smart Group Functions
# ----------------------------------------------------------------------------

# Create smart group for macOS 26+ devices (Platform SSO capable)
# Returns:
#   0 - Smart group created successfully
#   1 - Smart group creation failed
# Output:
#   Smart group ID
create_macos26_smart_group() {
    log_info "Creating smart group for macOS 26+ devices..."
    
    local group_name="macOS 26+ (Platform SSO Capable)"
    
    # Build the JSON payload
    local payload=$(cat <<EOF
{
  "name": "${group_name}",
  "criteria": [
    {
      "name": "Operating System Version",
      "priority": 0,
      "andOr": "and",
      "searchType": "greater than or equal",
      "value": "26.0",
      "openingParen": false,
      "closingParen": false
    }
  ]
}
EOF
)
    
    # Create the smart group via API
    local response
    if response=$(api_post "/api/v1/computer-groups" "${payload}"); then
        local group_id=$(echo "${response}" | jq -r '.id // empty')
        if [[ -n "${group_id}" ]]; then
            log_success "Smart group '${group_name}' created with ID: ${group_id}"
            echo "${group_id}"
            return 0
        else
            log_error "Smart group created but ID not returned"
            return 1
        fi
    else
        log_error "Failed to create smart group '${group_name}'"
        return 1
    fi
}

# Create smart group for macOS 13-15 devices (legacy Platform SSO)
# Returns:
#   0 - Smart group created successfully
#   1 - Smart group creation failed
# Output:
#   Smart group ID
create_legacy_platform_sso_smart_group() {
    log_info "Creating smart group for macOS 13-15 devices..."
    
    local group_name="macOS 13-15 (Legacy Platform SSO)"
    
    # Build the JSON payload
    local payload=$(cat <<EOF
{
  "name": "${group_name}",
  "criteria": [
    {
      "name": "Operating System Version",
      "priority": 0,
      "andOr": "and",
      "searchType": "greater than or equal",
      "value": "13.0",
      "openingParen": false,
      "closingParen": false
    },
    {
      "name": "Operating System Version",
      "priority": 1,
      "andOr": "and",
      "searchType": "less than",
      "value": "26.0",
      "openingParen": false,
      "closingParen": false
    }
  ]
}
EOF
)
    
    # Create the smart group via API
    local response
    if response=$(api_post "/api/v1/computer-groups" "${payload}"); then
        local group_id=$(echo "${response}" | jq -r '.id // empty')
        if [[ -n "${group_id}" ]]; then
            log_success "Smart group '${group_name}' created with ID: ${group_id}"
            echo "${group_id}"
            return 0
        else
            log_error "Smart group created but ID not returned"
            return 1
        fi
    else
        log_error "Failed to create smart group '${group_name}'"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Scope Management Functions
# ----------------------------------------------------------------------------

# Scope Platform SSO profile to appropriate smart group
# Arguments:
#   $1 - Profile ID
#   $2 - Smart group ID
# Returns:
#   0 - Scope updated successfully
#   1 - Scope update failed
scope_platform_sso_profile() {
    local profile_id="$1"
    local group_id="$2"
    
    log_info "Scoping Platform SSO profile to smart group..."
    
    # Build scope payload
    local payload=$(cat <<EOF
{
  "computerGroups": [${group_id}],
  "allComputers": false
}
EOF
)
    
    # Update profile scope
    if api_put "/api/v2/configuration-profiles/${profile_id}/scope" "${payload}"; then
        log_success "Platform SSO profile scoped to smart group ID: ${group_id}"
        return 0
    else
        log_error "Failed to scope Platform SSO profile"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------

setup_platform_sso() {
    print_section_header "Setting Up Platform SSO (macOS 26 Enhanced)"
    
    if [[ "${ENABLE_PLATFORM_SSO}" != "true" ]]; then
        log_info "Platform SSO disabled in configuration. Skipping..."
        return 0
    fi
    
    # Check if automatic configuration is enabled
    if [[ "${PLATFORM_SSO_AUTO_CONFIGURE}" != "true" ]]; then
        log_info "Platform SSO auto-configuration disabled"
        log_info "Manual configuration required - see documentation"
        return 0
    fi
    
    # Check Platform SSO capability
    local use_simplified=false
    if check_platform_sso_capability; then
        use_simplified=true
    fi
    
    local profile_id=""
    local group_id=""
    
    if [[ "${use_simplified}" == "true" ]]; then
        log_info "Using simplified Platform SSO configuration (macOS 26+)"
        
        # Create smart group for macOS 26+ devices
        if ! group_id=$(create_macos26_smart_group); then
            log_error "Failed to create macOS 26+ smart group"
            return 1
        fi
        
        # Create simplified Platform SSO configuration
        if ! profile_id=$(create_simplified_platform_sso); then
            log_error "Failed to create simplified Platform SSO configuration"
            return 1
        fi
        
        # Scope to macOS 26+ devices
        if ! scope_platform_sso_profile "${profile_id}" "${group_id}"; then
            log_warning "Platform SSO profile created but scoping failed"
        fi
        
        log_success "Simplified Platform SSO configuration complete"
        log_info "Profile automatically inherits SSO settings from Jamf Pro"
        log_info "Devices running macOS 26+ will use Platform SSO on next check-in"
        
    else
        log_info "Using legacy Platform SSO configuration (macOS 13-15)"
        
        # Create smart group for legacy devices
        if ! group_id=$(create_legacy_platform_sso_smart_group); then
            log_warning "Failed to create legacy Platform SSO smart group"
        fi
        
        # Provide legacy configuration guidance
        create_legacy_platform_sso
        
        log_warning "Legacy Platform SSO requires manual configuration profile creation"
        log_info "Scope the profile to smart group ID: ${group_id}"
    fi
    
    log_success "Platform SSO setup completed"
    
    return 0
}

# Run the setup if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_platform_sso
fi
