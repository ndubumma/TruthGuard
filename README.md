# TruthGuard

A decentralized conditional information disclosure system built on the Stacks blockchain. TruthGuard enables secure storage of encrypted information that automatically becomes accessible when predefined monitoring parameters are violated and sufficient trigger events are reported.

## Overview

TruthGuard provides a trustless mechanism for conditional information disclosure, where sensitive data remains encrypted and inaccessible until specific threshold conditions are met through community reporting and validation. This creates a powerful tool for accountability, transparency, and protective disclosure scenarios.

## Key Features

### Encrypted Information Storage
- Securely store encrypted payloads on-chain
- Information remains inaccessible until disclosure conditions are met
- Custodian-controlled decryption keys

### Threshold-Based Disclosure
- Configurable trigger thresholds for automatic disclosure
- Community-driven trigger event reporting
- Validated reporting system with authorized validators

### Multi-Layer Security
- Administrative override capabilities
- Authorized validator system for event verification
- Protection against false or malicious reports

### Transparent Monitoring
- Public monitoring parameters for each disclosure
- Immutable event logging and timestamp tracking
- Complete audit trail of all trigger events

## Use Cases

- **Corporate Accountability**: Automatic disclosure of internal documents when ethical violations are reported
- **Environmental Protection**: Release of environmental data when monitoring parameters are breached
- **Whistleblower Protection**: Secure mechanism for conditional information release with built-in safeguards
- **Regulatory Compliance**: Automated disclosure systems triggered by compliance violations
- **Research Transparency**: Conditional release of research data based on verification milestones

## Smart Contract Architecture

### Core Components

#### Disclosure Registry
- **disclosure-id**: Unique identifier for each disclosure
- **custodian**: Principal address of the disclosure owner
- **encrypted-payload**: Encrypted information content
- **monitoring-parameters**: List of conditions being monitored
- **trigger-event-count**: Number of reported violations
- **disclosure-status**: Whether information has been disclosed

#### Trigger Event System
- **Event Logging**: Immutable record of parameter violations
- **Evidence Support**: Detailed evidence submission for each event
- **Validation Process**: Authorized validator verification system
- **Threshold Monitoring**: Automatic threshold checking for disclosure

#### Access Control
- **Administrator Functions**: System-wide configuration and emergency controls
- **Validator Authorization**: Designated validators for event verification
- **Custodian Rights**: Original disclosure owner privileges

## Functions

### Public Functions

#### `register-disclosure`
Create a new disclosure with encrypted content and monitoring parameters.

```clarity
(register-disclosure 
  (encrypted-payload (string-ascii 500))
  (monitoring-parameters (list 5 (string-ascii 100))))
```

#### `log-trigger-event`
Report a violation of monitoring parameters for a specific disclosure.

```clarity
(log-trigger-event 
  (disclosure-id uint)
  (parameter-violated (string-ascii 100))
  (supporting-evidence (string-ascii 300)))
```

#### `validate-trigger-event`
Validate a reported trigger event (authorized validators only).

```clarity
(validate-trigger-event 
  (disclosure-id uint)
  (event-reporter principal))
```

#### `execute-disclosure`
Execute information disclosure when threshold conditions are met.

```clarity
(execute-disclosure 
  (disclosure-id uint)
  (decrypted-content (string-ascii 500)))
```

### Administrative Functions

#### `grant-validation-authority`
Grant validation authority to a new validator (administrator only).

#### `update-trigger-threshold`
Modify the global trigger threshold for disclosures.

#### `administrative-disclosure`
Emergency disclosure override (administrator only).

### Read-Only Functions

#### `get-disclosure-info`
Retrieve disclosure information (protects undisclosed content).

#### `get-trigger-event`
Get details about specific trigger events.

#### `get-trigger-threshold`
Get current global trigger threshold.

#### `has-validator-authority`
Check if an address has validation authority.

## Error Codes

- `u100`: Administrator-only function access denied
- `u101`: Unauthorized access attempt
- `u102`: Disclosure not found
- `u103`: Trigger threshold not met
- `u104`: Information already disclosed
- `u105`: Insufficient trigger events for disclosure

## Security Considerations

### Encryption Security
- Use strong encryption for payload data before storing on-chain
- Manage decryption keys securely off-chain
- Consider key rotation for long-term disclosures

### Validator Network
- Establish trusted validator network
- Implement validator rotation and accountability measures
- Monitor for validator collusion or compromise

### Event Verification
- Implement robust evidence verification processes
- Consider requiring multiple independent confirmations
- Establish clear criteria for parameter violations

## Deployment

1. **Contract Deployment**: Deploy the TruthGuard contract to Stacks blockchain
2. **Validator Setup**: Authorize initial set of trusted validators
3. **Threshold Configuration**: Set appropriate trigger thresholds
4. **Integration**: Integrate with frontend applications and monitoring systems

## Development

### Prerequisites
- Stacks blockchain development environment
- Clarity language understanding
- Cryptographic key management system

### Testing
- Unit tests for all contract functions
- Integration tests with Stacks testnet
- Security audits for production deployment