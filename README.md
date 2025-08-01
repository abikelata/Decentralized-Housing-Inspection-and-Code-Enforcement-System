# Decentralized Housing Inspection and Code Enforcement System

A comprehensive blockchain-based system for managing housing safety, compliance, and enforcement using Clarity smart contracts on the Stacks blockchain.

## System Overview

This system consists of five interconnected smart contracts that work together to ensure safe, compliant, and fair housing practices:

### 1. Rental Property Safety Inspection Contract (`rental-safety.clar`)
- Manages safety inspections for rental properties
- Tracks inspection schedules, results, and compliance status
- Issues safety certificates and violation notices
- Maintains inspector credentials and property records

### 2. Building Code Compliance Monitoring Contract (`building-compliance.clar`)
- Monitors construction projects for building code adherence
- Tracks permits, inspections, and compliance milestones
- Manages contractor certifications and project approvals
- Issues compliance certificates and violation penalties

### 3. Lead Paint Remediation Contract (`lead-remediation.clar`)
- Manages lead paint hazard identification and removal
- Tracks remediation projects and certified contractors
- Monitors compliance with lead safety regulations
- Issues clearance certificates upon successful remediation

### 4. Housing Discrimination Prevention Contract (`discrimination-prevention.clar`)
- Monitors rental practices to prevent illegal discrimination
- Tracks complaints and investigation outcomes
- Maintains fair housing compliance records
- Issues penalties for discriminatory practices

### 5. Affordable Housing Preservation Contract (`affordable-housing.clar`)
- Maintains existing affordable housing stock
- Prevents displacement through rent stabilization
- Tracks affordable unit compliance and renewals
- Manages preservation incentives and penalties

## Key Features

### Transparency and Accountability
- All inspections, violations, and remediation efforts are recorded on-chain
- Public access to property safety and compliance records
- Immutable audit trail for all enforcement actions

### Automated Compliance Tracking
- Smart contract automation for inspection scheduling
- Automatic penalty calculation for violations
- Compliance status updates in real-time

### Multi-Stakeholder System
- Property owners, tenants, inspectors, and regulators all participate
- Role-based permissions and access controls
- Incentive structures for compliance and reporting

### Data Integrity
- Cryptographic verification of inspection reports
- Tamper-proof violation and remediation records
- Secure storage of sensitive compliance data

## Contract Architecture

Each contract operates independently while maintaining data consistency through standardized data structures and validation rules. The system uses:

- **Principal-based access control** for role management
- **Map-based storage** for efficient data retrieval
- **Event logging** for transparency and auditability
- **Error handling** with descriptive error codes
- **Input validation** to ensure data integrity

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts: \`clarinet deploy\`

### Testing

The system includes comprehensive tests using Vitest:

\`\`\`bash
npm test
\`\`\`

Tests cover:
- Contract deployment and initialization
- Role-based access control
- Property registration and inspection workflows
- Violation reporting and remediation tracking
- Compliance monitoring and certificate issuance

## Usage Examples

### Registering a Property for Inspection
\`\`\`clarity
(contract-call? .rental-safety register-property
"123 Main St"
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX0RYC9QC6LK
u10)
\`\`\`

### Scheduling an Inspection
\`\`\`clarity
(contract-call? .rental-safety schedule-inspection
u1
'SP2INSPECTOR123
u1640995200)
\`\`\`

### Recording Inspection Results
\`\`\`clarity
(contract-call? .rental-safety record-inspection
u1
true
"Property meets all safety standards")
\`\`\`

## Error Codes

Each contract uses standardized error codes:
- \`u100-199\`: Authentication and authorization errors
- \`u200-299\`: Input validation errors
- \`u300-399\`: State validation errors
- \`u400-499\`: Business logic errors
- \`u500-599\`: System errors

## Security Considerations

- All functions include proper access control checks
- Input validation prevents malicious data injection
- State validation ensures data consistency
- Event logging provides audit trails
- Error handling prevents information leakage

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
