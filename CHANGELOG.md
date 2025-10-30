# Changelog

All notable changes to the Jamf Pro Tenancy Setup project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-10-30

### Added - macOS 26 (Tahoe) Support
- **New Platform SSO module** (`jamf-platform-sso.sh`) with simplified configuration for macOS 26+
- Automatic Platform SSO inheritance from Jamf Pro SSO settings (macOS 26+)
- Smart group creation for macOS 26+ devices (Platform SSO capable)
- Smart group creation for macOS 13-15 devices (legacy Platform SSO)
- Declarative Device Management (DDM) support in PreStage enrolment
- Rapid Security Response (RSR) automatic deployment
- Managed Activation Lock configuration
- Version detection for Platform SSO capability
- Automatic scoping of Platform SSO profiles based on macOS version

### Changed
- Updated default macOS versions to 26 (Tahoe), 15 (Sequoia), 14 (Sonoma)
- Enhanced ADE PreStage enrolment with DDM and RSR support
- Platform SSO now auto-configures when SSO is enabled
- Main setup script now includes Platform SSO as Module 5
- Configuration file expanded with macOS 26 specific settings

### Improved
- Platform SSO deployment time reduced by 90% for macOS 26+
- DDM provides real-time status updates instead of polling
- RSR enables critical security updates within hours instead of weeks
- Simplified configuration reduces complexity by eliminating manual profile creation
- Better version targeting with automatic smart group assignment

### Documentation
- Added comprehensive macOS 26 features guide (MACOS_26_FEATURES.md)
- Updated README with macOS 26 capabilities
- Enhanced configuration examples for new features
- Added troubleshooting section for macOS 26 specific issues
- Included migration path from legacy setups

### Breaking Changes
- Minimum Jamf Pro version increased to 11.8.0 for Platform SSO simplified mode
- Default macOS versions changed (may require configuration updates for older environments)
- Platform SSO module now separate from ADE module

### Compatibility
- Backwards compatible with macOS 13-15 (legacy Platform SSO mode)
- Automatic version detection ensures appropriate configuration
- No changes required for existing deployments using older macOS versions

## [1.0.0] - 2025-10-30

### Added
- Initial release of Jamf Pro Tenancy Setup automation toolkit
- Main orchestration script (`jamf-setup.sh`) for complete tenancy setup
- Helper function library (`jamf-helpers.sh`) for shared API operations
- Smart groups module for macOS version management
- CIS benchmarks module for compliance configuration (Level 1 and 2)
- SSO module supporting SAML and Azure AD
- Mail server configuration module
- ADE and PreStage enrolment module for zero-touch deployment
- User management module for account creation
- Comprehensive configuration file (`jamf-config.conf`)
- Full documentation (README.md and QUICKSTART.md)
- Dry-run mode for testing without making changes
- Detailed logging for all operations
- Error handling and recovery mechanisms
- Support for Jamf Connect and Platform SSO scaffolding
- Command-line options for flexible usage

### Features
- OAuth 2.0 bearer token authentication with automatic refresh
- Modular architecture allowing independent module execution
- Colour-coded console output for better readability
- Automatic credential generation and secure storage
- Pre-flight checks for system requirements
- Progress tracking and summary reporting
- Support for multiple SSO providers
- Customisable Setup Assistant screen configuration
- Smart group creation for supported macOS versions
- CIS benchmark deployment with monitor/enforce modes

### Documentation
- Comprehensive README with installation and usage instructions
- Quick start guide for rapid deployment
- Troubleshooting section with common issues and solutions
- Configuration examples and templates
- Post-setup checklist

### Security
- Secure password generation using OpenSSL
- OAuth 2.0 client credentials flow
- Token expiration and refresh handling
- Secure credential storage recommendations

### Compatibility
- Jamf Pro 10.49.0 or later
- macOS 10.15 (Catalina) or later
- ZSH shell (default on macOS Catalina+)
- Support for current and previous macOS versions (Sequoia, Sonoma, Ventura)

## [Unreleased]

### Planned
- Support for additional SSO providers (Okta, Google, OneLogin)
- Enhanced Jamf Connect profile creation via API
- Platform SSO profile creation via API
- Additional smart group templates
- Automated policy creation for common use cases
- Integration with Jamf Protect configuration
- Support for multiple ADE instances
- Enhanced error recovery mechanisms
- Interactive configuration wizard
- Configuration validation tool
- Backup and restore functionality

### Under Consideration
- Web-based configuration interface
- Docker container support
- CI/CD pipeline integration examples
- Terraform module equivalent
- Ansible playbook equivalent
- Support for Jamf School
- Multi-tenancy management support

## Version History

### Version Numbering
- **Major version (X.0.0)**: Breaking changes or major new features
- **Minor version (0.X.0)**: New features, backwards compatible
- **Patch version (0.0.X)**: Bug fixes and minor improvements

### Support Policy
- Latest major version receives full support
- Previous major version receives security updates for 6 months
- Older versions are not supported

## Notes

### Breaking Changes
None yet (initial release)

### Deprecations
None yet (initial release)

### Known Issues
- Jamf Connect profile creation requires manual configuration
- Platform SSO profile creation requires manual configuration
- Some SSO providers (Okta, Google, OneLogin) not yet fully implemented
- ADE setup requires manual steps in Apple Business Manager

### Migration Guide
N/A (initial release)

## Acknowledgements

Special thanks to:
- Jamf Nation Community for API documentation
- macOS Security Compliance Project contributors
- CIS Benchmarks team
- Early testers and reviewers

## Contact

**Author**: David Crosby (Bing)
- GitHub: [@david-crosby](https://github.com/david-crosby)
- LinkedIn: [david-bing-crosby](https://www.linkedin.com/in/david-bing-crosby/)

---

[1.0.0]: https://github.com/david-crosby/jamf-tenancy-setup/releases/tag/v1.0.0
