#!/bin/zsh
# ============================================================================
# Jamf Pro CIS Benchmarks Module
# ============================================================================
# This module enables and configures CIS Level 1 and Level 2 benchmarks
# using Jamf Pro's built-in compliance benchmarks feature.
# ============================================================================

# Source the helper functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/jamf-helpers.sh"

# ----------------------------------------------------------------------------
# CIS Benchmark Functions
# ----------------------------------------------------------------------------

# Get available compliance benchmark templates
# Returns:
#   0 - Successfully retrieved templates
#   1 - Failed to retrieve templates
# Output:
#   JSON array of available benchmark templates
get_available_benchmarks() {
    log_info "Retrieving available compliance benchmarks..."
    
    local response
    if response=$(api_get "/api/v1/compliance-benchmarks/available"); then
        echo "${response}"
        return 0
    else
        log_error "Failed to retrieve available compliance benchmarks"
        return 1
    fi
}

# Create a compliance benchmark
# Arguments:
#   $1 - Benchmark name (e.g., "CIS Level 1", "CIS Level 2")
#   $2 - Template ID from available benchmarks
#   $3 - Enforcement mode ("monitor" or "enforce")
#   $4 - Smart group ID for scope
# Returns:
#   0 - Benchmark created successfully
#   1 - Benchmark creation failed
create_compliance_benchmark() {
    local benchmark_name="$1"
    local template_id="$2"
    local enforcement_mode="$3"
    local smart_group_id="$4"
    
    log_info "Creating compliance benchmark: ${benchmark_name}..."
    
    # Validate enforcement mode
    if [[ "${enforcement_mode}" != "monitor" && "${enforcement_mode}" != "enforce" ]]; then
        log_error "Invalid enforcement mode: ${enforcement_mode}. Must be 'monitor' or 'enforce'"
        return 1
    fi
    
    # Build the JSON payload
    local payload=$(cat <<EOF
{
  "name": "${benchmark_name}",
  "templateId": "${template_id}",
  "enforcementMode": "${enforcement_mode}",
  "scope": {
    "smartGroupId": "${smart_group_id}"
  }
}
EOF
)
    
    # Create the benchmark via API
    local response
    if response=$(api_post "/api/v1/compliance-benchmarks" "${payload}"); then
        local benchmark_id=$(echo "${response}" | jq -r '.id // empty')
        if [[ -n "${benchmark_id}" ]]; then
            log_success "Compliance benchmark '${benchmark_name}' created with ID: ${benchmark_id}"
            echo "${benchmark_id}"
            return 0
        else
            log_error "Benchmark created but ID not returned"
            return 1
        fi
    else
        log_error "Failed to create compliance benchmark '${benchmark_name}'"
        return 1
    fi
}

# Deploy a compliance benchmark
# Arguments:
#   $1 - Benchmark ID
# Returns:
#   0 - Benchmark deployed successfully
#   1 - Benchmark deployment failed
deploy_compliance_benchmark() {
    local benchmark_id="$1"
    
    log_info "Deploying compliance benchmark ID: ${benchmark_id}..."
    
    # Deploy the benchmark
    if api_post "/api/v1/compliance-benchmarks/${benchmark_id}/deploy" "{}"; then
        log_success "Compliance benchmark deployed successfully"
        return 0
    else
        log_error "Failed to deploy compliance benchmark"
        return 1
    fi
}

# Create a smart group for all macOS computers (for CIS benchmark scope)
# Returns:
#   0 - Smart group created successfully
#   1 - Smart group creation failed
# Output:
#   Smart group ID
create_all_computers_smart_group() {
    log_info "Creating smart group for all macOS computers..."
    
    local group_name="All macOS Computers"
    
    # Build the JSON payload
    # This group will match all macOS computers
    local payload=$(cat <<EOF
{
  "name": "${group_name}",
  "criteria": [
    {
      "name": "Computer Group",
      "priority": 0,
      "andOr": "and",
      "searchType": "member of",
      "value": "All Managed Computers",
      "openingParen": false,
      "closingParen": false
    },
    {
      "name": "Operating System",
      "priority": 1,
      "andOr": "and",
      "searchType": "like",
      "value": "macOS",
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

# Setup CIS Level 1 benchmark
# Arguments:
#   $1 - Smart group ID for scope
# Returns:
#   0 - CIS Level 1 setup successful
#   1 - CIS Level 1 setup failed
setup_cis_level_1() {
    local smart_group_id="$1"
    
    log_info "Setting up CIS Level 1 benchmark..."
    
    # Get available benchmarks to find CIS Level 1 template
    local available_benchmarks
    if ! available_benchmarks=$(get_available_benchmarks); then
        return 1
    fi
    
    # Extract CIS Level 1 template ID
    # Note: The exact template name may vary - adjust as needed
    local template_id
    template_id=$(echo "${available_benchmarks}" | jq -r '.[] | select(.name | contains("CIS Level 1")) | .id' | head -n1)
    
    if [[ -z "${template_id}" ]]; then
        log_error "CIS Level 1 template not found in available benchmarks"
        log_info "Available benchmarks:"
        echo "${available_benchmarks}" | jq -r '.[].name'
        return 1
    fi
    
    log_info "Found CIS Level 1 template ID: ${template_id}"
    
    # Create the benchmark
    local benchmark_id
    if benchmark_id=$(create_compliance_benchmark "CIS Level 1 - macOS" "${template_id}" "${CIS_LEVEL_1_MODE}" "${smart_group_id}"); then
        # Deploy the benchmark
        if deploy_compliance_benchmark "${benchmark_id}"; then
            log_success "CIS Level 1 benchmark setup complete"
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Setup CIS Level 2 benchmark
# Arguments:
#   $1 - Smart group ID for scope
# Returns:
#   0 - CIS Level 2 setup successful
#   1 - CIS Level 2 setup failed
setup_cis_level_2() {
    local smart_group_id="$1"
    
    log_info "Setting up CIS Level 2 benchmark..."
    
    # Get available benchmarks to find CIS Level 2 template
    local available_benchmarks
    if ! available_benchmarks=$(get_available_benchmarks); then
        return 1
    fi
    
    # Extract CIS Level 2 template ID
    # Note: The exact template name may vary - adjust as needed
    local template_id
    template_id=$(echo "${available_benchmarks}" | jq -r '.[] | select(.name | contains("CIS Level 2")) | .id' | head -n1)
    
    if [[ -z "${template_id}" ]]; then
        log_error "CIS Level 2 template not found in available benchmarks"
        log_info "Available benchmarks:"
        echo "${available_benchmarks}" | jq -r '.[].name'
        return 1
    fi
    
    log_info "Found CIS Level 2 template ID: ${template_id}"
    
    # Create the benchmark
    local benchmark_id
    if benchmark_id=$(create_compliance_benchmark "CIS Level 2 - macOS" "${template_id}" "${CIS_LEVEL_2_MODE}" "${smart_group_id}"); then
        # Deploy the benchmark
        if deploy_compliance_benchmark "${benchmark_id}"; then
            log_success "CIS Level 2 benchmark setup complete"
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------

setup_cis_benchmarks() {
    print_section_header "Setting Up CIS Benchmarks"
    
    local success=true
    
    # Create a smart group for all computers to use as scope
    local smart_group_id
    if ! smart_group_id=$(create_all_computers_smart_group); then
        log_error "Failed to create scope smart group for CIS benchmarks"
        return 1
    fi
    
    # Setup CIS Level 1 if enabled
    if [[ "${ENABLE_CIS_LEVEL_1}" == "true" ]]; then
        if ! setup_cis_level_1 "${smart_group_id}"; then
            log_warning "CIS Level 1 setup failed"
            success=false
        fi
    else
        log_info "CIS Level 1 disabled in configuration"
    fi
    
    # Setup CIS Level 2 if enabled
    if [[ "${ENABLE_CIS_LEVEL_2}" == "true" ]]; then
        if ! setup_cis_level_2 "${smart_group_id}"; then
            log_warning "CIS Level 2 setup failed"
            success=false
        fi
    else
        log_info "CIS Level 2 disabled in configuration"
    fi
    
    if [[ "${success}" == "true" ]]; then
        log_success "CIS benchmarks setup completed successfully"
        return 0
    else
        log_error "Some CIS benchmark setups failed"
        return 1
    fi
}

# Run the setup if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_cis_benchmarks
fi
