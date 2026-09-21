# Security Policy

## Supported Versions

**Shift-Register Arcade** is currently in discovery / pre-release status — see [Business Requirements](./docs/BUSINESS_REQUIREMENTS.md). Development flows `develop` → `staging` → `main`; only the code on these three branches is supported, there is no long-term support for older commits.

| Branch    | Environment | GCP project          | Status                        |
| --------- | ----------- | --------------------- | ------------------------------ |
| `develop` | Development | `shift-register-arcade-dev`     | Active, default branch          |
| `staging` | Staging     | `shift-register-arcade-staging` | Active                           |
| `main`    | Production  | `shift-register-arcade-prod`    | Provisioned, not yet released    |

## Reporting a Vulnerability

This is a private repository, so please do not open a public issue for a security concern.

Instead, email **support@nelsongrey.com** with:

- A description of the vulnerability and its potential impact
- Steps to reproduce, or a proof of concept if available
- Any relevant logs, request/response samples, or affected endpoints

You should get an acknowledgement within a few business days. This is a small, pre-release project without a formal bug bounty program, but genuine reports are taken seriously and fixed promptly.

## Automated Dependency Scanning

Dependabot alerts are enabled on this repository (org default), and `.github/dependabot.yml` opens weekly update PRs for GitHub Actions, the Cloud Functions npm dependencies, and the Flutter/pub dependencies. Native GitHub secret scanning and code scanning (CodeQL) require GitHub Advanced Security, which isn't currently licensed for this org's private repositories, so neither is enabled here. Avoid committing credentials or secrets to this repo regardless — downloaded Firebase config (`firebase-config/`) is gitignored, and there are no other runtime secrets checked in.
