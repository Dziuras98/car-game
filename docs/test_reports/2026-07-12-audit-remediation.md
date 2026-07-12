# Audit remediation — 2026-07-12

This change set addresses the confirmed defects found during the repository audit:

- bounded, direction-safe AI recovery with an explicit return to forward gear;
- authoritative opponent-grid configuration validation;
- skid-mark mesh geometry refresh during runtime specs reconfiguration;
- distance and voice-budget gating for baked opponent engine audio;
- scene-root contract validation for car and track catalog entries;
- safe generated-track reuse criteria;
- retryable visual wheel binding configuration;
- removal of production-only startup readiness instrumentation;
- localized initialization-failure messages;
- minimap cache invalidation when the track transform changes.

Each behavioral change is accompanied by focused regression coverage and is validated by the canonical Windows verification and packaged-export workflows.
