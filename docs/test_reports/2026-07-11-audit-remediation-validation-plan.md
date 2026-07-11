# Audit remediation validation plan — 2026-07-11

The authoritative validation is the required Windows workflow on the pull-request head.

Required successful stages:

1. repository and complete-history safety;
2. Windows platform, pinned-checksum and export-version preflights;
3. localization and static architecture checks;
4. headless Godot import;
5. all recursively discovered standalone and scene tests;
6. production Windows export and PCK content inspection;
7. normal startup and production argument-isolation smoke runs;
8. packaged regression export and smoke run.

The pull request must not be merged until the current head commit reports workflow conclusion `success`.
