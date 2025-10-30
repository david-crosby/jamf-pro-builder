#!/bin/zsh
# ============================================================================
# Jamf Pro Smart Groups Module
# ============================================================================
# This module creates smart groups for macOS version management.
# It will create groups for the current macOS version and the last 2 versions.
# ============================================================================

# Source the helper functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/jamf-helpers.sh"

# ----------------------------------------------------------------------------
# Smart Group Creation Functions
# ----------------------------------------------------------------------------

# Create a smart group for a specific macOS version
# Arguments:
#   $1 - macOS version number (e.g., "15")
#   $2 - macOS version name (e.g., "Sequoia")
# Returns:
#   0 - Smart group created successfully
#   1 - Smart group creation failed
create_macos_version_smart_group() {
    local version="$1"
    local name="$2"
    
    log_info "Creating smart group for macOS ${version} (${name})..."
    
    # Construct the group name
    local group_name="macOS ${version} - ${name}"
    
    # Build the JSON payload for the smart group
    # This group will match computers running the specified macOS version
    local payload=$(cat <<EOF
{
  "name": "${group_name}",
  "criteria": [
    {
      "name": "Operating System Version",
      "priority": 0,
      "andOr": "and",
      "searchType": "like",
      "value": "${version}.",
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

# Create a smart group for computers NOT running the current macOS versions
# This helps identify outdated systems
# Returns:
#   0 - Smart group created successfully
#   1 - Smart group creation failed
create_outdated_macos_smart_group() {
    log_info "Creating smart group for outdated macOS versions..."
    
    local group_name="macOS - Outdated (Not ${MACOS_CURRENT_VERSION}, ${MACOS_PREVIOUS_VERSION_1}, or ${MACOS_PREVIOUS_VERSION_2})"
    
    # Build the JSON payload
    # This group will match computers NOT running any of the supported versions
    local payload=$(cat <<EOF
{
  "name": "${group_name}",
  "criteria": [
    {
      "name": "Operating System Version",
      "priority": 0,
      "andOr": "and",
      "searchType": "not like",
      "value": "${MACOS_CURRENT_VERSION}.",
      "openingParen": false,
      "closingParen": false
    },
    {
      "name": "Operating System Version",
      "priority": 1,
      "andOr": "and",
      "searchType": "not like",
      "value": "${MACOS_PREVIOUS_VERSION_1}.",
      "openingParen": false,
      "closingParen": false
    },
    {
      "name": "Operating System Version",
      "priority": 2,
      "andOr": "and",
      "searchType": "not like",
      "value": "${MACOS_PREVIOUS_VERSION_2}.",
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

# Create a smart group for the latest patch of each macOS version
# Arguments:
#   $1 - macOS version number (e.g., "15")
#   $2 - macOS version name (e.g., "Sequoia")
#   $3 - Latest patch version (e.g., "15.2")
# Returns:
#   0 - Smart group created successfully
#   1 - Smart group creation failed
create_latest_patch_smart_group() {
    local version="$1"
    local name="$2"
    local latest_patch="$3"
    
    log_info "Creating smart group for latest patch of macOS ${version}..."
    
    local group_name="macOS ${version} - Latest Patch (${latest_patch})"
    
    # Build the JSON payload
    local payload=$(cat <<EOF
{
  "name": "${group_name}",
  "criteria": [
    {
      "name": "Operating System Version",
      "priority": 0,
      "andOr": "and",
      "searchType": "is",
      "value": "${latest_patch}",
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

# Create a smart group for computers needing updates within a major version
# Arguments:
#   $1 - macOS version number (e.g., "15")
#   $2 - macOS version name (e.g., "Sequoia")
#   $3 - Latest patch version (e.g., "15.2")
# Returns:
#   0 - Smart group created successfully
#   1 - Smart group creation failed
create_update_needed_smart_group() {
    local version="$1"
    local name="$2"
    local latest_patch="$3"
    
    log_info "Creating smart group for macOS ${version} computers needing updates..."
    
    local group_name="macOS ${version} - Update Needed"
    
    # Build the JSON payload
    # This group matches computers on this major version but not on the latest patch
    local payload=$(cat <<EOF
{
  "name": "${group_name}",
  "criteria": [
    {
      "name": "Operating System Version",
      "priority": 0,
      "andOr": "and",
      "searchType": "like",
      "value": "${version}.",
      "openingParen": false,
      "closingParen": false
    },
    {
      "name": "Operating System Version",
      "priority": 1,
      "andOr": "and",
      "searchType": "is not",
      "value": "${latest_patch}",
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
# Main Execution
# ----------------------------------------------------------------------------

setup_smart_groups() {
    print_section_header "Setting Up Smart Groups"
    
    local success=true
    
    # Create smart groups for current macOS version
    if ! create_macos_version_smart_group "${MACOS_CURRENT_VERSION}" "${MACOS_CURRENT_NAME}"; then
        success=false
    fi
    
    # Create smart groups for previous macOS versions
    if ! create_macos_version_smart_group "${MACOS_PREVIOUS_VERSION_1}" "${MACOS_PREVIOUS_NAME_1}"; then
        success=false
    fi
    
    if ! create_macos_version_smart_group "${MACOS_PREVIOUS_VERSION_2}" "${MACOS_PREVIOUS_NAME_2}"; then
        success=false
    fi
    
    # Create smart group for outdated systems
    if ! create_outdated_macos_smart_group; then
        success=false
    fi
    
    # Optional: Create groups for latest patches and update tracking
    # Uncomment the following lines and provide latest patch versions if desired
    # create_latest_patch_smart_group "${MACOS_CURRENT_VERSION}" "${MACOS_CURRENT_NAME}" "15.2"
    # create_update_needed_smart_group "${MACOS_CURRENT_VERSION}" "${MACOS_CURRENT_NAME}" "15.2"
    
    if [[ "${success}" == "true" ]]; then
        log_success "Smart groups setup completed successfully"
        return 0
    else
        log_error "Some smart groups failed to create"
        return 1
    fi
}

# Run the setup if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_smart_groups
fi
