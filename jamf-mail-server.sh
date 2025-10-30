#!/bin/zsh
# ============================================================================
# Jamf Pro Mail Server Configuration Module
# ============================================================================
# This module configures the SMTP mail server settings for Jamf Pro
# to enable email notifications and reports.
# ============================================================================

# Source the helper functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/jamf-helpers.sh"

# ----------------------------------------------------------------------------
# Mail Server Configuration Functions
# ----------------------------------------------------------------------------

# Configure SMTP mail server settings
# Returns:
#   0 - Mail server configured successfully
#   1 - Mail server configuration failed
configure_mail_server() {
    log_info "Configuring mail server settings..."
    
    # Validate required mail server configuration
    if [[ -z "${MAIL_SERVER_ADDRESS}" || -z "${MAIL_SENDER_EMAIL}" ]]; then
        log_error "Mail server configuration incomplete. Required: MAIL_SERVER_ADDRESS, MAIL_SENDER_EMAIL"
        return 1
    fi
    
    # Build the JSON payload for mail server configuration
    local payload=$(cat <<EOF
{
  "enabled": true,
  "host": "${MAIL_SERVER_ADDRESS}",
  "port": ${MAIL_SERVER_PORT},
  "timeout": 30,
  "fromEmail": "${MAIL_SENDER_EMAIL}",
  "fromName": "${ORGANISATION_NAME}",
  "requireAuthentication": true,
  "username": "${MAIL_USERNAME}",
  "password": "${MAIL_PASSWORD}",
  "useTls": ${MAIL_USE_TLS}
}
EOF
)
    
    # Configure mail server via API
    if api_put "/api/v2/smtp-server" "${payload}"; then
        log_success "Mail server configured successfully"
        return 0
    else
        log_error "Failed to configure mail server"
        return 1
    fi
}

# Test mail server configuration by sending a test email
# Returns:
#   0 - Test email sent successfully
#   1 - Test email failed
test_mail_server() {
    log_info "Testing mail server configuration..."
    
    # Build the JSON payload for test email
    local payload=$(cat <<EOF
{
  "recipient": "${ORGANISATION_CONTACT_EMAIL}",
  "subject": "Jamf Pro Mail Server Test",
  "body": "This is a test email from your Jamf Pro instance to verify mail server configuration."
}
EOF
)
    
    # Send test email via API
    if api_post "/api/v2/smtp-server/test" "${payload}"; then
        log_success "Test email sent successfully to ${ORGANISATION_CONTACT_EMAIL}"
        log_info "Please check the recipient's inbox to verify email receipt"
        return 0
    else
        log_warning "Test email may have failed. Please verify mail server settings."
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------

setup_mail_server() {
    print_section_header "Setting Up Mail Server"
    
    # Check if mail server address is configured
    if [[ -z "${MAIL_SERVER_ADDRESS}" ]]; then
        log_info "Mail server not configured. Skipping..."
        return 0
    fi
    
    # Configure the mail server
    if ! configure_mail_server; then
        log_error "Mail server configuration failed"
        return 1
    fi
    
    # Test the mail server configuration
    if [[ -n "${ORGANISATION_CONTACT_EMAIL}" ]]; then
        test_mail_server
    else
        log_warning "No contact email specified. Skipping mail server test."
        log_info "Set ORGANISATION_CONTACT_EMAIL to enable mail server testing"
    fi
    
    log_success "Mail server setup completed"
    
    return 0
}

# Run the setup if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_mail_server
fi
