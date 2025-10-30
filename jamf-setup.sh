#!/bin/zsh
# ============================================================================
# Jamf Pro Tenancy Setup - Main Orchestration Script
# ============================================================================
# This script orchestrates the complete setup of a Jamf Pro tenancy from
# scratch, including API authentication, SSO, mail server, ADE, PreStage
# enrolment, smart groups, CIS benchmarks, and user accounts.
#
# Author: David Crosby (Bing)
# GitHub: https://github.com/david-crosby
# ============================================================================

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="${0:A:h}"

# Load configuration
CONFIG_FILE="${SCRIPT_DIR}/jamf-config.conf"
if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    echo "Please create the configuration file before running this script."
    exit 1
fi

# Source configuration and helper functions
source "${CONFIG_FILE}"
source "${SCRIPT_DIR}/jamf-helpers.sh"

# ----------------------------------------------------------------------------
# Pre-flight Checks
# ----------------------------------------------------------------------------

# Perform pre-flight checks before starting setup
# Returns:
#   0 - All checks passed
#   1 - One or more checks failed
preflight_checks() {
    print_section_header "Pre-flight Checks"
    
    log_info "Running pre-flight checks..."
    
    # Verify required commands are available
    if ! verify_requirements; then
        return 1
    fi
    
    # Validate configuration
    if ! validate_config; then
        return 1
    fi
    
    # Test API connectivity
    log_info "Testing API connectivity..."
    if ! get_bearer_token; then
        log_error "Failed to authenticate with Jamf Pro API"
        log_error "Please verify:"
        log_error "  - JAMF_URL is correct and accessible"
        log_error "  - JAMF_CLIENT_ID and JAMF_CLIENT_SECRET are valid"
        log_error "  - API client has necessary permissions"
        return 1
    fi
    
    log_success "Pre-flight checks completed successfully"
    return 0
}

# ----------------------------------------------------------------------------
# Setup Orchestration
# ----------------------------------------------------------------------------

# Display welcome message and setup overview
display_welcome() {
    clear
    echo "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║               Jamf Pro Tenancy Setup Automation Script                  ║
║                                                                          ║
║  This script will configure your Jamf Pro instance with:                ║
║    • Smart Groups for macOS version management                          ║
║    • CIS Level 1 and Level 2 compliance benchmarks                      ║
║    • Single Sign-On (SSO) integration                                   ║
║    • Mail server for notifications                                      ║
║    • Automated Device Enrolment (ADE) integration                       ║
║    • Zero-touch deployment PreStage enrolment                           ║
║    • User accounts with appropriate permissions                         ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
EOF
    echo "${NC}"
    echo ""
    
    log_info "Configuration file: ${CONFIG_FILE}"
    log_info "Jamf Pro URL: ${JAMF_URL}"
    log_info "Log file: ${LOG_FILE}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "DRY RUN MODE: No changes will be made to Jamf Pro"
    fi
    
    echo ""
    pause_for_confirmation "Press Enter to begin setup..."
}

# Main setup orchestration function
# Returns:
#   0 - Setup completed successfully
#   1 - Setup failed
run_setup() {
    local start_time=$(date +%s)
    
    # Initialise log file
    echo "Jamf Pro Tenancy Setup Log" > "${LOG_FILE}"
    echo "Started: $(date)" >> "${LOG_FILE}"
    echo "======================================" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"
    
    # Display welcome message
    display_welcome
    
    # Run pre-flight checks
    if ! preflight_checks; then
        log_error "Pre-flight checks failed. Aborting setup."
        return 1
    fi
    
    # Track success status
    local setup_success=true
    local completed_modules=()
    local failed_modules=()
    
    # Module 1: Smart Groups
    log_info "Starting Module 1: Smart Groups"
    if source "${SCRIPT_DIR}/jamf-smart-groups.sh" && setup_smart_groups; then
        completed_modules+=("Smart Groups")
    else
        failed_modules+=("Smart Groups")
        setup_success=false
    fi
    
    # Module 2: CIS Benchmarks
    log_info "Starting Module 2: CIS Benchmarks"
    if source "${SCRIPT_DIR}/jamf-cis-benchmarks.sh" && setup_cis_benchmarks; then
        completed_modules+=("CIS Benchmarks")
    else
        failed_modules+=("CIS Benchmarks")
        log_warning "CIS Benchmarks setup failed, but continuing..."
    fi
    
    # Module 3: Single Sign-On
    log_info "Starting Module 3: Single Sign-On"
    if source "${SCRIPT_DIR}/jamf-sso.sh" && setup_sso; then
        completed_modules+=("SSO")
    else
        failed_modules+=("SSO")
        log_warning "SSO setup failed, but continuing..."
    fi
    
    # Module 4: Mail Server
    log_info "Starting Module 4: Mail Server"
    if source "${SCRIPT_DIR}/jamf-mail-server.sh" && setup_mail_server; then
        completed_modules+=("Mail Server")
    else
        failed_modules+=("Mail Server")
        log_warning "Mail server setup failed, but continuing..."
    fi
    
    # Module 5: ADE and PreStage Enrolment
    log_info "Starting Module 5: ADE and PreStage Enrolment"
    if source "${SCRIPT_DIR}/jamf-ade-prestage.sh" && setup_ade_and_prestage; then
        completed_modules+=("ADE and PreStage")
    else
        failed_modules+=("ADE and PreStage")
        log_warning "ADE and PreStage setup failed, but continuing..."
    fi
    
    # Module 6: User Accounts
    log_info "Starting Module 6: User Accounts"
    if source "${SCRIPT_DIR}/jamf-users.sh" && setup_users; then
        completed_modules+=("User Accounts")
    else
        failed_modules+=("User Accounts")
        log_warning "User account setup failed, but continuing..."
    fi
    
    # Clean up: Invalidate the bearer token
    invalidate_token
    
    # Display setup summary
    print_section_header "Setup Summary"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    log_info "Setup completed in ${minutes}m ${seconds}s"
    echo ""
    
    if [[ ${#completed_modules[@]} -gt 0 ]]; then
        log_success "Successfully completed modules:"
        for module in "${completed_modules[@]}"; do
            echo "  ${GREEN}✓${NC} ${module}"
        done
        echo ""
    fi
    
    if [[ ${#failed_modules[@]} -gt 0 ]]; then
        log_warning "Modules with issues:"
        for module in "${failed_modules[@]}"; do
            echo "  ${YELLOW}⚠${NC} ${module}"
        done
        echo ""
    fi
    
    # Display next steps
    print_section_header "Next Steps"
    echo ""
    log_info "1. Review the log file: ${LOG_FILE}"
    
    if [[ -f /tmp/jamf-credentials.txt ]]; then
        log_info "2. Review and securely store user credentials: /tmp/jamf-credentials.txt"
        log_warning "   DELETE this file after storing credentials securely!"
    fi
    
    log_info "3. Verify SSO configuration through the Jamf Pro web interface"
    log_info "4. Test mail server by sending test notifications"
    log_info "5. Complete ADE setup in Apple Business Manager (if not done)"
    log_info "6. Test zero-touch deployment with a test device"
    log_info "7. Review CIS benchmark compliance reports"
    log_info "8. Configure Jamf Connect or Platform SSO profiles if enabled"
    echo ""
    
    if [[ "${setup_success}" == "true" && ${#failed_modules[@]} -eq 0 ]]; then
        log_success "Jamf Pro tenancy setup completed successfully! 🎉"
        return 0
    else
        log_warning "Jamf Pro tenancy setup completed with some warnings"
        log_info "Review failed modules and complete them manually if needed"
        return 0
    fi
}

# ----------------------------------------------------------------------------
# Error Handling
# ----------------------------------------------------------------------------

# Handle script errors
error_handler() {
    local line_number=$1
    log_error "An error occurred on line ${line_number}"
    log_error "Setup aborted. Please review the log file: ${LOG_FILE}"
    
    # Clean up
    invalidate_token 2>/dev/null || true
    
    exit 1
}

# Set up error trap
trap 'error_handler ${LINENO}' ERR

# ----------------------------------------------------------------------------
# Main Entry Point
# ----------------------------------------------------------------------------

# Display usage information
usage() {
    cat << EOF
Usage: ${0:t} [OPTIONS]

Automate the setup of a Jamf Pro tenancy from scratch.

OPTIONS:
    -h, --help          Display this help message
    -c, --config FILE   Use alternate configuration file
    -d, --dry-run       Run in dry-run mode (no changes made)
    -v, --version       Display script version

EXAMPLES:
    ${0:t}                      Run with default config
    ${0:t} --config custom.conf  Run with custom config
    ${0:t} --dry-run            Test without making changes

CONFIGURATION:
    Before running this script, edit jamf-config.conf with your
    Jamf Pro instance details and preferences.

FOR MORE INFORMATION:
    GitHub: https://github.com/david-crosby
    LinkedIn: https://www.linkedin.com/in/david-bing-crosby/

EOF
}

# Parse command-line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -v|--version)
                echo "Jamf Pro Tenancy Setup Script v1.0.0"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    parse_arguments "$@"
    
    # Run the setup
    run_setup
    
    exit $?
}

# Execute main function with all arguments
main "$@"
