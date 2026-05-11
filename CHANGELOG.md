# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.2] — 2026-05-11

### Fixed

- `marketplace.json` plugin source switched from `github` type (which delegates to the user's local git protocol — SSH by default for many setups) to the explicit `url` type with an HTTPS clone URL. Public-repo HTTPS clones need no SSH key or GitHub auth, so the plugin now installs for any user who can `git clone https://github.com/nadyshalaby/hackify.git` from their machine. Resolves "Permission denied (publickey)" install errors on machines without GitHub SSH access.

### Added

- README "Troubleshooting" section covering the three most common install failures: source-type rejection (fixed in 0.1.1), SSH host-key prompts (one-liner with `ssh-keyscan`), and SSH auth errors (the protocol switch shipped in 0.1.2).

## [0.1.1] — 2026-05-11

### Fixed

- `marketplace.json` `plugins[0].source` was set to the bare string `"."`, which the current Claude Code plugin-marketplace schema rejects with "This plugin uses a source type your Claude Code version does not support." Replaced with the documented typed-object form `{"source": "github", "repo": "nadyshalaby/hackify"}`. `/plugin install hackify@hackify-marketplace` now succeeds against the published GitHub repo.

## [0.1.0] — 2026-05-11

### Added

- Initial public release.
- Single skill `hackify` invokable as `/hackify:hackify` after install.
- Six-phase workflow: Clarify → Plan + Gate → Spec self-review → Implement (parallel waves) → Verify → Review (parallel reviewers) → Finish.
- Per-task markdown work-doc convention at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`.
- Nine reference files covering: clarify question banks, code rules, debug playbook, finish protocol, frontend-design heuristics, TDD walkthrough, parallel-agent dispatch templates, review checklist, work-doc template.
- Optional `evals/evals.json` for use with the `skill-creator` plugin (harmless if not installed).
- Self-hosted marketplace metadata in `.claude-plugin/marketplace.json` so the plugin is installable via `/plugin marketplace add nadyshalaby/hackify` → `/plugin install hackify@hackify-marketplace`.

## Maintenance notes

- **Every release MUST bump `version` in `.claude-plugin/plugin.json`.** Claude Code uses that field to detect updates for installed users — pushing further commits without a version bump is invisible to existing installs.
- Pair every `version` bump with a new entry in this CHANGELOG and a corresponding git tag (`v0.x.y`).
- Breaking workflow changes (e.g., a renamed phase, a removed reference file, a different work-doc schema) bump the minor version while the plugin is on `0.x.y`, and the major version once it reaches `1.0.0`.
