#!/bin/zsh
# ============================================================================
# Jamf Pro API Helper Functions Library
# ============================================================================
# This library provides common functions for interacting with the Jamf Pro API
# including authentication, token management, and standard API operations.
# ============================================================================

# Colour codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Colour

# Global variables for token management
BEARER_TOKEN=""
TOKEN_EXPIRATION=""

# ----------------------------------------------------------------------------
# Logging Functions
# ----------------------------------------------------------------------------

# Log an informational message to console and file
# Arguments:
#   $1 - Message to log
log_info() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1"
    echo "${BLUE}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

# Log a success message to console and file
# Arguments:
#   $1 - Message to log
log_success() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $1"
    echo "${GREEN}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

# Log a warning message to console and file
# Arguments:
#   $1 - Message to log
log_warning() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING] $1"
    echo "${YELLOW}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

# Log an error message to console and file
# Arguments:
#   $1 - Message to log
log_error() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1"
    echo "${RED}${message}${NC}" >&2
    echo "${message}" >> "${LOG_FILE}"
}

# ----------------------------------------------------------------------------
# Configuration Validation Functions
# ----------------------------------------------------------------------------

# Validate that required configuration variables are set
# Returns:
#   0 - All required variables are set
#   1 - One or more required variables are missing
validate_config() {
    log_info "Validating configuration..."
    
    local required_vars=(
        "JAMF_URL"
        "JAMF_CLIENT_ID"
        "JAMF_CLIENT_SECRET"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${(P)var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required configuration variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        return 1
    fi
    
    # Validate URL format
    if [[ ! "${JAMF_URL}" =~ ^https?:// ]]; then
        log_error "JAMF_URL must start with http:// or https://"
        return 1
    fi
    
    log_success "Configuration validation complete"
    return 0
}

# ----------------------------------------------------------------------------
# Authentication Functions
# ----------------------------------------------------------------------------

# Obtain a bearer token using client credentials
# Sets the global BEARER_TOKEN and TOKEN_EXPIRATION variables
# Returns:
#   0 - Token obtained successfully
#   1 - Token retrieval failed
get_bearer_token() {
    log_info "Obtaining bearer token..."
    
    # Make the authentication request
    local response
    response=$(curl -s -X POST "${JAMF_URL}/api/oauth/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=${JAMF_CLIENT_ID}" \
        -d "client_secret=${JAMF_CLIENT_SECRET}" \
        -d "grant_type=client_credentials")
    
    # Check if the request was successful
    if [[ $? -ne 0 ]]; then
        log_error "Failed to connect to Jamf Pro instance"
        return 1
    fi
    
    # Extract the token from the response
    BEARER_TOKEN=$(echo "${response}" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
    
    if [[ -z "${BEARER_TOKEN}" ]]; then
        log_error "Failed to obtain bearer token. Response: ${response}"
        return 1
    fi
    
    # Extract the expiration time (in seconds)
    local expires_in
    expires_in=$(echo "${response}" | grep -o '"expires_in":[0-9]*' | cut -d':' -f2)
    
    # Calculate expiration timestamp
    TOKEN_EXPIRATION=$(( $(date +%s) + expires_in ))
    
    log_success "Bearer token obtained (expires in ${expires_in} seconds)"
    return 0
}

# Check if the current token is still valid
# Returns:
#   0 - Token is valid
#   1 - Token is expired or not set
is_token_valid() {
    if [[ -z "${BEARER_TOKEN}" ]]; then
        return 1
    fi
    
    local current_time=$(date +%s)
    # Add a 60-second buffer to refresh before actual expiration
    local expiration_with_buffer=$(( TOKEN_EXPIRATION - 60 ))
    
    if [[ ${current_time} -gt ${expiration_with_buffer} ]]; then
        return 1
    fi
    
    return 0
}

# Ensure a valid bearer token is available
# Refreshes the token if necessary
# Returns:
#   0 - Valid token available
#   1 - Failed to obtain token
ensure_valid_token() {
    if ! is_token_valid; then
        if ! get_bearer_token; then
            return 1
        fi
    fi
    return 0
}

# Invalidate the current bearer token
# Returns:
#   0 - Token invalidated successfully
#   1 - Token invalidation failed
invalidate_token() {
    if [[ -z "${BEARER_TOKEN}" ]]; then
        return 0
    fi
    
    log_info "Invalidating bearer token..."
    
    curl -s -X POST "${JAMF_URL}/api/v1/auth/invalidate-token" \
        -H "Authorization: Bearer ${BEARER_TOKEN}" > /dev/null
    
    BEARER_TOKEN=""
    TOKEN_EXPIRATION=""
    
    log_success "Bearer token invalidated"
    return 0
}

# ----------------------------------------------------------------------------
# API Request Functions
# ----------------------------------------------------------------------------

# Make a GET request to the Jamf Pro API
# Arguments:
#   $1 - API endpoint (without base URL)
#   $2 - (Optional) Additional curl options
# Returns:
#   0 - Request successful
#   1 - Request failed
# Output:
#   Response body from the API
api_get() {
    local endpoint="$1"
    local additional_opts="${2:-}"
    
    if ! ensure_valid_token; then
        log_error "Failed to obtain valid token for GET request"
        return 1
    fi
    
    local url="${JAMF_URL}${endpoint}"
    log_info "GET ${endpoint}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "DRY RUN: Would execute GET ${url}"
        echo '{"dryRun": true}'
        return 0
    fi
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" -X GET "${url}" \
        -H "Authorization: Bearer ${BEARER_TOKEN}" \
        -H "Accept: application/json" \
        ${additional_opts})
    
    http_code=$(echo "${response}" | tail -n1)
    response=$(echo "${response}" | sed '$d')
    
    if [[ ${http_code} -ge 200 && ${http_code} -lt 300 ]]; then
        echo "${response}"
        return 0
    else
        log_error "GET request failed with status ${http_code}: ${response}"
        return 1
    fi
}

# Make a POST request to the Jamf Pro API
# Arguments:
#   $1 - API endpoint (without base URL)
#   $2 - JSON payload
#   $3 - (Optional) Additional curl options
# Returns:
#   0 - Request successful
#   1 - Request failed
# Output:
#   Response body from the API
api_post() {
    local endpoint="$1"
    local payload="$2"
    local additional_opts="${3:-}"
    
    if ! ensure_valid_token; then
        log_error "Failed to obtain valid token for POST request"
        return 1
    fi
    
    local url="${JAMF_URL}${endpoint}"
    log_info "POST ${endpoint}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "DRY RUN: Would execute POST ${url}"
        log_warning "Payload: ${payload}"
        echo '{"dryRun": true, "id": 999}'
        return 0
    fi
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" -X POST "${url}" \
        -H "Authorization: Bearer ${BEARER_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "${payload}" \
        ${additional_opts})
    
    http_code=$(echo "${response}" | tail -n1)
    response=$(echo "${response}" | sed '$d')
    
    if [[ ${http_code} -ge 200 && ${http_code} -lt 300 ]]; then
        echo "${response}"
        return 0
    else
        log_error "POST request failed with status ${http_code}: ${response}"
        return 1
    fi
}

# Make a PUT request to the Jamf Pro API
# Arguments:
#   $1 - API endpoint (without base URL)
#   $2 - JSON payload
#   $3 - (Optional) Additional curl options
# Returns:
#   0 - Request successful
#   1 - Request failed
# Output:
#   Response body from the API
api_put() {
    local endpoint="$1"
    local payload="$2"
    local additional_opts="${3:-}"
    
    if ! ensure_valid_token; then
        log_error "Failed to obtain valid token for PUT request"
        return 1
    fi
    
    local url="${JAMF_URL}${endpoint}"
    log_info "PUT ${endpoint}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "DRY RUN: Would execute PUT ${url}"
        log_warning "Payload: ${payload}"
        echo '{"dryRun": true}'
        return 0
    fi
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" -X PUT "${url}" \
        -H "Authorization: Bearer ${BEARER_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "${payload}" \
        ${additional_opts})
    
    http_code=$(echo "${response}" | tail -n1)
    response=$(echo "${response}" | sed '$d')
    
    if [[ ${http_code} -ge 200 && ${http_code} -lt 300 ]]; then
        echo "${response}"
        return 0
    else
        log_error "PUT request failed with status ${http_code}: ${response}"
        return 1
    fi
}

# Make a DELETE request to the Jamf Pro API
# Arguments:
#   $1 - API endpoint (without base URL)
#   $2 - (Optional) Additional curl options
# Returns:
#   0 - Request successful
#   1 - Request failed
api_delete() {
    local endpoint="$1"
    local additional_opts="${2:-}"
    
    if ! ensure_valid_token; then
        log_error "Failed to obtain valid token for DELETE request"
        return 1
    fi
    
    local url="${JAMF_URL}${endpoint}"
    log_info "DELETE ${endpoint}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "DRY RUN: Would execute DELETE ${url}"
        return 0
    fi
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" -X DELETE "${url}" \
        -H "Authorization: Bearer ${BEARER_TOKEN}" \
        ${additional_opts})
    
    http_code=$(echo "${response}" | tail -n1)
    
    if [[ ${http_code} -ge 200 && ${http_code} -lt 300 ]]; then
        return 0
    else
        log_error "DELETE request failed with status ${http_code}"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Utility Functions
# ----------------------------------------------------------------------------

# Check if a command is available
# Arguments:
#   $1 - Command name
# Returns:
#   0 - Command is available
#   1 - Command is not available
check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "Required command '${cmd}' is not installed"
        return 1
    fi
    return 0
}

# Verify required commands are available
# Returns:
#   0 - All required commands are available
#   1 - One or more required commands are missing
verify_requirements() {
    log_info "Verifying required commands..."
    
    local required_commands=(
        "curl"
        "jq"
        "base64"
    )
    
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! check_command "${cmd}"; then
            missing_commands+=("${cmd}")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands:"
        for cmd in "${missing_commands[@]}"; do
            log_error "  - ${cmd}"
        done
        log_error "Please install missing commands and try again"
        return 1
    fi
    
    log_success "All required commands are available"
    return 0
}

# Pause and wait for user confirmation
# Arguments:
#   $1 - Prompt message
pause_for_confirmation() {
    local prompt="${1:-Press Enter to continue...}"
    echo ""
    read "?${YELLOW}${prompt}${NC} "
}

# Display a section header
# Arguments:
#   $1 - Section title
print_section_header() {
    local title="$1"
    local width=80
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo ""
    echo "${BLUE}$(printf '=%.0s' {1..${width}})${NC}"
    echo "${BLUE}$(printf ' %.0s' {1..${padding}})${title}$(printf ' %.0s' {1..${padding}})${NC}"
    echo "${BLUE}$(printf '=%.0s' {1..${width}})${NC}"
    echo ""
}
