# Project Structure

This document explains the organisation and relationships between all files in the Jamf Pro Tenancy Setup toolkit.

## File Overview

```
jamf-tenancy-setup/
├── Core Scripts
│   ├── jamf-setup.sh              # Main orchestration script (11K)
│   ├── jamf-helpers.sh            # Shared helper functions (13K)
│   └── jamf-config.conf           # Configuration file (5.7K)
│
├── Module Scripts
│   ├── jamf-smart-groups.sh       # macOS version smart groups (8.8K)
│   ├── jamf-cis-benchmarks.sh     # CIS compliance setup (9.2K)
│   ├── jamf-sso.sh                # SSO configuration (6.0K)
│   ├── jamf-mail-server.sh        # SMTP server setup (3.8K)
│   ├── jamf-ade-prestage.sh       # ADE & PreStage setup (15K)
│   └── jamf-users.sh              # User account management (6.5K)
│
└── Documentation
    ├── README.md                   # Main documentation (13K)
    ├── QUICKSTART.md               # Quick start guide (5.7K)
    ├── EXAMPLE_USAGE.md            # Real-world example (12K)
    ├── CHANGELOG.md                # Version history (4.3K)
    └── LICENSE                     # MIT License (1.1K)
```

## Script Dependencies

### Dependency Graph

```
jamf-setup.sh (Main Entry Point)
    │
    ├─→ jamf-config.conf (Configuration)
    │
    ├─→ jamf-helpers.sh (Always loaded first)
    │   └── Functions used by all modules
    │
    ├─→ jamf-smart-groups.sh (Module 1)
    │   └── Uses: jamf-helpers.sh
    │
    ├─→ jamf-cis-benchmarks.sh (Module 2)
    │   └── Uses: jamf-helpers.sh
    │
    ├─→ jamf-sso.sh (Module 3)
    │   └── Uses: jamf-helpers.sh
    │
    ├─→ jamf-mail-server.sh (Module 4)
    │   └── Uses: jamf-helpers.sh
    │
    ├─→ jamf-ade-prestage.sh (Module 5)
    │   └── Uses: jamf-helpers.sh
    │
    └─→ jamf-users.sh (Module 6)
        └── Uses: jamf-helpers.sh
```

## File Descriptions

### Core Scripts

#### `jamf-setup.sh`
**Purpose**: Main orchestration script that coordinates all modules  
**Functions**:
- Pre-flight system checks
- Sequential module execution
- Progress tracking and reporting
- Error handling and recovery
- Summary and next steps

**Usage**:
```bash
./jamf-setup.sh [--dry-run] [--config FILE]
```

#### `jamf-helpers.sh`
**Purpose**: Shared library of helper functions  
**Functions**:
- API authentication (OAuth 2.0)
- Token management
- HTTP request wrappers (GET, POST, PUT, DELETE)
- Logging functions
- Configuration validation
- Utility functions

**Usage**: Sourced by all other scripts
```bash
source jamf-helpers.sh
```

#### `jamf-config.conf`
**Purpose**: Central configuration file  
**Contains**:
- Jamf Pro instance details
- API credentials
- SSO settings
- Mail server settings
- ADE configuration
- macOS version definitions
- CIS benchmark settings
- User account definitions

### Module Scripts

#### `jamf-smart-groups.sh`
**Purpose**: Creates smart groups for macOS version management  
**Creates**:
- Groups for current macOS version (e.g., Sequoia)
- Groups for previous 2 versions (e.g., Sonoma, Ventura)
- Group for outdated systems

**Can run standalone**:
```bash
./jamf-smart-groups.sh
```

#### `jamf-cis-benchmarks.sh`
**Purpose**: Configures CIS compliance benchmarks  
**Configures**:
- CIS Level 1 benchmark
- CIS Level 2 benchmark
- Monitor or enforce mode
- Scope smart groups

**Can run standalone**:
```bash
./jamf-cis-benchmarks.sh
```

#### `jamf-sso.sh`
**Purpose**: Sets up Single Sign-On integration  
**Supports**:
- SAML 2.0
- Azure AD
- Okta (planned)
- Google (planned)

**Can run standalone**:
```bash
./jamf-sso.sh
```

#### `jamf-mail-server.sh`
**Purpose**: Configures SMTP mail server  
**Configures**:
- SMTP connection settings
- Authentication
- TLS/SSL
- Test email functionality

**Can run standalone**:
```bash
./jamf-mail-server.sh
```

#### `jamf-ade-prestage.sh`
**Purpose**: Sets up Automated Device Enrolment  
**Configures**:
- Downloads ADE public key
- Uploads ADE server token
- Creates PreStage enrolment
- Configures Setup Assistant
- Jamf Connect scaffolding
- Platform SSO scaffolding

**Can run standalone**:
```bash
./jamf-ade-prestage.sh
```

#### `jamf-users.sh`
**Purpose**: Creates Jamf Pro user accounts  
**Creates**:
- User accounts with specified privileges
- Secure passwords
- Stores credentials temporarily

**Can run standalone**:
```bash
./jamf-users.sh
```

## Documentation Files

### `README.md`
Complete documentation including:
- Features and capabilities
- Prerequisites
- Installation instructions
- Configuration guide
- Usage examples
- Troubleshooting

### `QUICKSTART.md`
Rapid deployment guide:
- Step-by-step setup (15 minutes)
- Minimum configuration
- Common issues
- Post-setup checklist

### `EXAMPLE_USAGE.md`
Real-world scenario:
- Complete configuration example
- Timeline and steps
- Results and metrics
- Lessons learned

### `CHANGELOG.md`
Version history:
- Release notes
- New features
- Bug fixes
- Breaking changes

### `LICENSE`
MIT License terms

## Execution Flow

### Standard Execution

```
User runs: ./jamf-setup.sh
    ↓
1. Load jamf-config.conf
    ↓
2. Source jamf-helpers.sh
    ↓
3. Pre-flight checks
    ├─ Verify required commands
    ├─ Validate configuration
    └─ Test API connectivity
    ↓
4. Module 1: Smart Groups
    ↓
5. Module 2: CIS Benchmarks
    ↓
6. Module 3: SSO
    ↓
7. Module 4: Mail Server
    ↓
8. Module 5: ADE & PreStage
    ↓
9. Module 6: User Accounts
    ↓
10. Summary & Next Steps
```

### Individual Module Execution

```
User runs: ./jamf-smart-groups.sh
    ↓
1. Script sources jamf-helpers.sh
    ↓
2. jamf-helpers.sh loads jamf-config.conf
    ↓
3. Module executes its functions
    ↓
4. Results displayed
```

## Data Flow

### Configuration → Scripts
```
jamf-config.conf
    ↓
Variables loaded into environment
    ↓
Used by all scripts for:
    - API authentication
    - Feature configuration
    - Settings and preferences
```

### Scripts → Jamf Pro
```
Module Script
    ↓
Calls helper functions
    ↓
Helper functions make API requests
    ↓
Jamf Pro API
    ↓
Changes applied to tenancy
```

### Scripts → User
```
Operations performed
    ↓
Logging functions called
    ↓
Output to:
    - Console (colour-coded)
    - Log file (/tmp/jamf-setup-*.log)
    - Credentials file (/tmp/jamf-credentials.txt)
```

## File Permissions

All scripts should be executable:
```bash
chmod +x jamf-*.sh
```

Configuration file should be readable:
```bash
chmod 644 jamf-config.conf
```

## Size Summary

| Category | Files | Total Size |
|----------|-------|------------|
| Scripts | 7 | 73.3K |
| Documentation | 5 | 36.1K |
| Configuration | 1 | 5.7K |
| **Total** | **13** | **115.1K** |

## Integration Points

### External Systems
- **Jamf Pro**: All modules interact via REST API
- **Apple Business Manager**: Manual integration for ADE
- **SSO Provider**: Automated configuration (SAML/Azure AD)
- **SMTP Server**: Automated configuration
- **Identity Provider**: User attribute mapping

### Internal Dependencies
- All modules depend on `jamf-helpers.sh`
- All modules use configuration from `jamf-config.conf`
- Main script orchestrates module execution
- No inter-module dependencies (modular design)

## Customisation Points

Users can customise:
1. **Configuration**: Edit `jamf-config.conf`
2. **Module Selection**: Comment out modules in `jamf-setup.sh`
3. **Helper Functions**: Extend `jamf-helpers.sh`
4. **Individual Modules**: Modify any module script
5. **Execution Order**: Change sequence in `jamf-setup.sh`

## Best Practices

1. **Always test with dry-run first**:
   ```bash
   ./jamf-setup.sh --dry-run
   ```

2. **Keep configuration secure**:
   - Don't commit `jamf-config.conf` with real credentials
   - Use environment variables for secrets in CI/CD

3. **Review logs after execution**:
   ```bash
   cat /tmp/jamf-setup-*.log
   ```

4. **Back up configuration**:
   ```bash
   cp jamf-config.conf jamf-config.conf.backup
   ```

5. **Version control**:
   - Commit scripts to Git
   - Use `.gitignore` for config files with secrets

## Troubleshooting File Locations

| Issue | Check File |
|-------|-----------|
| Setup failures | `/tmp/jamf-setup-*.log` |
| Configuration errors | `jamf-config.conf` |
| API issues | `jamf-helpers.sh` (authentication functions) |
| Module failures | Individual module script |
| Missing credentials | `/tmp/jamf-credentials.txt` |
| ADE public key | `/tmp/jamf-ade-public-key.pem` |

---

This structure provides a modular, maintainable, and extensible framework for Jamf Pro tenancy automation.
