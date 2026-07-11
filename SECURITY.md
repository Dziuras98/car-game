# Security Policy

## Supported versions

This project is a prototype. Security fixes are applied only to the current `master` branch unless a release is explicitly marked as supported.

## Reporting a vulnerability

Do not open a public issue containing exploit details, credentials, personal data or other sensitive information.

Use GitHub's private vulnerability-reporting flow from the repository **Security** tab and select **Report a vulnerability**. Include:

- the affected commit, branch or release;
- the affected file or subsystem;
- reproducible steps or a minimal proof of concept;
- the expected and observed impact;
- any suggested mitigation;
- whether the report includes exposed credentials or personal data.

If private vulnerability reporting is unavailable, contact the repository owner through their GitHub profile and request a private reporting channel without including technical details in the initial public message.

The maintainer will acknowledge a valid private report when it is reviewed, coordinate remediation where practical and avoid disclosing reporter information without consent.

## Secrets and credentials

Never commit passwords, access tokens, private keys, signing certificates, service-account files or local environment files. A secret found in Git history must be considered compromised and rotated before the history is rewritten.
