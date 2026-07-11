# Complete audit remediation — 2026-07-11

This historical report records the scope prepared on `agent/full-audit-remediation`. The current code and CI reports remain authoritative.

## High priority

- dedicated typed suspension-probe filtering and normal validation;
- strict lap-count admission;
- transactional runtime `CarSpecs` replacement;
- reversible same-ID track-definition commits;
- deep generated-geometry validation;
- session-time track rebuild locking;
- side-effect-free committed racing-line access.

## Medium priority

- explicit absent lap/position telemetry;
- encapsulated race-session mutable state;
- blocking pause-menu and initialization admission;
- one fatal initialization path;
- deterministic opponent RNG rollback;
- typed AI and lap-tracking fault escalation.

## Low priority

- immutable vehicle telemetry snapshots and real physics-frame regression coverage;
- repository-pinned Godot editor/template SHA-512 values;
- source-derived Windows product/file versions with preset restoration;
- corrected architecture, CI and Windows export documentation.

## Validation

The branch adds focused `audit_high_priority_contract_test.gd`, `audit_medium_priority_contract_test.gd` and `audit_low_priority_contract_test.gd` suites, checksum/export-version PowerShell preflights and compatibility updates to existing vehicle and lap-tracker tests. The required Windows workflow remains the authoritative final validation.
