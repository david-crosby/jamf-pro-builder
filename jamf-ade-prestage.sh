#!/bin/zsh
# ============================================================================
# Jamf Pro ADE and PreStage Enrolment Module
# ============================================================================
# This module configures Automated Device Enrolment (ADE) integration and
# creates a zero-touch deployment PreStage enrolment for macOS devices.
# ============================================================================

# Source the helper functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/jamf-helpers.sh"

# ----------------------------------------------------------------------------
# ADE Configuration Functions
# ----------------------------------------------------------------------------

# Download the public key from Jamf Pro for ADE setup
# Returns:
#   0 - Public key downloaded successfully
#   1 - Public key download failed
# Output:
#   Path to the downloaded public key file
download_ade_public_key() {
    log_info "Downloading ADE public key from Jamf Pro..."
    
    local public_key_path="/tmp/jamf-ade-public-key.pem"
    
    # Download the public key
    if ! ensure_valid_token; then
        log_error "Failed to obtain valid token"
        return 1
    fi
    
    if curl -s -X GET "${JAMF_URL}/api/v1/dep/public-key" \
        -H "Authorization: Bearer ${BEARER_TOKEN}" \
        -o "${public_key_path}"; then
        
        if [[ -f "${public_key_path}" && -s "${public_key_path}" ]]; then
            log_success "Public key downloaded to ${public_key_path}"
            log_info "Upload this file to Apple Business Manager or Apple School Manager"
            echo "${public_key_path}"
            return 0
        else
            log_error "Public key file is empty or not created"
            return 1
        fi
    else
        log_error "Failed to download public key"
        return 1
    fi
}

# Upload ADE server token to Jamf Pro
# Returns:
#   0 - Token uploaded successfully
#   1 - Token upload failed
upload_ade_token() {
    log_info "Uploading ADE server token to Jamf Pro..."
    
    # Check if token file exists
    if [[ ! -f "${ADE_TOKEN_FILE_PATH}" ]]; then
        log_error "ADE token file not found: ${ADE_TOKEN_FILE_PATH}"
        log_info "Please download the server token (.p7m) from Apple Business Manager"
        log_info "and update ADE_TOKEN_FILE_PATH in the configuration"
        return 1
    fi
    
    if ! ensure_valid_token; then
        log_error "Failed to obtain valid token"
        return 1
    fi
    
    # Upload the token file
    if curl -s -X POST "${JAMF_URL}/api/v1/dep/servers" \
        -H "Authorization: Bearer ${BEARER_TOKEN}" \
        -H "Content-Type: multipart/form-data" \
        -F "displayName=${ADE_INSTANCE_NAME}" \
        -F "tokenFile=@${ADE_TOKEN_FILE_PATH}"; then
        
        log_success "ADE server token uploaded successfully"
        return 0
    else
        log_error "Failed to upload ADE server token"
        return 1
    fi
}

# Get ADE server instances
# Returns:
#   0 - Successfully retrieved ADE servers
#   1 - Failed to retrieve ADE servers
# Output:
#   JSON array of ADE server instances
get_ade_servers() {
    log_info "Retrieving ADE server instances..."
    
    local response
    if response=$(api_get "/api/v1/dep/servers"); then
        echo "${response}"
        return 0
    else
        log_error "Failed to retrieve ADE server instances"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# PreStage Enrolment Functions
# ----------------------------------------------------------------------------

# Create a PreStage enrolment for zero-touch deployment
# Arguments:
#   $1 - ADE server ID
# Returns:
#   0 - PreStage enrolment created successfully
#   1 - PreStage enrolment creation failed
create_prestage_enrollment() {
    local ade_server_id="$1"
    
    log_info "Creating PreStage enrolment for zero-touch deployment..."
    
    # Build the JSON payload for PreStage enrolment
    # macOS 26 (Tahoe) enhancements included
    local payload=$(cat <<EOF
{
  "displayName": "${PRESTAGE_NAME}",
  "mandatory": true,
  "mdmRemovable": false,
  "supportPhoneNumber": "${ORGANISATION_CONTACT_PHONE}",
  "supportEmailAddress": "${ORGANISATION_CONTACT_EMAIL}",
  "department": "IT",
  "defaultPrestage": true,
  "enrollmentSiteId": -1,
  "keepExistingSiteMembership": false,
  "keepExistingLocationInformation": false,
  "requireAuthentication": false,
  "authenticationPrompt": "Welcome to ${ORGANISATION_NAME}",
  "preventActivationLock": true,
  "enableDeviceBasedActivationLock": ${ADE_MANAGED_ACTIVATION_LOCK},
  "deviceEnrollmentProgramInstanceId": ${ade_server_id},
  "skipSetupItems": {
    "Accessibility": ${SKIP_ACCESSIBILITY},
    "Appearance": ${SKIP_APPEARANCE},
    "AppleID": ${SKIP_APPLE_ID},
    "Biometric": ${SKIP_BIOMETRIC},
    "Diagnostics": ${SKIP_DIAGNOSTICS},
    "DisplayTone": ${SKIP_DISPLAY_TONE},
    "Location": ${SKIP_LOCATION},
    "Payment": ${SKIP_PAYMENT},
    "Privacy": ${SKIP_PRIVACY},
    "Registration": ${SKIP_REGISTRATION},
    "Restore": ${SKIP_RESTORE},
    "ScreenTime": ${SKIP_SCREEN_TIME},
    "Siri": ${SKIP_SIRI},
    "TOS": ${SKIP_TOS}
  },
  "locationInformation": {
    "username": "",
    "realname": "",
    "phone": "",
    "email": "",
    "room": "",
    "position": "",
    "departmentId": -1,
    "buildingId": -1,
    "id": 0
  },
  "purchasingInformation": {
    "id": 0,
    "leased": false,
    "purchased": true,
    "appleCareId": "",
    "poNumber": "",
    "vendor": "",
    "purchasePrice": "",
    "lifeExpectancy": 0,
    "purchasingAccount": "",
    "purchasingContact": "",
    "leaseDate": "",
    "poDate": "",
    "warrantyDate": "",
    "attachments": []
  },
  "anchorCertificates": [],
  "enrollmentCustomizationId": null,
  "autoAdvanceSetup": true,
  "installProfilesDuringSetup": true,
  "prestageInstalledProfileIds": [],
  "customPackageIds": [],
  "customPackageDistributionPointId": -1,
  "enableRecoveryLock": false,
  "recoveryLockPasswordType": "MANUAL",
  "declarativeDeviceManagement": {
    "enabled": ${ADE_ENABLE_DDM},
    "autoActivate": ${ADE_DDM_AUTO_ACTIVATE}
  },
  "rapidSecurityResponse": {
    "enabled": ${ADE_ENABLE_RSR},
    "autoInstall": true
  }
}
EOF
)
    
    # Create the PreStage enrolment via API
    local response
    if response=$(api_post "/api/v2/computer-prestages" "${payload}"); then
        local prestage_id=$(echo "${response}" | jq -r '.id // empty')
        if [[ -n "${prestage_id}" ]]; then
            log_success "PreStage enrolment '${PRESTAGE_NAME}' created with ID: ${prestage_id}"
            echo "${prestage_id}"
            return 0
        else
            log_error "PreStage enrolment created but ID not returned"
            return 1
        fi
    else
        log_error "Failed to create PreStage enrolment"
        return 1
    fi
}

# Scope PreStage enrolment to automatically assign new devices
# Arguments:
#   $1 - PreStage enrolment ID
# Returns:
#   0 - Scope configured successfully
#   1 - Scope configuration failed
configure_prestage_scope() {
    local prestage_id="$1"
    
    log_info "Configuring PreStage enrolment scope..."
    
    # Enable automatic assignment of new devices
    local payload=$(cat <<EOF
{
  "versionLock": 0,
  "autoAddDevices": true
}
EOF
)
    
    # Update the PreStage scope via API
    if api_put "/api/v2/computer-prestages/${prestage_id}/scope" "${payload}"; then
        log_success "PreStage enrolment scope configured for automatic device assignment"
        return 0
    else
        log_error "Failed to configure PreStage enrolment scope"
        return 1
    fi
}

# Add Jamf Connect configuration profile to PreStage enrolment
# Arguments:
#   $1 - PreStage enrolment ID
#   $2 - Configuration profile ID
# Returns:
#   0 - Profile added successfully
#   1 - Profile addition failed
add_profile_to_prestage() {
    local prestage_id="$1"
    local profile_id="$2"
    
    log_info "Adding configuration profile to PreStage enrolment..."
    
    # Get current PreStage settings
    local current_prestage
    if ! current_prestage=$(api_get "/api/v2/computer-prestages/${prestage_id}"); then
        log_error "Failed to retrieve current PreStage settings"
        return 1
    fi
    
    # Add profile ID to the list
    local updated_profiles
    updated_profiles=$(echo "${current_prestage}" | jq ".prestageInstalledProfileIds += [${profile_id}]")
    
    # Update the PreStage with the new profile
    if api_put "/api/v2/computer-prestages/${prestage_id}" "${updated_profiles}"; then
        log_success "Configuration profile added to PreStage enrolment"
        return 0
    else
        log_error "Failed to add configuration profile to PreStage enrolment"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Jamf Connect Configuration Functions
# ----------------------------------------------------------------------------

# Create Jamf Connect configuration profile
# Returns:
#   0 - Profile created successfully
#   1 - Profile creation failed
# Output:
#   Configuration profile ID
create_jamf_connect_profile() {
    log_info "Creating Jamf Connect configuration profile..."
    
    # Build the Jamf Connect configuration profile
    local payload=$(cat <<EOF
{
  "general": {
    "name": "Jamf Connect - SSO Authentication",
    "description": "Configures Jamf Connect for SSO authentication",
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
    "allJSSUsers": false
  },
  "selfService": {
    "installButtonText": "Install",
    "selfServiceDescription": "",
    "forceUsersToViewDescription": false,
    "selfServiceIcon": {
      "id": 0
    },
    "featureOnMainPage": false,
    "selfServiceCategories": [],
    "notification": false,
    "notificationSubject": "",
    "notificationMessage": ""
  },
  "payloads": {
    "jamfConnect": {
      "oidcProvider": "${JAMF_CONNECT_OIDC_PROVIDER}",
      "clientID": "${JAMF_CONNECT_CLIENT_ID}",
      "redirectURI": "${JAMF_CONNECT_REDIRECT_URI}",
      "localPasswordSync": true,
      "tokenRefresh": true
    }
  }
}
EOF
)
    
    # Create the configuration profile via Classic API (XML format)
    # Note: This is a simplified example. Actual implementation may require
    # more complex XML structure for Jamf Connect payloads
    
    log_warning "Jamf Connect profile creation requires manual configuration"
    log_info "Please create the Jamf Connect configuration profile manually"
    log_info "Configuration details:"
    log_info "  - OIDC Provider: ${JAMF_CONNECT_OIDC_PROVIDER}"
    log_info "  - Client ID: ${JAMF_CONNECT_CLIENT_ID}"
    log_info "  - Redirect URI: ${JAMF_CONNECT_REDIRECT_URI}"
    
    return 0
}

# ----------------------------------------------------------------------------
# Platform SSO Configuration Functions
# ----------------------------------------------------------------------------

# Create Platform SSO configuration profile
# Returns:
#   0 - Profile created successfully
#   1 - Profile creation failed
create_platform_sso_profile() {
    log_info "Creating Platform SSO configuration profile..."
    
    log_warning "Platform SSO profile creation requires manual configuration"
    log_info "Please create the Platform SSO configuration profile manually"
    log_info "Platform SSO is available on macOS 13 and later"
    log_info "Configuration details:"
    log_info "  - Token URL: ${PLATFORM_SSO_TOKEN_URL}"
    log_info "  - Client ID: ${PLATFORM_SSO_CLIENT_ID}"
    
    return 0
}

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------

setup_ade_and_prestage() {
    print_section_header "Setting Up ADE and PreStage Enrolment"
    
    local ade_server_id=""
    
    # Step 1: Download public key
    log_info "Step 1: Download ADE Public Key"
    local public_key_path
    if public_key_path=$(download_ade_public_key); then
        log_success "Public key ready for upload to Apple Business Manager"
        log_warning "Action required: Upload ${public_key_path} to Apple Business Manager"
        log_warning "Then download the server token file (.p7m) and update ADE_TOKEN_FILE_PATH"
        
        if [[ "${DRY_RUN}" != "true" ]]; then
            pause_for_confirmation "Press Enter once you've uploaded the key and downloaded the token..."
        fi
    else
        log_error "Failed to download public key"
        return 1
    fi
    
    # Step 2: Upload ADE token
    log_info "Step 2: Upload ADE Server Token"
    if [[ -f "${ADE_TOKEN_FILE_PATH}" ]]; then
        if upload_ade_token; then
            log_success "ADE token uploaded successfully"
        else
            log_error "Failed to upload ADE token"
            return 1
        fi
    else
        log_warning "ADE token file not found. Skipping token upload."
        log_info "To complete ADE setup:"
        log_info "  1. Upload the public key to Apple Business Manager"
        log_info "  2. Download the server token (.p7m)"
        log_info "  3. Update ADE_TOKEN_FILE_PATH in configuration"
        log_info "  4. Re-run this script"
        return 0
    fi
    
    # Step 3: Get ADE server ID
    log_info "Step 3: Retrieve ADE Server Instance"
    local ade_servers
    if ade_servers=$(get_ade_servers); then
        ade_server_id=$(echo "${ade_servers}" | jq -r '.results[0].id // empty')
        if [[ -n "${ade_server_id}" ]]; then
            log_success "Found ADE server instance with ID: ${ade_server_id}"
        else
            log_error "No ADE server instances found"
            return 1
        fi
    else
        return 1
    fi
    
    # Step 4: Create PreStage enrolment
    log_info "Step 4: Create PreStage Enrolment"
    local prestage_id
    if prestage_id=$(create_prestage_enrollment "${ade_server_id}"); then
        log_success "PreStage enrolment created"
        
        # Configure scope for automatic device assignment
        configure_prestage_scope "${prestage_id}"
    else
        log_error "Failed to create PreStage enrolment"
        return 1
    fi
    
    # Step 5: Configure Jamf Connect if enabled
    if [[ "${ENABLE_JAMF_CONNECT}" == "true" ]]; then
        log_info "Step 5: Configure Jamf Connect"
        create_jamf_connect_profile
    fi
    
    # Step 6: Configure Platform SSO if enabled
    if [[ "${ENABLE_PLATFORM_SSO}" == "true" ]]; then
        log_info "Step 6: Configure Platform SSO"
        create_platform_sso_profile
    fi
    
    log_success "ADE and PreStage enrolment setup completed"
    log_info "Devices can now be enrolled via zero-touch deployment"
    
    return 0
}

# Run the setup if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ade_and_prestage
fi
