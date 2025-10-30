#!/bin/zsh
# ============================================================================
# Jamf Pro SSO Configuration Module
# ============================================================================
# This module configures Single Sign-On (SSO) for Jamf Pro.
# Supports SAML, Azure AD, Okta, Google, and OneLogin providers.
# ============================================================================

# Source the helper functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/jamf-helpers.sh"

# ----------------------------------------------------------------------------
# SSO Configuration Functions
# ----------------------------------------------------------------------------

# Configure SAML SSO
# Returns:
#   0 - SAML SSO configured successfully
#   1 - SAML SSO configuration failed
configure_saml_sso() {
    log_info "Configuring SAML SSO..."
    
    # Validate required SAML configuration
    if [[ -z "${SAML_ENTITY_ID}" || -z "${SAML_SSO_URL}" ]]; then
        log_error "SAML configuration incomplete. Required: SAML_ENTITY_ID, SAML_SSO_URL"
        return 1
    fi
    
    # Build the JSON payload for SAML SSO configuration
    local payload=$(cat <<EOF
{
  "enabled": true,
  "providerType": "SAML",
  "entityId": "${SAML_ENTITY_ID}",
  "ssoUrl": "${SAML_SSO_URL}",
  "metadataSource": {
    "type": "URL",
    "url": "${SAML_IDP_METADATA_URL}"
  },
  "userAttributeMapping": {
    "email": "email",
    "username": "username",
    "firstName": "firstName",
    "lastName": "lastName"
  },
  "groupAttributeName": "groups",
  "sessionTimeout": 480
}
EOF
)
    
    # Configure SSO via API
    if api_put "/api/v1/sso" "${payload}"; then
        log_success "SAML SSO configured successfully"
        return 0
    else
        log_error "Failed to configure SAML SSO"
        return 1
    fi
}

# Configure Azure AD SSO
# Returns:
#   0 - Azure AD SSO configured successfully
#   1 - Azure AD SSO configuration failed
configure_azure_ad_sso() {
    log_info "Configuring Azure AD SSO..."
    
    # Validate required Azure AD configuration
    if [[ -z "${AZURE_TENANT_ID}" || -z "${AZURE_CLIENT_ID}" || -z "${AZURE_CLIENT_SECRET}" ]]; then
        log_error "Azure AD configuration incomplete. Required: AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET"
        return 1
    fi
    
    # Build the JSON payload for Azure AD SSO configuration
    local payload=$(cat <<EOF
{
  "enabled": true,
  "providerType": "AZURE_AD",
  "tenantId": "${AZURE_TENANT_ID}",
  "clientId": "${AZURE_CLIENT_ID}",
  "clientSecret": "${AZURE_CLIENT_SECRET}",
  "userAttributeMapping": {
    "email": "email",
    "username": "userPrincipalName",
    "firstName": "givenName",
    "lastName": "surname"
  },
  "groupSyncEnabled": true,
  "sessionTimeout": 480
}
EOF
)
    
    # Configure SSO via API
    if api_put "/api/v1/sso" "${payload}"; then
        log_success "Azure AD SSO configured successfully"
        return 0
    else
        log_error "Failed to configure Azure AD SSO"
        return 1
    fi
}

# Configure SSO based on provider type
# Returns:
#   0 - SSO configured successfully
#   1 - SSO configuration failed
configure_sso() {
    case "${SSO_PROVIDER}" in
        "SAML")
            configure_saml_sso
            ;;
        "Azure AD"|"AZURE_AD")
            configure_azure_ad_sso
            ;;
        "Okta"|"Google"|"OneLogin")
            log_warning "SSO provider '${SSO_PROVIDER}' configuration not yet implemented"
            log_info "Please configure manually through the Jamf Pro web interface"
            return 0
            ;;
        *)
            log_error "Unknown SSO provider: ${SSO_PROVIDER}"
            return 1
            ;;
    esac
}

# Enable SSO for Jamf Pro user authentication
# Returns:
#   0 - SSO enabled successfully
#   1 - SSO enabling failed
enable_sso_authentication() {
    log_info "Enabling SSO for user authentication..."
    
    # Get current SSO settings
    local current_settings
    if ! current_settings=$(api_get "/api/v1/sso"); then
        log_error "Failed to retrieve current SSO settings"
        return 1
    fi
    
    # Enable SSO
    local payload=$(cat <<EOF
{
  "enabled": true,
  "ssoForEnrolment": true,
  "ssoBypassAllowed": true
}
EOF
)
    
    if api_put "/api/v1/sso/settings" "${payload}"; then
        log_success "SSO authentication enabled"
        return 0
    else
        log_error "Failed to enable SSO authentication"
        return 1
    fi
}

# Test SSO configuration
# Returns:
#   0 - SSO test successful
#   1 - SSO test failed
test_sso_configuration() {
    log_info "Testing SSO configuration..."
    
    # Attempt to retrieve SSO metadata to verify configuration
    local sso_metadata
    if sso_metadata=$(api_get "/api/v1/sso/metadata"); then
        log_success "SSO configuration test passed"
        return 0
    else
        log_warning "Unable to verify SSO configuration. Manual verification recommended."
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------

setup_sso() {
    print_section_header "Setting Up Single Sign-On (SSO)"
    
    if [[ "${ENABLE_SSO}" != "true" ]]; then
        log_info "SSO disabled in configuration. Skipping..."
        return 0
    fi
    
    # Configure SSO based on provider
    if ! configure_sso; then
        log_error "SSO configuration failed"
        return 1
    fi
    
    # Enable SSO authentication
    if ! enable_sso_authentication; then
        log_error "Failed to enable SSO authentication"
        return 1
    fi
    
    # Test the configuration
    test_sso_configuration
    
    log_success "SSO setup completed"
    log_warning "Please verify SSO configuration manually through the Jamf Pro web interface"
    log_warning "Test SSO login before enforcing it for all users"
    
    return 0
}

# Run the setup if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_sso
fi
