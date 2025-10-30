#!/bin/zsh
# ============================================================================
# Jamf Pro User Management Module
# ============================================================================
# This module creates and manages user accounts in Jamf Pro with appropriate
# privilege sets and access levels.
# ============================================================================

# Source the helper functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/jamf-helpers.sh"

# ----------------------------------------------------------------------------
# User Management Functions
# ----------------------------------------------------------------------------

# Get privilege set ID by name
# Arguments:
#   $1 - Privilege set name
# Returns:
#   0 - Privilege set found
#   1 - Privilege set not found
# Output:
#   Privilege set ID
get_privilege_set_id() {
    local privilege_name="$1"
    
    log_info "Looking up privilege set: ${privilege_name}..."
    
    local response
    if response=$(api_get "/api/v1/accounts/privilege-sets"); then
        local privilege_id
        privilege_id=$(echo "${response}" | jq -r ".results[] | select(.name == \"${privilege_name}\") | .id" | head -n1)
        
        if [[ -n "${privilege_id}" ]]; then
            echo "${privilege_id}"
            return 0
        else
            log_error "Privilege set '${privilege_name}' not found"
            return 1
        fi
    else
        log_error "Failed to retrieve privilege sets"
        return 1
    fi
}

# Create a standard Jamf Pro user account
# Arguments:
#   $1 - Username
#   $2 - Full name
#   $3 - Email address
#   $4 - Privilege set name
# Returns:
#   0 - User created successfully
#   1 - User creation failed
create_user_account() {
    local username="$1"
    local fullname="$2"
    local email="$3"
    local privilege_set="$4"
    
    log_info "Creating user account: ${username}..."
    
    # Generate a secure random password
    local password
    password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    # Get privilege set ID
    local privilege_id
    if ! privilege_id=$(get_privilege_set_id "${privilege_set}"); then
        log_error "Cannot create user without valid privilege set"
        return 1
    fi
    
    # Build the JSON payload for user creation
    local payload=$(cat <<EOF
{
  "username": "${username}",
  "realName": "${fullname}",
  "email": "${email}",
  "password": "${password}",
  "enabled": true,
  "privilegeSetId": ${privilege_id},
  "accessLevel": "Full Access",
  "currentSiteId": -1,
  "forcePasswordChange": true
}
EOF
)
    
    # Create the user account via API
    local response
    if response=$(api_post "/api/v1/accounts/users" "${payload}"); then
        local user_id=$(echo "${response}" | jq -r '.id // empty')
        if [[ -n "${user_id}" ]]; then
            log_success "User account '${username}' created with ID: ${user_id}"
            log_info "Initial password: ${password}"
            log_warning "Password will need to be changed on first login"
            
            # Store credentials securely for the admin
            echo "Username: ${username}" >> /tmp/jamf-credentials.txt
            echo "Password: ${password}" >> /tmp/jamf-credentials.txt
            echo "Email: ${email}" >> /tmp/jamf-credentials.txt
            echo "---" >> /tmp/jamf-credentials.txt
            
            return 0
        else
            log_error "User created but ID not returned"
            return 1
        fi
    else
        log_error "Failed to create user account '${username}'"
        return 1
    fi
}

# Create multiple user accounts from configuration
# Returns:
#   0 - All users created successfully
#   1 - One or more users failed to create
create_user_accounts_from_config() {
    log_info "Creating user accounts from configuration..."
    
    local success=true
    
    # Check if users are defined in configuration
    if [[ ${#JAMF_USERS[@]} -eq 0 ]]; then
        log_info "No user accounts defined in configuration"
        return 0
    fi
    
    # Initialise credentials file
    echo "Jamf Pro User Credentials" > /tmp/jamf-credentials.txt
    echo "Generated: $(date)" >> /tmp/jamf-credentials.txt
    echo "======================================" >> /tmp/jamf-credentials.txt
    echo "" >> /tmp/jamf-credentials.txt
    
    # Create each user account
    for user_config in "${JAMF_USERS[@]}"; do
        # Parse user configuration (format: username:fullname:email:privilege_set)
        IFS=':' read -r username fullname email privilege_set <<< "${user_config}"
        
        if [[ -z "${username}" || -z "${fullname}" || -z "${email}" || -z "${privilege_set}" ]]; then
            log_error "Invalid user configuration: ${user_config}"
            success=false
            continue
        fi
        
        if ! create_user_account "${username}" "${fullname}" "${email}" "${privilege_set}"; then
            success=false
        fi
    done
    
    # Set secure permissions on credentials file
    if [[ -f /tmp/jamf-credentials.txt ]]; then
        chmod 600 /tmp/jamf-credentials.txt
        log_success "User credentials saved to /tmp/jamf-credentials.txt"
        log_warning "Please store these credentials securely and delete the file"
    fi
    
    if [[ "${success}" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# List all user accounts
# Returns:
#   0 - Users retrieved successfully
#   1 - Failed to retrieve users
list_user_accounts() {
    log_info "Retrieving user accounts..."
    
    local response
    if response=$(api_get "/api/v1/accounts/users"); then
        echo "${response}" | jq -r '.results[] | "\(.id)\t\(.username)\t\(.realName)\t\(.email)"'
        return 0
    else
        log_error "Failed to retrieve user accounts"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------

setup_users() {
    print_section_header "Setting Up User Accounts"
    
    # Create user accounts from configuration
    if ! create_user_accounts_from_config; then
        log_error "Some user accounts failed to create"
        return 1
    fi
    
    # List created accounts
    log_info "Current user accounts:"
    list_user_accounts
    
    log_success "User account setup completed"
    
    return 0
}

# Run the setup if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_users
fi
