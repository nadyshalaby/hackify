# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Honest confidence tiers for the deterministic scanner** — `ban.bare-error` and `ban.inline-type` were labelled `confidence: exact` and the rule-catalog claimed the deterministic tier is "zero false positives," but the scanner cannot tell domain from non-domain code (bare-error) or count props (inline-type, which the rule bans only at 2+). Both are now `confidence: syntactic` — matched exactly in syntax, but a true positive needs a one-step scope/threshold check. The other 8 rules stay `exact`. Catalog, SKILL.md, and the `checks.py` docstring corrected; pinned by a `test_audit.py` case so the honesty cannot silently regress. No detection behavior changes.

### Added

- **Semantic-tier recall is now a real multi-run measurement.** Broadened the recall corpus oracle from 5 to **8 `(file, rule)` pairs across 6 concerns** (added `style.srp`, `perf.n-plus-1`, `style.ternary` via a deterministically-clean `orders.service.ts` with neutral identifiers so the blind copy leaks nothing). `score_semantic.py` now aggregates **N rounds** into a hit-rate per pair + mean recall (one file = a single illustrative read; several = variance-aware). Observed baseline (2026-06-10, 3 rounds, sonnet): 18/24 pair-runs strict, 7/8 attribution-corrected, with one **consistent real gap** — the security pass flags missing-authz on a controller mutation but misses it on a service-layer mutation (recorded in `semantic-runner.md`). The runner now also mandates handing subagents the carve-out floors (else they flag exempt files like a migration).

## [0.4.4] - 2026-06-10

> **Patch-level: measure the auditor, fix the flaky gate.** Adds the lawkeeper recall corpus — a known-oracle fixture set that converts the rulebook from *asserted* to *measured* (deterministic tier: 9/10 rules at 100% recall / 0 false positives, CI-gated; semantic tier scored on demand) — and fixes a SIGPIPE flake in DoD check `[50]` that had silently failed the first-ever CI run. Dev/CI internals only: nothing a plugin user loads or runs changes.

### Added

- **lawkeeper recall corpus** (`skills/lawkeeper/evals/corpus/`) — a synthetic project of deliberately-violating fixtures that measures the auditor's precision/recall against a known oracle, closing the "rules asserted, not measured" gap surfaced in the evaluation-coverage audit. Every planted violation carries an inline `// EXPECT:` / `// EXPECT-CLEAN:` / `// EXPECT-SEMANTIC:` marker — the self-maintaining oracle (no separate line-numbered file to rot; markers carry the bare rule_id only, so they never trip the scanner they exercise).
  - **Deterministic tier** (`run_corpus.py`, in CI): runs `audit_scan.py` and asserts findings equal the `EXPECT:` set **exactly** — today 9/10 deterministic rules at 100% recall with **0 false positives** across 7 carve-out traps (test-file waivers, non-scoped inline types, the env-name secret guard, owned/ticketed debt markers, generated/migration exemption). A `ground-truth.json` freshness check fails CI on marker drift. `ban.custom` stays covered by `test_audit.py` (needs a project `ban-patterns.txt`).
  - **Semantic tier** (`score_semantic.py` + `semantic-runner.md`, on demand): dispatches the judgment-rule subagent pass over a **comment-stripped blind copy** (so headers/markers can't leak the answers) and scores recall by `(file, rule)`. First illustrative run scored **4/5** — the lone miss being a missing-authz on a service-layer mutation — proving the harness surfaces real judgment-tier gaps. Non-deterministic, so it is out of CI and explicitly labelled illustrative (run each concern a few times for a stable number).
  - Fixtures are **never mirrored to `dist/`** (`validate-dod [55]` excludes `*/evals/corpus/*`) — shipping deliberately-broken code into the generated runtime trees would be wrong. They still live in the repo (and so in plugin caches), but carry no `SKILL.md`, so they are never loaded as a skill, and the planted secret is an inert fake literal already present in `test_audit.py`. The corpus is also exempt from a `/lawkeeper` self-audit of this repo (added to the scanner's generated-globs) and allow-listed for the ban-blocker so the on-by-default hook does not block authoring it.
- **CI step** running the corpus deterministic scorer (`.github/workflows/ci.yml`).

### Fixed

- **Flaky DoD gate `[50]`** (`scripts/validate-dod.d/50-runtimes-and-companions.sh`) — the runtime-target check piped a ~40KB `$DRY_OUT` into `grep -q`, which short-circuits on first match and closes the pipe; the upstream `printf` then took SIGPIPE and, under `set -o pipefail`, the pipeline reported non-zero even though `grep` matched — a spurious "missing dist/<runtime>/" failure. It silently failed the **first-ever CI run** (0.4.2 `a5a8972`) and surfaced locally as an intermittent "N CHECK(S) FAILED." Replaced the pipe with a here-string (no upstream producer to receive SIGPIPE). A flaky gate is itself an evaluation-integrity defect — the same class this release set out to close.

## [0.4.3] - 2026-06-10

> **Patch-level: edit-time secret blocking.** Extends the on-by-default `PreToolUse` ban-blocker to catch hardcoded secrets — `sec.hardcoded-secret`, lawkeeper's only critical-severity rule and the one deterministic check the edit-time hook did not enforce. Surfaced by auditing hackify's own principle/standards *evaluation* coverage (edit-time enforcement was a strict subset of audit-time).

### Added

- **Edit-time hardcoded-secret blocking** — the `PreToolUse` ban-blocker (`hooks/scan_edit.py` / `hooks/scan_bash.py`) now also blocks `Write`/`Edit`/`Bash` actions that introduce a hardcoded secret (AWS/GitHub/Slack/Google keys, PEM private keys, assigned `api-key`/`password`/`token` literals) into JS/TS source. `sec.hardcoded-secret` is lawkeeper's only **critical**-severity rule, yet it was the single deterministic check the edit-time hook did not enforce — so a credential could reach disk and wait for a full audit that might never run. Detection reuses `FileContext.check_secrets` (the same provider patterns, env-name carve-out, and redaction the scanner uses — single source of truth); the secret value is never echoed back in the block message. **Net-new only** for Write/Edit (a secret already on an untouched line is grandfathered) and honors the `.claude/hooks/ban-allowlist` escape hatch. Hook test suite grown 25 → 29 cases.

## [0.4.2] - 2026-06-09

> **Patch-level: the plugin-hardening pass.** Bundles edit-time ban enforcement (a new `PreToolUse` hook), the first CI gate, and two new Definition-of-Done checks that close the holes which let a stale README badge and 5 unmirrored evals ship. Areas surfaced by auditing hackify against its own doctrine.

### Added

- **`hooks/block-banned-tokens.sh` + `hooks/scan_edit.py` + `hooks/scan_bash.py`** — a `PreToolUse` (Write|Edit|Bash) hook that blocks edits **introducing** zero-tolerance banned tokens into JS/TS source: lint/type suppressions (`@ts-ignore`, `@ts-nocheck`, `eslint-disable`, `biome-ignore`; `@ts-expect-error` outside test files), non-null `!`, empty `catch {}`, and bare `throw new Error(`. **Net-new only** for Write/Edit — a banned line already present in the file (Write) or the replaced `old_string` (Edit) is grandfathered, so the hook blocks what you add, not pre-existing violations on lines you carry past untouched. **Bash coverage** — also scans source written via a heredoc or `echo`/`printf` redirect to a JS/TS file (the shell path that would otherwise bypass Write/Edit); it does NOT see content produced by `cp`/`mv`/`sed`/`awk` (not statically knowable). Detection reuses lawkeeper's tested `lexer.py` + `checks.py` regexes (single source of truth) — semantic bans are matched on lexer-MASKED text, so a token inside a string or comment never false-fires; suppressions are matched on raw text. **On by default** (claude-code only). Per-path escape hatch: list a path (literal or glob) in `<project-root>/.claude/hooks/ban-allowlist` (e.g. standalone front-end assets where a bare `Error` is acceptable). Fail-open by design: any internal failure (missing `jq`/`python3`, unparseable input) allows the edit — a hook bug must never wedge editing. 25-case test suite (`hooks/test_block_banned_tokens.sh`).
- **`.github/workflows/ci.yml`** — the first automated gate. Runs the lawkeeper scanner tests, the ban-blocker hook tests, `validate-dod.sh`, and `sync-runtimes.sh --dry-run` on every push + PR to `main`. The 0.4.0 stale badge shipped precisely because the only gate was a human running the validator locally.
- **`validate-dod` [55] mirror-completeness** (`scripts/validate-dod.d/55-mirror-completeness.sh`) — diffs `git ls-files skills/ commands/ rules/` against `MIRROR_SOURCES ∪ CLAUDE_CODE_EXTRA` (read straight from the sync manifest, not re-listed). Fails on any tracked canonical file absent from the manifest (which would ship missing from `dist/`) or any stale manifest entry. `git ls-files` (not `find`) excludes `dist/` and build artifacts for free. Regression-tested (probe file → FAIL).
- **`validate-dod` [16b] README-badge version check** — the shields.io badge must equal `plugin.json .version`; closes the unstructured-string drift the jq-only [16] check could not see.
- **`.claude/hooks/ban-allowlist`** — hackify's own dogfood allowlist, exempting the codewalk browser viewers (standalone assets, not domain code) from the bare-`Error` ban so the hook never blocks editing the plugin itself.

### Changed

- **`scripts/sync-runtimes.d/00-helpers.sh`** — fixed the bug check [55] surfaced: 5 companion-skill `evals.json` (groom, quick, review-triage, skillsmith, yolo) were tracked but never mirrored to `dist/`; added them to `MIRROR_SOURCES`. Registered the two new hook files in `CLAUDE_CODE_EXTRA`.
- **`skills/hackify/SKILL.md`** — honest runtime caveat on the "parallelism is the default" claim: on best-effort runtimes (no subagent primitive) the mandatory phases still run, but inline and sequentially — degraded concurrency, never dropped coverage.
- **`README.md`** — new **Skill routing** matrix (intent → skill, with the "audit / review / check" overlap disambiguated across all 8 skills); the hooks-primitive and repository-layout sections now document the `PreToolUse` ban-blocker; version badge → 0.4.2.

## [0.4.1] - 2026-06-09

> **Patch-level: `lawkeeper` ↔ hackify alignment polish + `validate-dod` hardening.** No workflow behavior change — voice/portability seams on the `lawkeeper` skill closed, the multi-runtime story made honest about its one host dependency, and a binary-artifact false-positive class removed from the DoD validator.

### Changed

- **`skills/lawkeeper/SKILL.md`** — documented the `python3` host dependency the Phase 2 deterministic scanner assumes (now framed as running "through the shell primitive"), with a graceful-degradation note: if `python3` is absent, report it and fall through to the interpreter-free semantic pass rather than silently skipping a whole engine. Neutral-primitive voice pass — `AskUserQuestion` → "wizard tool", matching `runtime-adapters.md`'s primitive vocabulary. Phase 5 now offers a compressed clarify→implement→verify framing for genuinely substantive fixes (file split, N+1, layering surgery) instead of folding a real structural change into an inline propose-confirm — without calling sibling skills.
- **`skills/hackify/references/runtime-adapters.md`** — new **Host-interpreter dependencies** table documenting the two skills that ship an executable engine riding the `shell` primitive (`lawkeeper`'s `python3` scanner, `codewalk`'s `node` viewer/builder), each with its stated non-silent fallback. No runtime adapter can conjure a missing interpreter, so the dependency is named rather than papered over.
- **`README.md`** — version badge corrected (was stale at `0.3.3`; the `0.4.0` release shipped without bumping it) → `0.4.1`.

### Fixed

- **`scripts/validate-dod.d/00-helpers.sh` + `10-required-files.sh`** — the token-scrub and absolute-path checks now pass `-I` to `grep` so binary files are skipped. Running `skills/lawkeeper/scripts/test_audit.py` writes `__pycache__/*.pyc` bytecode whose embedded absolute source paths were counted by `grep -c` as personal-handle / leaked-path matches — a false positive that failed an otherwise-clean tree. Binary artifacts can no longer trip these checks.
- **`.gitignore`** — added `__pycache__/` and `*.pyc` so Python bytecode never enters the tracked working tree.

## [0.4.0] - 2026-06-09

> **Minor-level scope: new `lawkeeper` skill — full-codebase engineering-rules auditor.** The detect-and-fix counterpart to a setup harness: it reads the effective rule set from a project's own harness (`.claude/rules`, `ban-patterns.txt`, `CLAUDE.md`/`AGENTS.md`) with stricter-wins fallback to global doctrine, runs a bundled deterministic scanner plus a semantic subagent pass, reports every finding with `file:line` grouped by category/severity, then fixes them one at a time with approval. Mirrored to all full-mirror runtimes.

### Added

- **`skills/lawkeeper/`** — new skill. `SKILL.md` (6-phase workflow: resolve rule set → deterministic scan → semantic pass → report → propose-confirm remediation → verify), a bundled Python scanner under `scripts/` (`audit_scan.py` CLI + `lexer.py` string/comment masker + `checks.py` exact checks + `exemptions.py` carve-out matcher + `test_audit.py` with 23 unit tests), four `references/` (rule-catalog, carve-outs, semantic-pass, porting-scanner), `assets/report-template.md`, and `evals/evals.json` (happy-path + edge + non-trigger). Deterministic checks are exact and zero-false-positive: file-line cap; lint suppressions, non-null `!`, empty catch, bare `Error`, hardcoded secrets, inline types in scoped modules; `// removed:` markers and ownerless TODO/FIXME (comment-anchored so the word inside a string literal is not flagged). The semantic subagent pass covers DRY, layering, controller-purity, naming, SRP, folder-structure, security, performance, testing, full SOLID + YAGNI, and cross-file cleanup — reusing the project's installed `.claude/agents/` reviewers when present. TS/JS core with `--text-only-ext` for any file (file-cap + project bans on non-JS) and an ephemeral on-demand scanner for deep non-JS audits. Bundled-file references use the `<skill-dir>` convention (resolved from the `Base directory for this skill:` line), never a hardcoded user path; every bundled `*.md` is ≤ 500 LOC and the scripts hold to the same caps the skill enforces (≤ 500/file, ≤ 40/function, ≤ 3 params).
- **`MIRROR_SOURCES` entries for `skills/lawkeeper/`** (`scripts/sync-runtimes.d/00-helpers.sh`) — all 12 canonical lawkeeper files explicitly enumerated so every full-mirror runtime carries the skill; `scripts/sync-runtimes.sh` mirrors them into `dist/{claude-code,codex-cli,codex-app,gemini-cli,opencode,cursor}/` (copilot-cli stays MANIFEST-only by design).

### Changed

- **`README.md`** — `lawkeeper` added to the plugin-primitives skill list, the per-skill blurb section, the command table, and the source-tree diagram.

## [0.3.3] - 2026-05-25

> **Patch-level scope: codewalk viewer follow-up — type-token hyperlinks, light-mode skipped-line legibility, clickable header breadcrumb.** Three additive fixes surfaced when actually using the v0.3.2 playbook end-to-end on a real 53-endpoint NestJS service. User-visible polish only; no schema change, no trace re-walk required.

### Added

- **`skills/codewalk/assets/viewer.js` `_byTypeName` index + `_linkTypeTokens()` Prism post-processor.** On every trace load, `_index()` now builds a PascalCase-name → node-id lookup over every node whose simple name (last `.` segment) matches `^[A-Z][A-Za-z0-9_$]*$`, preferring `layer: "type"` nodes when two layers share a name. `renderSource()` then wraps every Prism `class-name` token whose text matches a known node in a `.cw-call.cw-type-link` anchor — so a class/interface/type/DTO/Zod-schema identifier appearing anywhere in the source pane is now clickable and jumps to that node's viewer. Self-references (same node) and missing matches stay un-wrapped. Works alongside the existing line-level `call_sites[]` wrap; both can co-exist on the same line and the inner type-link wins on click (via `closest('[data-callee-id]')`).
- **`.cw-type-link` styling.** Dotted underline (vs the dashed underline used by the line-level `.cw-call`) so the user can distinguish "click this whole call-site line" from "click this one type identifier" at a glance. Color tracks Prism's `class-name` palette per theme.

### Changed

- **`skills/codewalk/assets/viewer.html` header breadcrumb is now interactive (since v0.3.3).** The previously-decorative `codewalk` span is a back-link to `../` (the playbook index), with a `← codewalk` label + hover affordance — so a user reading any per-trace viewer can one-click back to the catalog. The entry-point label (e.g., `GET /api/admin/products`) became a `<button>` that calls `select(data.nodes[0].id)` and jumps to the entry node — useful after the user has navigated several layers deep through call-site clicks and wants to reset to the root without using the Back arrow.
- **`skills/codewalk/assets/viewer.css` light-mode skipped-line styling.** The dark-mode rule applies `opacity: 0.32 + font-style: italic` to non-invoked lines; on a white background this rendered as faded grey-on-grey italic that the user reported as unreadable. Light mode now overrides with solid `color: #6b7280`, no opacity, no italic, and force-overrides every nested Prism token to the same grey via `body.cw-light .cw-line.cw-skipped .cw-line__code *` — so non-invoked branches stay legible without visually competing with the green-highlighted invoked block. The gutter line-numbers stay lighter (#c4c7cc) to preserve the invoked/skipped contrast in the gutter.

### Rationale

The v0.3.2 deep-trace mandate produced rich traces where every controller/service/repository/external boundary AND every type/interface/DTO referenced on the path emitted its own node — but the viewer only hyperlinked the FUNCTION nodes via line-level `call_sites[]` wraps. The TYPE nodes were reachable from the file tree but not from the source pane where the user actually reads them — a `ProductFilter` identifier in a method signature led nowhere. v0.3.3 closes that gap by hyperlinking at the Prism-token level so the type/class/DTO identifier the user sees in the source IS the click target. Two adjacent gaps surfaced the same session: the decorative `codewalk` breadcrumb suggested a back-link that wasn't there (the user expected to click it to return to the playbook), and the light-mode skipped-line styling was inherited from dark mode where italic+0.32-opacity is legible on `#0d0d0d` but unreadable on `#fbfbfd`. Patch-level (not minor) because every change is additive: existing v0.3.2 traces render correctly without re-walking, the breadcrumb still works without a parent playbook (404 on `../` is acceptable for one-off traces), and the dark theme styling is untouched.

## [0.3.2] - 2026-05-25

> **Patch-level scope: codewalk depth & types mandate, update-by-default, light theme by default, hackify finish hand-off.** Six additive changes to the codewalk + hackify skills, surfaced when re-running the v0.3.1 playbook against a real 53-endpoint NestJS API and finding: every trace stopped at the controller boundary (one node per slug); re-runs blind-overwrote existing files; the dark-by-default viewer didn't match the user's expectation that tooling demos open light. Backwards-compatible — single-entry and playbook traces written under v0.3.1 still load; users who prefer dark can `?theme=dark` or click the header ☾ toggle.

### Added

- **`skills/codewalk/SKILL.md` § "Depth & Completeness Mandate"** — new top-level section (between the intro and "When to invoke") that bans the failure modes the v0.3.1 audit surfaced: traces that stop at the controller, traces that gesture at "calls `service.foo`" without recursing into `foo`, type references that resolve to nothing because the type body wasn't emitted. Codifies a rough-size reference table (trivial endpoint 1-3 nodes / standard CRUD 5-10 / hot-path search 20-40 / heavy pipelines 30+) so the trace agent can self-correct when it shipped a 1-node trace for a 30-node endpoint. The 5-function depth-check pause is now explicitly **off** in playbook mode or whenever the user pre-approved depth with "all" / "every" / "deep" / "end to end" / "full" / "complete".
- **`skills/codewalk/references/data-schema.md` § "Type-definition nodes (`layer: "type"`)"** — new section documenting the sixth layer value. Type nodes share the same JSON shape as function nodes but with `invoked_lines: []`, `call_sites: []`, and `branches_not_taken: []`; they're reached via `call_sites` entries on function nodes whose `callee_id` points at the type node id, so the viewer renders the type name as a clickable cw-call span. The `layers` top-level object now requires a `type` key (array of type-node ids). The Mermaid sequence-diagram layer-name capitalization list grew to include `Type` (though type nodes generally don't appear as participants — they're referenced in message labels).
- **`skills/codewalk/assets/viewer.js` `layerClass(layer)` helper + type-aware tooltip preview.** Layer chips render in colored Tailwind pairs (`controller:sky`, `service:violet`, `repository:fuchsia`, `external:amber`, `type:emerald`, `other:neutral`) instead of the previous monochrome neutral chip. When hovering a call-site whose callee is `layer: "type"`, the tooltip body now shows the first ~6 lines of the type body alongside the docblock purpose — types ARE their declarations, so previewing them is the primary signal in the tooltip.

### Changed

- **`skills/codewalk/SKILL.md` Phase 3** — extended the node-field extraction order to include type/interface/Zod/DTO/entity emission; documented the rule that `call_sites` on function nodes must include both function-call callees AND type-reference callees so the viewer hyperlinks the type name in `data_in`/`data_out`/parameter signatures. The anti-rationalizations table grew three new rows banning shortcuts that surfaced in the audit: "Stopping at the controller is fine", "Tracing into the type definitions would bloat the trace", "I'll list `service.foo(...)` as a call_site but skip the node — they can grep".
- **`skills/codewalk/SKILL.md` Phase 4** — validation list now requires every `nodes[*].call_sites[*].callee_id` to resolve to a `nodes[].id` (no dangling links — the viewer logs a warning and renders the cw-call as un-clickable). Mentions that `layer: "type"` nodes are expected to carry `invoked_lines: []`.
- **`skills/codewalk/assets/index.html`** — the per-trace code-pane header now shows the layer-colored chip next to the function name (was: only in story-mode); the chip uses `layerClass(currentNode?.layer)` so dark + light themes pick up the right pair.
- **`skills/codewalk/assets/viewer.css`** — added per-layer light-mode color overrides (`bg-sky-900/40` → light sky, `text-violet-200` → deep violet, etc.) so layer chips stay legible on the white background. Dark palette unchanged.
- **`skills/codewalk/SKILL.md` frontmatter `description`** — workflow shape clause updated to mention "deep depth-first walk to leaves (controller → service → repository/external + every type/interface/DTO/Zod schema crossed on the path)"; locked-contract clause says "the trace is deep-by-default" + "include every type definition referenced on the path as a separate type-layer node" + "never collapse a sub-path because 'it's a service / repo / external client'".

### Added (continued)

- **`skills/codewalk/SKILL.md` "Locked Contract" callout at the top of the body.** Six numbered rules the trace agent reads before anything else: deep-by-default, types-as-nodes, no dangling links, update-existing-not-overwrite, light-mode default, stop-on-ambiguity. Plus a "your trace is REJECTED if …" acceptance checklist (1-node trace for non-trivial endpoint, dangling callee_id, missing type node for referenced shape, etc.). The callout exists so future trace agents can self-reject without the user catching the failure.
- **Phase 4 Step 4.0 — "Update existing trace by default".** When `/codewalk` is re-invoked for an entry whose `.codewalk/<slug>/data.json` already exists, the skill loads the previous file, runs the fresh deep walk, preserves manual edits to `docblock.purpose` / `docblock.ownership` / `risk` / `branches_not_taken[].name` where `function_range` is unchanged, replaces the live fields (source / invoked_lines / call_sites / data_in / data_out / git_blame), sets `previous_generated_at`, and populates `diff_vs_previous` (added_nodes / removed_nodes / signature_drift / new_side_effects). The viewer's amber diff callout becomes the standard surfacing for re-traces. The user must type "regenerate" or "fresh" to opt INTO a blind overwrite.
- **`skills/codewalk/assets/build-playbook.mjs` idempotency guard.** The catalog-driven builder no longer clobbers existing rich `data.json` files (≥2 nodes) when running without a `_traces.json`. Previously a re-run of the builder would replace every walked trace with a 1-node stub — the v0.3.1 playbook rebuild lost ~800 nodes the first time we ran it after dispatching deep agents. Now the builder skips slugs whose `data.json` already carries ≥2 nodes and no fresh entry in `_traces.json` is present.
- **`skills/hackify/SKILL.md` + `references/finish.md` Step D.5 — Codewalk follow-up at end of task.** When Phase 6 Finish archives a work-doc whose change-set touched an entry-point file (controller / CLI command / Inngest function / UI action / route handler — detected by file-pattern match against `*.controller.ts`, `*.cli.ts`, `inngest/*.ts`, `app/**/route.ts`, etc.), hackify asks the user via `AskUserQuestion` whether to update an existing `.codewalk/<slug>/` trace, create a new codewalk for the touched entry, or skip. On Update/Create, invokes `/codewalk <entry-point>` immediately. Skip silently when no entry-point files were touched.

### Changed (continued)

- **Viewer default theme flipped dark → light.** `viewer.js` now boots with `theme: 'light'`; the body class is preset to `cw-light`; `index.html` Mermaid init flips its `wantsDark` check accordingly. `localStorage["codewalk-theme"]` still persists user overrides. The header toggle still works — ☾ switches to dark. Existing v0.3.1 traces continue to honor a user's stored `codewalk-theme=dark` preference; new users see light first.

### Rationale

A user re-ran the v0.3.1 playbook against their 53-endpoint NestJS service and found that every slug's `data.json` had exactly 1 node — the controller method itself. The trace agent had treated "trace this endpoint" as "show me the entry point", not as "walk the full call stack". The schema permitted depth; the SKILL.md description didn't insist on it. v0.3.2 closes that gap by making depth-by-default + type-as-node a **non-negotiable** contract surface, with a sized expectation table the agent can self-check against. Two adjacent gaps surfaced in the same session: blindly overwriting an existing `data.json` on re-run destroyed manual edits and the diff signal, and the dark-by-default viewer didn't match user expectations for tooling demos; both got their own additive fix. Hackify's Phase 6 Finish now closes the loop by asking, after every shipped task that touches an entry-point file, whether to update the corresponding codewalk trace — turning the codewalk catalog from a one-time artifact into a continuously-refreshed team mental model. Patch-level (not minor) because every change is additive: existing 1-node v0.3.1 traces still load, the viewer is still functional without `layer: "type"` nodes, and a stored dark-theme preference is honored.

## [0.3.1] - 2026-05-25

> **Patch-level scope: codewalk skill upgrades.** Three additive changes to the `/codewalk` skill, surfaced after dog-fooding it against a real 53-endpoint NestJS API. All changes are backwards-compatible — existing `.codewalk/<slug>/` traces keep working; the dark theme stays the default. No changes to other skills, hooks, validators, hard-caps, agents, or rules. Bumping minor isn't warranted — the contract grows, no surface narrows.

### Added

- **`skills/codewalk/assets/playbook.html` + `playbook.js` + `playbook.css`** — new playbook mode for multi-entry codewalks. Light-mode-first index page that lists every traced entry in a service, grouped by domain, with a live filter input, method-color chips (`GET`/`POST`/`PATCH`/`PUT`/`DELETE`/`SSE`/`CLI`/`JOB`/`UI`), and a one-click theme toggle. Each row links into its sibling slug folder's per-trace viewer in a new tab, propagating the theme via `?theme=light|dark` so the viewer opens in the same mode. Catalog-driven: reads `.codewalk/_catalog.json` at runtime.
- **`skills/codewalk/assets/build-playbook.mjs`** — new catalog-driven builder. Reads `.codewalk/_catalog.json` (and optional `_traces.json`), copies the playbook + per-trace viewer assets to disk, and writes one `<slug>/data.json` per catalog entry. When `_traces.json` carries a rich entry for a slug, that entry's nodes/edges populate the per-trace viewer directly; otherwise the slug gets a stub `data.json` that the user can deepen later with `/codewalk <entry>`. Single file, 198 LOC, under the cap.
- **Light-mode viewer support in `assets/viewer.css`, `assets/viewer.js`, `assets/index.html`.** Toggle in the per-trace viewer header (☀/☾). Theme precedence: URL `?theme=light|dark` → `localStorage["codewalk-theme"]` → default `dark`. Persistent across reloads via `localStorage`. Prism stylesheet (`#cw-prism-css`) and Mermaid (`theme: 'default'` vs `'dark'`) swap in lockstep. Dark mode stays the default — no behavior change for users who don't touch the toggle.
- **`skills/codewalk/references/data-schema.md` § "Playbook mode — multi-entry catalog"** — documents the new `_catalog.json` and optional `_traces.json` formats with field-by-field schemas, slug rules, color palette, and builder invocation. Legacy `endpoints` is accepted as an alias for `entries` in the catalog.
- **`skills/codewalk/SKILL.md` § "Playbook mode — multi-entry codewalks"** — full workflow shape (Phase 1' → 7'), the "single-entry vs playbook" decision table, file-map update with the four new asset files, and the rule that playbook mode only fires on explicit triggers ("all endpoints", "every endpoint", "index playbook", "browse all routes"). Single-entry mode remains the default.

### Changed

- **`skills/codewalk/assets/viewer.js` HTML entity decode in `renderSource`.** Source strings authored by sub-agents and round-tripped through JSON often carry `&lt;`, `&gt;`, `&amp;`, `&quot;`, `&#39;` instead of their literal characters (typically when the agent inlined TypeScript generics or JSX in a JSON code block). Previously these reached Prism un-decoded and rendered as visible entity text in the viewer's source pane. A new `decodeEntities()` helper runs before Prism highlighting; safe because the source is rendered, not executed.
- **`skills/codewalk/assets/viewer.js` dangling-`callee_id` guard in `renderSource`.** Call sites whose `callee_id` doesn't resolve to a node in `data.json` now render as plain text instead of a broken-link `cw-call` span. The console-warning in `_index` (pointing the trace author at the missing node) is unchanged. Fixes a viewer dead-click on stub data.json files where the controller references a service that isn't yet walked.
- **`skills/codewalk/assets/index.html` Prism stylesheet now has `id="cw-prism-css"`** so the viewer can swap dark→light at runtime. Mermaid initialization now reads the same theme signal at boot (URL param OR localStorage) so the first render lands in the correct theme without a flash.

### Rationale

Three improvements surfaced in one session of dog-fooding `/codewalk` against a NestJS API with 53 endpoints. The playbook mode + builder are the headline — single-entry codewalks scale poorly past ~10 entries because there's no top-level index to navigate from, and operators were stitching their own index together by hand. The light-mode + entity-decode + dangling-callee fixes are smaller-surface but all came from the same session, so they ship together rather than spread across three patch releases. Patch-level (not minor) because every change is additive: dark mode is still default, the schema is opt-in (only fires when the user authors a `_catalog.json`), and existing `.codewalk/<slug>/` folders keep loading exactly as before.

## [0.3.0] - 2026-05-22

> **Minor-level scope.** Six plugin enhancements ship together: file-size cap validator, sync-runtimes prune-on-mirror with modular per-runtime emitters, two-channel marketplace (`hackify` stable tag + `hackify-edge` main), `scripts/release.sh` tag-on-version-bump helper, sibling-plugin collision-detection script wired as a soft warning, eval coverage for the six non-hackify skills, and a README version-label drift sweep. Closes six known gaps in one release. Tagged via the new `scripts/release.sh` — eating own dog food.

### Added

- **`scripts/validate-dod.d/80-file-size-caps.sh`** — new validator module that enforces the project-agnostic ≤500 LOC hard cap across `skills/`, `agents/`, `rules/`, `scripts/`, `hooks/`, `commands/` for every `*.md`, `*.sh`, `*.json` file. Closes the v0.2.7-retrospective gap where the rules said one thing (≤500 LOC) and the validator enforced another (nothing). The check fails red on any over-cap file; the orchestrator at `scripts/sync-runtimes.sh` was split first to pass its own check (was 528 LOC; now 94 LOC orchestrator + 7 per-runtime emitters of 35-68 LOC each + 199 LOC shared helpers, all under cap).
- **`scripts/validate-dod.d/90-collisions.sh`** — new validator module (soft warning, never fails) that invokes `scripts/check-collisions.sh` and reports any sibling-plugin slug substring overlaps as yellow `WARN` lines. Soft on purpose: a hostile or unrelated sibling plugin must never break our CI.
- **`scripts/check-collisions.sh`** — new standalone script that scans installed Claude Code plugins under `~/.claude/plugins/cache/` (overridable via `CLAUDE_PLUGINS_ROOT` env var), extracts every `name:` frontmatter value from sibling `SKILL.md` files, and reports `EXACT MATCH` / `SUBSTRING OVERLAP` / `OK` per hackify slug. Handles four empty-state branches gracefully (missing plugins root, empty cache, zero SKILL.md, malformed frontmatter) — always exits 0.
- **`scripts/release.sh`** — new tag-on-version-bump helper. Reads `version` from `.claude-plugin/plugin.json` (prefers `jq`, falls back to `grep`), refuses on dirty working tree, refuses if tag `v<version>` already exists locally OR on origin, refuses on missing/empty `version` field, creates annotated tag at HEAD with message `Release v<version>`, prompts before pushing main + tag. Supports `--dry-run` to print planned commands without executing. On push failure: leaves the local tag in place and prints a `git tag -d` rollback hint.
- **`scripts/sync-runtimes.d/`** — new directory holding the per-runtime emitter modules + shared helpers. `00-helpers.sh` (199 LOC) exports `MIRROR_SOURCES`, `CLAUDE_CODE_EXTRA`, `RUNTIMES`, plus the helper surface (`red`/`green`/`yellow`, `write_or_announce_copy`, `write_or_announce_heredoc`, `mirror_canonical_files`, `prune_runtime_dist`, `print_runtime_summary`). Seven per-runtime modules (`claude-code.sh`, `codex-cli.sh`, `codex-app.sh`, `gemini-cli.sh`, `opencode.sh`, `cursor.sh`, `copilot-cli.sh`) each define an `emit_<runtime>` function with only runtime-specific install-notes prose — no duplicated mirror/prune/summary logic.
- **`skills/groom/evals/evals.json`, `skills/skillsmith/evals/evals.json`, `skills/review-triage/evals/evals.json`, `skills/codewalk/evals/evals.json`, `skills/yolo/evals/evals.json`, `skills/quick/evals/evals.json`** — eval coverage for the six non-hackify skills. Each file follows the exact schema of `skills/hackify/evals/evals.json` (`skill_name` + `evals[]` with `{id, name, prompt, assertions[].text, files}`). Three cases per skill: happy-path trigger, edge trigger, explicit non-trigger (proving the auto-discovery boundary).

### Changed

- **`scripts/sync-runtimes.sh` split into orchestrator + per-runtime modules.** Was a 528-LOC monolith (over the cap). Now a 94-LOC orchestrator that sources `scripts/sync-runtimes.d/00-helpers.sh` + the seven per-runtime emitter modules and dispatches each. Behavior is identical: 270 files mirrored across 7 runtimes; idempotent on second run; `--dry-run` flag preserved. Spot-checked byte-for-byte against the pre-split tree.
- **`scripts/sync-runtimes.sh` now prunes `dist/<runtime>/skills/` before each mirror** via `prune_runtime_dist` called at the start of every per-runtime emitter. Renaming or removing a source skill no longer leaves stale destination directories — the v0.2.9 rename surfaced this when 18 leftover dirs from old slugs (`brainstorm`, `writing-skills`, `receiving-code-review`) needed manual cleanup. With prune-on-mirror, that's gone for good.
- **`.claude-plugin/marketplace.json` rewritten as two channels.** Entry one (`hackify`) pins `ref: v0.3.0` — the stable tagged release recommended for production users. Entry two (`hackify-edge`) keeps `ref: main` — bleeding-edge, for early adopters who want to test pre-release features. Both reference the same source URL. Tag-on-version-bump discipline (via `scripts/release.sh`) keeps the stable channel current.
- **`README.md` version-label drift sweep.** Eight in-prose `(v0.2.2)` / `v0.2.0 ships` / `(v0.2.0) sprint vocabulary` / `v0.2.2 \`UserPromptSubmit\` hook` labels reframed to `(since vX.Y.Z)` framing — preserves introduction-version provenance without implying current-version. Current-version surface is now limited to the version badge, the Install snippet, and the `plugin.json` link.

### Rationale

Six distinct gaps shipped together because each had a small surface and they share a verify-and-tag cycle. The file-size cap had been a v0.2.7 retrospective follow-up; without it the cap doctrine was advisory-only. The sync-runtimes prune-on-mirror was a v0.2.9 retrospective follow-up; without it every source-side rename leaked stale dirs that local-dev installs would ship to consumers. The marketplace tag-pin was a v0.2.8 gap surfaced when consumers asked how to pin to a release — `ref: main` was always bleeding-edge with no opt-out. The collision-detection script was the natural complement to the v0.2.9 rename — proving the rename worked AND giving consumers a tool to spot future collisions. Evals for the six non-hackify skills filled a measurement hole — only `hackify` itself had eval coverage before this release. The README label sweep ended the long-running pattern of `(v0.2.2)` reading like "current version 0.2.2" to casual readers. `scripts/release.sh` makes the tag-on-version-bump discipline executable rather than a doc-only checklist — and v0.3.0 itself was tagged with it, dog-fooding the new tool.

## [0.2.9] - 2026-05-22

> **Companion-skill rename pass.** Three companion skills are renamed to avoid auto-discovery substring collisions with the Anthropic Superpowers plugin and other third-party skill packs that ship near-identical slugs. No behavior change to any skill, workflow phase, sub-agent contract, hard-cap, hook wiring, or DoD-validator check — only the slugs, their directory paths, and every cross-reference to them moved. `codewalk` is unchanged (already hackify-distinctive).

### Changed

- **`skills/brainstorm/` → `skills/groom/`** (Socratic pre-task refinement). Frontmatter `name:` updated, `# Brainstorm` heading rewritten to `# Groom`, `Brainstorm Provenance` work-doc block renamed to `Groom Provenance`, slash trigger `/brainstorm` → `/hackify:groom`. Auto-discovery trigger list drops the bare `brainstorm` substring and adopts `groom` (sprint-vocab fit alongside the existing `Sprint Backlog` / `Daily Updates` / `Sprint Review` labels in work-docs).
- **`skills/writing-skills/` → `skills/skillsmith/`** (meta-skill that authors hackify-conformant skills). Frontmatter `name:` updated, `# Writing-Skills` heading rewritten to `# Skillsmith`, slash trigger `/writing-skills` → `/hackify:skillsmith`. Bare `writing-skills` substring dropped from auto-discovery.
- **`skills/receiving-code-review/` → `skills/review-triage/`** (per-finding reviewer-response decision table). Frontmatter `name:` updated, `# Receiving-Code-Review` heading rewritten to `# Review-Triage`, slash trigger `/receiving-code-review` → `/hackify:review-triage`. Bare `receiving-code-review` substring dropped from auto-discovery.
- **Cascading cross-reference updates across active files** — `README.md` (Companion-skills bullets, Slash-commands table, Repository layout, Plugin-primitives skill list), `scripts/sync-runtimes.sh` (`MIRROR_SOURCES` array + 6 install-note paragraphs), `scripts/validate-dod.d/50-runtimes-and-companions.sh` (`NEW_SKILL_FILES` + `NEW_SKILL_SLUGS`), and `hooks/inject-hard-caps.sh` (one comment line). The legacy-pattern phrase `plan/spec/brainstorm/execute/verify/review/finish ceremony` in `skills/hackify/SKILL.md` is intentionally preserved — it names the historical multi-skill pattern hackify replaces, not our renamed skill.

### Rationale

The `brainstorm`, `writing-skills`, and `receiving-code-review` slugs were generic enough to substring-collide with Anthropic's Superpowers plugin and other third-party skill packs. When two plugins offer auto-discovery-triggered skills with overlapping substrings, the harness has no deterministic tiebreaker — invocation depends on plugin load order or description-field ranking, neither of which is portable across runtimes. The rename moves all three to hackify-distinctive slugs that signal craft (`skillsmith`), sprint vocabulary (`groom`, `review-triage`), and consequently de-collide with any plugin's generic naming. Archived work-docs under `docs/work/done/` and pre-v0.2.9 CHANGELOG entries retain the original names verbatim — they are a frozen historical record and re-writing them would violate the work-doc immutability convention.

## [0.2.8] - 2026-05-22

> **New companion skill: `codewalk`.** Interactive call-stack viewer for code you didn't write — a senior-peer walkthrough of one execution path from a single entry point (route, handler, CLI command, queue job, UI action), rendered as a GitHub-PR-style three-pane app under `.codewalk/<slug>/` in the target repo. Bundled viewer assets (Tailwind + Alpine + Prism + Mermaid via CDN) plus a Node-stdlib server with a cross-platform fallback chain. No behavior change to any existing skill or workflow phase.

### Added

- **`skills/codewalk/SKILL.md`** — new top-level companion skill. Phase 1-7 workflow (confirm entry → read repo conventions → depth-first walk → emit `data.json` → materialize viewer by copying assets → launch `node serve.js` → 5 comprehension questions + decisions checklist). Mandatory 5-function depth-check block printed to chat. Auto-discovery triggers: `/codewalk`, `walk this code`, `walk me through`, `trace this call stack`, `trace this flow`, `explain this flow`, `what happens when`, `onboard me to`, plus six more substring matches. On ambiguity (env flags, feature gates, tenant guards, DI tokens, dynamic dispatch) the skill STOPS and asks rather than guessing the runtime path. Self-contained — never calls other skills.
- **`skills/codewalk/references/data-schema.md`** — exact JSON contract between trace and viewer (nodes, edges, layers, diagrams, deferred_branches, diff_vs_previous). Slug convention is documented per entry-point shape: HTTP routes → `<method-lowercase>-<path-sanitized>`, CLI commands → `cli-<sanitized>`, queue jobs → `job-<queue>-<job-name>`, UI actions → `ui-<component>-<action>`.
- **`skills/codewalk/references/trace-rubric.md`** — how to walk the stack with rigor. Covers invoked-block identification (the hardest field — only lines that fire on this path), side-effect classification (`db` / `queue` / `http` / `cache` / `auth` / `fs`), picking the one risk per node, branches-not-taken listed by name and never expanded, and the procedural format for the depth-check block.
- **`skills/codewalk/assets/{index.html, viewer.js, viewer.css, serve.js}`** — bundled viewer template copied per trace into `.codewalk/<slug>/`. Three-pane layout (file tree by visit order with function-count badges / code viewer with green-border invoked lines + dimmed-italic skipped lines + clickable call-site anchors + hover docblock tooltip / right-rail metadata pane). Diagrams tab renders a Mermaid sequence diagram by architectural layer, module-dependency map, data-shape evolution chain, invariants per boundary, failure modes with blast radius, deferred branches, and an amber diff banner when `data.json` re-trace differs from the prior run. `serve.js` picks a free port starting at 8765 using only Node stdlib, opens the default browser cross-platform; fallback chain to `python3 -m http.server`, `python -m http.server`, `npx serve`, `php -S`, `ruby httpd` is documented when Node is missing.

### Changed

- **`README.md`** — version badge synced to `0.2.8`. "Plugin primitives" sentence and "Companion skills" section now enumerate `codewalk`. Companion-skills heading no longer carries the `(v0.2.0)` suffix since the section now spans v0.2.0–v0.2.8 introductions. Slash-commands table gains a `/codewalk` row. Repository-layout block adds `skills/codewalk/` with its `references/` and `assets/` children. FAQ gains a codewalk entry (offline behavior + repo-source isolation). Troubleshooting table gains three codewalk-specific rows (Node missing → fallback chain, viewer doesn't open → copy URL manually, port range exhausted → kill range or edit `START_PORT`).

### Fixed

- **`README.md`** — pre-existing v0.2.4 oversights swept up while integrating codewalk: `skills/yolo/` is now listed in the repository-layout block, the "Plugin primitives" sentence now enumerates `yolo`, and the line `Both skills auto-trigger from natural-language prompts` now reads `All three skills auto-trigger from natural-language prompts` (the table above had grown from two to three flows when yolo shipped). Overview paragraph now mentions `/hackify:yolo` alongside `/hackify:quick` instead of introducing yolo cold further down the page.

## [0.2.7] - 2026-05-21

> **Patch-level scope, patch-level label.** Two oversized reference files split into per-topic subdirs, all cross-references migrated, and Phase 6 gains a mandatory pre-archive cleanup sweep. No phase, wizard, sub-agent contract, hard-cap, hook-wiring, or DoD-validator behavior change — the substrate stays identical; only file layout and one new Phase 6 step move.

### Changed

- **`skills/hackify/references/parallel-agents.md` (1783 LOC) split into 12 files under `skills/hackify/references/parallel-agents/`.** Each sub-topic (orchestration, dispatch model, file allowlists, wave structure, sub-agent contract, review parallelism, failure handling, etc.) becomes its own file under the new subdir. The old monolithic file is deleted with no forwarding stub — consumers update their cross-refs to the new paths.
- **`skills/hackify/references/clarify-questions.md` (639 LOC) split into 10 files under `skills/hackify/references/clarify-questions/`.** Same pattern: each question category becomes its own file under the new subdir, monolithic file deleted with no forwarding stub.
- **11 cross-references migrated** across consuming files (skills, agents, validator modules) to point at the new subdir paths; 1 fix-up applied to `agents/spec-reviewer-dependencies.md`. No reader follows a broken link after the split.
- **`scripts/sync-runtimes.sh`** — `MIRROR_SOURCES` extended with 22 new entries (12 + 10) covering every file under the two new subdirs. New ATTENTION-future-maintainers header comment explains that `MIRROR_SOURCES` is enumerated (not glob-discovered) so future file additions must be appended explicitly. Idempotent regen now mirrors 270 files across 7 runtimes (was 150).
- **`scripts/validate-dod.d/20-templates.sh`** — checks `[9]`, `[13]`, and `[14]` rewired to iterate the new `parallel-agents/` and `clarify-questions/` subdirs instead of grepping the deleted monolithic files. Same assertions, new traversal target.

### Added

- **Phase 6 cleanup step (Step C.5) — new mandatory pre-archive sweep.** Covers 8 cleanup classes before the work-doc is archived: stale cross-refs, broken anchors, TODO without owner, empty directories, dead branches, scope creep, surfaced dead code, and work-doc path drift. Applied to this very sprint's Phase 6 as proof-of-concept; the sweep is now part of every future task's Phase 6.

### Rationale

`parallel-agents.md` and `clarify-questions.md` had grown past the 500 LOC hard cap, with `parallel-agents.md` at 3.5× the cap and `clarify-questions.md` at 1.3×. Both files mixed many sub-topics that readers consult independently, so the natural split was per-topic subdirs rather than arbitrary line-count chunks. Behavioral guarantees preserved — 7-section sub-agent contract, 4-section wizard contract, lint-suppression carve-out tokens, hook wiring, hard caps — all unchanged. The Phase 6 cleanup step closes a recurring failure mode where finished sprints left stale cross-refs, empty dirs, or surfaced dead code in the tree because the finisher had no checklist to sweep against.

## [0.2.6] - 2026-05-21

> **Patch-level scope, patch-level label.** Tech-neutral rewrite plus four-principles integration. No phase, wizard, sub-agent contract, hard-cap, hook-wiring, or DoD-validator behavior change — the substrate stays identical; the prose substrate becomes runtime-agnostic and the doctrinal core becomes explicit.

### Added

- **`rules/four-principles.md`** — new canonical always-on rules file enumerating the four principles that gate every substantive turn: **Think Before Coding**, **Simplicity First**, **Surgical Changes**, **Goal-Driven Execution**. Attributed to Andrej Karpathy's framing. Sits alongside `rules/hard-caps.md` and `rules/code-quality.md` as the third always-on engineering law; the hard caps and code-quality rules operationalize these four principles, and the workflow phases enforce them. Canonical home — other files link here rather than restating the principle bodies.
- **`skills/hackify/references/anti-patterns.md`** — new polyglot reference with at least six wrong-vs-right worked examples covering the failure modes the four principles guard against (assumption-skipping, speculative abstraction, scope creep, drive-by edits, premature optimization, hidden coupling). Each example is paired so reviewers can cite a concrete contrast when flagging a finding.
- **Work-doc per-task `→ verify: <check>` suffix.** `references/work-doc-template.md` Sprint Backlog rows gain a SHOULD-suffixed `→ verify: <check>` clause so each task carries its own acceptance signal inline — the Phase 4 verifier reads the suffix rather than reverse-engineering intent from the task body.

### Changed

- **Pure-abstract neutralization pass across `rules/`, `agents/`, `skills/`, and `README.md`.** Ecosystem brand names stripped from prose in favor of role nouns — `linter`, `test runner`, `package manager`, `type checker`, `formatter`. The lint-suppression scan-target tokens carved out — those literal directive strings stay as-is because the rule that bans them must name them. `CHANGELOG.md` historical entries also carved out — prior versions retain their original wording.
- **Behavioral guarantees preserved.** Phase structure, the Wizard contract, the 7-section sub-agent contract, the hard caps (40 LOC / 3 params / 3 nesting / 500 LOC), hook wiring (`UserPromptSubmit` injects `rules/hard-caps.md`), and the DoD validator's check set all unchanged. Reviewers verifying upgrades read the same surface they read on `0.2.5`; only the prose substrate moved.
- **`scripts/sync-runtimes.sh` `MIRROR_SOURCES` extended** with the two new canonical files (`rules/four-principles.md` + `skills/hackify/references/anti-patterns.md`) so all seven runtime distributions under `dist/<runtime>/` ship them. Direct corollary of the two new files above; idempotent regen confirmed at 150 files across the 7 runtime targets.

### Rationale

The v0.2.5 surface had two latent fragilities. First, the prose hard-coded a single runtime's tool names in places where role nouns would have done the same job — every new runtime adapter inherited that drift and had to be re-scrubbed. Second, the doctrinal core of hackify ("think before you code, ship the minimum, change only what was asked, drive every line to the stated goal") lived implicitly across `skills/hackify/SKILL.md`, `rules/code-quality.md`, and the reviewer prompts, with no canonical home. v0.2.6 promotes that doctrine to `rules/four-principles.md` so it can be cited, audited, and extended in one place, and finishes the runtime-agnostic prose pass so the substrate is portable to any AI coding tool that honors the four primitives.

## [0.2.5] - 2026-05-16

> **Patch-level scope, patch-level label.** Closes two v0.2.4 retrospective follow-ups in one commit. No behavior change to any skill or workflow phase.

### Added

- **`scripts/gen-demo-gif.py`** — new Python+Pillow generator for the README hero GIF. Renders a 1200×675, 7-frame, 600 ms/frame animation showing the 6-phase pipeline (1 Clarify → 2 Plan → 3 Implement → 4 Verify → 5 Review → 6 Finish) with sequential phase highlight. Requires Pillow (`pip install Pillow>=10`). Run with `python3 scripts/gen-demo-gif.py [output_path]` — defaults to `docs/assets/hackify-demo.gif`. Solves the "no source committed" problem the v0.2.1 → v0.2.4 GIF transition hit.
- **`scripts/validate-dod.d/*.sh`** — 8 new modules (`00-helpers.sh`, `10-required-files.sh`, `20-templates.sh`, `30-version-and-summary.sh`, `40-quick-skill.sh`, `50-runtimes-and-companions.sh`, `60-primitives.sh`, `70-invariants-and-new.sh`) sourced in order by the orchestrator. Each module is well under the 500 LOC hard cap; `00-helpers.sh` exports all shared color printers + `check_*` helpers used by the 34 check groups distributed across the 7 check modules.

### Changed

- **`docs/assets/hackify-demo.gif`** — regenerated. The title label is now just `Hackify` (the explicit `v0.2.1` version overlay is removed) so future version bumps no longer require a GIF refresh unless phases or install commands change.
- **`scripts/validate-dod.sh`** — rewritten as a thin orchestrator (≤60 LOC, was 723 LOC). Responsibilities reduced to: define `REPO_ROOT` / `FAILED` / `DOD_MODULES_DIR`, `cd` to repo root, explicitly `source` each of the 8 `scripts/validate-dod.d/*.sh` modules in lexicographic order, print the final summary line. No `shellcheck disable` directives — modules are sourced by explicit path, not by glob.

### Rationale

The v0.2.4 retrospective surfaced two follow-ups: refresh the README hero GIF (drifted to a stale `v0.2.1` label) and split `scripts/validate-dod.sh` past the 500 LOC hard cap. Both ship here as pure housekeeping in one commit — no skill content changes, no plugin contract changes, no auto-discovery behavior changes. The GIF now has a committed source script, so future regenerations are reproducible; the validate-dod script no longer violates its own hard cap.

## [0.2.4] - 2026-05-16

> **Patch-level scope, patch-level label.** Adds a new sibling skill `/hackify:yolo` (full-autopilot mode) and a one-sentence exploration nudge to quick mode. No phase change to full or quick.

### Added

- **`skills/yolo/SKILL.md`** — new full-autopilot sibling skill. Same workflow phases as `/hackify:hackify` (Clarify with exploration, in-chat Plan, Spec-review, parallel Implement, Verify, Multi-reviewer, Finish) but two gates auto-pass: Phase 2 plan sign-off and Phase 6 4-options finish menu. The in-chat plan block (assistant message) replaces the on-disk work-doc as the Phase 2.5 / Phase 5 reviewer audit subject. Phase 5 multi-reviewer findings auto-fix in-place at every severity (Critical AND Important); Minor findings logged to chat (no Retrospective doc exists). Phase 6 default is commit to current branch locally, no push — user inspects with `git log -1` / `git diff HEAD~1` afterward. Auto-discovery triggers include `/hackify:yolo`, `yolo`, `just do it`, `don't ask me` and 7 other autonomy phrases — the canonical list lives in `skills/yolo/SKILL.md` frontmatter. No work-doc → no pause/resume across sessions.
- **`scripts/sync-runtimes.sh`** — `MIRROR_SOURCES` array gains the entry `"skills/yolo/SKILL.md"` so the new skill mirrors into all 7 runtime distributions.
- **`scripts/validate-dod.sh`** — two new check groups. Check `[34]` validates `skills/yolo/SKILL.md` exists, has `name: yolo` frontmatter matching the slug regex, has `description:` frontmatter, and the body contains the 10 required tokens (`Phase 1`, `Phase 2.5`, `Phase 3`, `Phase 4`, `Phase 5`, `Phase 6`, `in-chat plan`, `auto-pass`, `commit to current branch locally`, `no work-doc`). Check `[35]` validates `skills/quick/SKILL.md` contains the verbatim string `read it end-to-end before judging ambiguity`. A new positive-match helper `check_token_present` (mirror of the existing `check_no_token` shape) is added and reused by both check groups.

### Changed

- **`skills/quick/SKILL.md`** — the Phase 1 row in the "Kept phases" table gains a bolded sentence: `**If the ask names a file or symbol but not a fix, read it end-to-end before judging ambiguity.**` No other change to quick mode.
- **`skills/hackify/SKILL.md`** — the "When to invoke" section gains a new bullet introducing YOLO as the full-autopilot alternative alongside the existing Compressed-flow alternative.
- **`README.md`** — hero callout "Two flows, one discipline" rewritten to "Three flows, one discipline"; the flow comparison table gains a `Hackify YOLO` row between the existing Full and Quick rows; a new `### YOLO mode` subsection describes when to use YOLO and the no-work-doc trade-off; the slash-command reference table gains a `/hackify:yolo <ask>` row.

### Rationale

Full hackify and quick mode together left a middle-ground gap: substantive tasks where the user trusts the pipeline and doesn't want to gate on plan sign-off or the finish menu, but still wants spec-review, parallel implementation, and multi-reviewer rigor. YOLO fills it. The auto-fix-Critical contract is deliberate — the user opted into autopilot; surfacing findings mid-flow would defeat the purpose. The "When NOT to use YOLO" table flags auth/crypto/migration/secret as the load-bearing carve-out where auto-fix is risky. The quick-mode exploration nudge is unrelated and small: it tells the AI to read a named file end-to-end before judging ambiguity, addressing a quiet failure mode where the AI guessed at intent instead of consulting the file the user named.

## [0.2.3] - 2026-05-16

> **Patch-level scope, patch-level label.** Quick mode is now user-locked. Workflow phases are unchanged; only one runtime contract — auto-fallback — is removed.

### Changed

- **`skills/quick/SKILL.md`** — quick mode is now user-locked. Once `/hackify:quick` is invoked (explicitly or via auto-discovery), it stays in quick mode for the entire task. Promotion to full hackify requires an explicit user phrase: `switch to full`, `go to full mode`, `promote to full`, `/hackify:hackify`, `do full review`, `run Phase 5`, or `run multi-reviewer` (case-insensitive, scanned in the most recent user message only). The promotion procedure (write work-doc from accumulated context, hand off to full hackify Phase 2, preserve intent + partial diff in Daily Updates) is preserved verbatim under the new section heading "Promotion to full hackify (user-initiated only)" — only the trigger surface changes from automatic to manual.
- **`skills/quick/SKILL.md`** frontmatter description — the "Falls back to full hackify automatically on any of 4 testable signals" sentence replaced with a "User-locked mode" sentence stating quick mode stays in quick mode until the user explicitly promotes; also documents non-resumability (no work-doc → no pause/resume across sessions). The auto-discovery routing guidance ("Do NOT auto-fire on cross-file refactors, redesigns, debug…") is preserved — it controls which skill the harness picks when no slash command is typed, not the runtime fallback contract.
- **`skills/hackify/SKILL.md`** line 17 — the cross-reference to quick mode's fallback signals replaced with `stays in quick mode until you explicitly switch to full hackify`.
- **`README.md`** lines 28 and 95–104 — fallback-trigger paragraph and 4-row trigger list replaced with a "User-initiated promotion to full hackify" subsection listing the explicit promotion phrases.

### Removed

- **Four auto-fallback signals from `/hackify:quick`** — (a) implementation-attempt counter reaching 2, (b) `(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u | wc -l > 3`, (c) `grep -iE 'auth|crypto|migration|secret|token|password'` against touched paths, (d) most-recent-user-message scan for `Phase 5` / `multi-reviewer` / `do full review`. Triggers (a)–(c) are removed entirely; (d) is preserved as an explicit user-initiated promotion phrase, no longer described as a fallback.
- **Scratch `.quick-<slug>.md` attempt-counter file** — no longer created; the attempt counter is gone.
- **Anti-rationalization rows** in `skills/quick/SKILL.md` that referenced fallback triggers ("It's only one file, no need to check the diff scope" / "Attempt 2 failed but I have a great idea for attempt 3" / "The diff touches an `auth_helper.ts` file but it is just a comment edit") — removed; one replacement row added stating quick mode never auto-promotes.

### Rationale

The 4-signal auto-fallback was intended as a safety net but conflicted with user-stated intent: when a user explicitly invokes `/hackify:quick`, they have opted into a single-session, no-work-doc, no-resume flow and expect the AI to comply for the duration of the task. Silently switching modes mid-task violated that contract. The carve-out routing list in the skill description (which steers auto-discovery toward full hackify for cross-file refactors / redesigns / auth-crypto-migration work) remains the safety net at the routing layer, before quick mode is ever invoked.

## [0.2.2] - 2026-05-14

> **Patch label, refactor + additive scope.** Removes the prompt-based smart router that picked between full hackify, quick, and brainstorm — routing is now handled entirely by each skill's frontmatter `description` field via the harness's native auto-discovery. In its place, hackify graduates to a four-primitive plugin layout: `skills/` (workflows), `rules/` (always-on engineering law), `agents/` (formal sub-agent definitions), `hooks/` (UserPromptSubmit reminders). Each primitive owns the concern it is best at — and ONLY that concern. The hook is explicitly NON-routing: it injects `rules/hard-caps.md` into context every prompt, never classifies full vs quick from prompt content. Moving the classifier into the hook would just relocate the problem; this release deletes the classifier instead.

### Why

The v0.2.1 smart-router classifier was a custom prompt-content matcher embedded in two SKILL files plus a shared reference. Claude Code already does this work natively via skill `description` auto-discovery. The router added a second classifier on top of the native one, doubling the surface area, requiring its own validator check, and creating an ongoing maintenance contract between three files. v0.2.2 deletes the router, sharpens the three SKILL descriptions to do the same job through harness-native means, and uses the recovered conceptual space to ship the three plugin primitives that were always implicit in hackify's design.

### Changed — Smart router removed

- **`skills/hackify/references/smart-router.md`** — **deleted.** The canonical classifier file from v0.2.1 is gone. Routing is now description-based.
- **`skills/hackify/SKILL.md`** — `## Pre-flight: smart router — pick the right flow` stub block removed.
- **`skills/quick/SKILL.md`** — same stub block removed.
- **`skills/brainstorm/SKILL.md`** — `## When to invoke` section cross-reference paragraph to the smart router removed; `## File map` reference rewritten to point at description-based routing.
- **`README.md`** — "Smart router (v0.2.1)" paragraph removed; replaced with a "Plugin primitives (v0.2.2)" paragraph that lists `skills/ rules/ agents/ hooks/ commands/` and their respective concerns.
- **`scripts/validate-dod.sh`** — check `[27]` (smart-router cross-reference) deleted in W1; a new check `[33]` (router-excision invariant) added at the tail of the script to assert the file stays deleted and neither SKILL re-introduces a link to it.

### Added — Plugin primitives at the repo root

- **`rules/hard-caps.md`** — new short always-on engineering law (~40 lines). Function/file/param/nesting caps, lint-suppression ban, no-`!` rule, no-empty-catch rule, named-types rule, single-responsibility, refuse-on-sight anti-patterns. Injected into every prompt by the new UserPromptSubmit hook so the hard caps are always loaded.
- **`rules/code-quality.md`** — relocated canonical content of the deeper SOLID / DRY / types / layering doctrine (formerly `skills/hackify/references/code-rules.md`). 231 lines, skill-loaded on demand by Phase 2.5 Reviewer B and Phase 5 Reviewer B. The legacy `references/code-rules.md` path is preserved as a 6-line forwarding stub so existing intra-skill links keep working; both paths mirror to all 7 runtimes via `sync-runtimes.sh`.
- **`agents/`** — 7 formal Claude Code sub-agent definitions extracted from the templates in `skills/hackify/references/parallel-agents.md`. Three Phase 2.5 spec reviewers (`spec-reviewer-consistency`, `spec-reviewer-rules`, `spec-reviewer-dependencies`), three Phase 5 code reviewers (`code-reviewer-security`, `code-reviewer-quality`, `code-reviewer-plan-consistency`), and one Phase 3 wave task implementer (`wave-task-implementer`). Each file has YAML frontmatter (`name`, `description`) plus the canonical 7-section sub-agent contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT — SEVERITY omitted on the implementer). claude-code-only — non-claude-code runtimes fall back to the inline templates in `parallel-agents.md`, which stays untouched.
- **`hooks/hooks.json`** + **`hooks/inject-hard-caps.sh`** — single UserPromptSubmit hook. The shell script emits a JSON envelope (`{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<rules>"}}`) so the harness treats the rules as injected context rather than a transcript message. NON-routing — the script never inspects the user prompt; it just reads `${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md`. claude-code-only.

### Changed — Skill descriptions are the new routing mechanism

- **`skills/hackify/SKILL.md`** description — sharpened (1177 chars) to enumerate broad-spectrum verbs (`add`, `build`, `implement`, `refactor`, `redesign`, `restyle`, `migrate`, `debug`, `polish`, `audit`) AND architecture/scope/security surface (`auth`, `crypto`, `migration`, `secret`, `token`, `password`, `schema`, `data model`, `API surface`, `refactor everywhere`, `across all`). Explicit "When in doubt, invoke this skill" contract preserved.
- **`skills/quick/SKILL.md`** description — sharpened (1458 chars) to lead with explicit small-fix triggers (`quick fix`, `small change`, `just fix the`, `one-line fix`, `tiny edit`, `small fix`, `small bug`, `quick patch`, `minor tweak`, `just rename`, `fix typo`); explicit non-trigger list (cross-file refactor, redesign, debug, auth/crypto/migration); four fallback signals (attempt counter, file count, security path, user-invokes-full) kept intact as post-implementation circuit breakers.
- **`skills/brainstorm/SKILL.md`** description — sharpened (1273 chars) to enumerate idea-exploration triggers (`/brainstorm`, `let's discuss`, `let's think`, `what if`, `brainstorm`, `explore the idea`, `what do you think`, `considering`, `thinking about`); explicit non-trigger rule for build verbs that route to hackify/quick directly.

### Changed — sync-runtimes + validator

- **`scripts/sync-runtimes.sh`** `MIRROR_SOURCES` appended with `rules/hard-caps.md` and `rules/code-quality.md` (mirrors to all 7 runtimes). `CLAUDE_CODE_EXTRA` appended with the 7 `agents/*.md` files + `hooks/hooks.json` + `hooks/inject-hard-caps.sh` (mirrors to `dist/claude-code/` only). Both arrays remain explicit flat enumerations, not globs.
- **`scripts/validate-dod.sh`** — gained five new checks: `[29]` rules/ existence + non-empty, `[30]` agents/ has exactly the 7 expected files with matching frontmatter `name:`, `[31]` hooks/hooks.json parses as JSON and declares `UserPromptSubmit`, `[32]` `hooks/inject-hard-caps.sh` is executable, `[33]` smart-router file stays deleted and no SKILL re-introduces a link to it.

### Migration

No migration for skill users — slash commands, descriptions, and the work-doc contract are unchanged on the user-facing surface. Plugin authors who fork hackify pick up the new four-primitive contract: `rules/` for always-on law, `agents/` for parallel-dispatch defs, `hooks/` for prompt-time reminders, `skills/` for workflows.

## [0.2.1] - 2026-05-11

> **Patch label, refactor-only scope.** Pure refactor — no new features, no bug fixes against shipped behavior. Extracts the smart-router block to a single canonical reference shared by both SKILLs, hardens two validator checks flagged in the v0.2.0 Retrospective, and honestly retires the v0.2.0 AC10 gross target as a documented incompatibility (the router block was post-v0.2.0 additive prose, not pre-existing prose, so its extraction is gross-neutral against AC10's anchor). Wins are measured in net SKILL-file line reduction (−37 / −39) and single-source-of-truth architecture for the router rules.

### Changed — Smart-router single source of truth

- **`skills/hackify/references/smart-router.md`** — new canonical reference (62 lines). Holds the H1 title, rationale paragraph, three verbatim H3 signal-group sections (`### Signal group (i) — Brainstorm triggers`, `### Signal group (ii) — Full-mode triggers`, `### Signal group (iii) — Quick-eligible`), the 5-row decision table, the explicit default-to-full fallback rule (signal-group count ≠ 1), a `## Consumers` subsection naming both SKILLs that link here, and a `## Stub template (verbatim — for T2.1 and T2.2)` subsection containing the exact byte-stable stub used in both SKILL files.
- **`skills/hackify/SKILL.md`** smart-router section replaced with a 5-line stub linking to `references/smart-router.md`. File shrinks 386 → 349 lines (−37).
- **`skills/quick/SKILL.md`** smart-router section replaced with the same byte-stable stub. File shrinks 134 → 95 lines (−39).
- **Eliminates the ~42-line near-verbatim duplication** flagged in the v0.2.0 Retrospective as documented-but-fragile. Future router-rule edits land in ONE place; both SKILLs inherit by reference.

### Changed — Validator hardening

- **`scripts/validate-dod.sh` check `[2]`** (references count) switched from hardcoded equality (`-eq 10`) to minimum threshold (`-ge 11`), closing the v0.2.0 Retrospective follow-up that flagged the `eq N` pattern as fragile across version bumps.
- **`scripts/validate-dod.sh` check `[27]`** (router classifier) rescoped: greps each SKILL for the literal repo-rooted markdown link `(/skills/hackify/references/smart-router.md)` — not the bare filename, which would leak into CHANGELOG/README/work-doc occurrences — and separately greps `references/smart-router.md` for the three exact verbatim H3 headings. Same "router is documented" invariant, new anchors aligned to the post-extraction layout.
- **Stub link path** uses the repo-rooted leading-slash form `(/skills/hackify/references/smart-router.md)` so the same byte-stable stub works from both `skills/hackify/SKILL.md` AND `skills/quick/SKILL.md` (bare relative paths break for the second consumer because the reference lives under `skills/hackify/references/`, not `skills/quick/references/`).

### Changed — v0.2.0 AC10 disposition (retired, not recovered)

- **AC10 disposition reframed honestly.** The v0.2.0 work-doc Retrospective flagged AC10's gross-20%-on-pre-existing-prose target as missed and deferred to v0.2.1. v0.2.1 reframes that disposition: the router block was post-v0.2.0 additive prose, NOT pre-existing prose, so its extraction is gross-neutral against AC10's anchor. AC10's gross target is hereby **retired as a documented incompatibility** rather than "recovered." v0.2.1's win is measured in net SKILL-file line reduction (−37 / −39 across the two SKILLs) and single-source-of-truth architecture for the router.

## [0.2.0] - 2026-05-11

> **Minor-level scope, minor-level label.** First release where the plugin source is tool-agnostic: the canonical hackify source no longer hard-codes Claude Code tool names, and a runtime-sync script emits per-runtime distributions. Ships three new skills (`brainstorm`, `writing-skills`, `receiving-code-review`), a sprint-style work-doc vocabulary, a smart pre-Phase-1 router shared by full and quick modes, wave-end persistence + pause-checkpoint behavior, and a tightened token + soft-language pass on both SKILL files. No breaking change to the workflow phases, the 7-section sub-agent contract, or the Wizard contract; archived pre-0.2.0 work-docs work without migration.

### Added — Multi-runtime support

- **Tool-agnostic prose pass on `skills/hackify/SKILL.md`.** Concrete Claude Code tool names replaced with runtime primitive names (`wizard tool` / `subagent dispatcher` / `file-read op` / `file-write op` / `file-edit op` / `search` / `shell`). Wizard contract, Template contract, and 7-section sub-agent contract tokens preserved verbatim.
- **`references/runtime-adapters.md`** — new reference. 7×8 primitive-to-native-tool mapping table plus a 3-tier (`native` / `best-effort` / `not supported`) plugin-support matrix covering Claude Code, OpenAI Codex CLI, OpenAI Codex App, Google Gemini CLI, OpenCode, Cursor, and GitHub Copilot CLI.
- **`scripts/sync-runtimes.sh`** — new script (479 lines, POSIX/macOS-portable, `--dry-run` aware, idempotent). Converts the canonical hackify source into runtime-specific plugin packages under `dist/<runtime>/`. New `dist/.gitignore` (`*` plus `!.gitignore`) keeps generated output untracked while pinning the directory shape.
- **`## Runtime primitives — where the tool names go`** — new trailing section in `skills/hackify/SKILL.md` cross-referencing `references/runtime-adapters.md` so authors land on the mapping table the first time they hit a primitive.

### Added — New skills

- **`skills/brainstorm/SKILL.md`** (97 lines) — Socratic pre-task refinement mode. Auto-discovery triggers: `/brainstorm`, "let's discuss", "let's think", "what if", "brainstorm", "explore the idea". Graduation rule: when the user signals "build this", lazily creates the work-doc with a `## Brainstorm Provenance` block and hands off to Phase 1 of full hackify. One-doc-per-task philosophy preserved.
- **`skills/writing-skills/SKILL.md`** (128 lines) — hackify-specific meta-skill for authoring new hackify-conformant skills. Bundles a 9-check self-validation checklist covering frontmatter, triggers, required sections, the 7-section sub-agent contract, the Wizard contract, OUTPUT word-caps, soft-language scan, file size, and path conventions.
- **`skills/receiving-code-review/SKILL.md`** (109 lines) — structured per-finding response. Required table columns: Finding / Severity / Decision / Evidence; Decision ∈ {`accept`, `push-back`, `defer`}. Two trigger paths: Phase 5 internal multi-reviewer findings AND external feedback paste (PR comments, Slack quotes). Critical-findings guardrail: no bare push-back without Phase 5 escalation.

### Added — Sprint-style work-doc

- **`references/work-doc-template.md`** body sections relabeled to sprint vocabulary: `Definition of Done` → `Acceptance Criteria`, `Tasks` → `Sprint Backlog`, `Implementation Log` → `Daily Updates`, `Verification` → `Sprint Review`, `Post-mortem` → `Retrospective`. New `sprint_goal` frontmatter field. Back-compat: `skills/hackify/SKILL.md` resume-mode accepts either label set, so archived pre-v0.2.0 docs in `docs/work/done/` work without migration.

### Added — Smart router

- **Pre-Phase-1 router block** added to both `skills/hackify/SKILL.md` and `skills/quick/SKILL.md`. Three signal groups: (i) brainstorm triggers, (ii) full-mode triggers (auth/crypto/migration keywords, multi-file scope keywords, architecture keywords, prompt length > 80 chars, explicit `/hackify:hackify`), (iii) quick-eligible. Default-to-full rule fires when the matched signal-group count ≠ 1.

### Added — Wave-end persistence + pause checkpoint

- **Phase 3 wave-end persistence rule.** Parent MUST update the work-doc (tick checkboxes, append a Daily Updates entry, run verification, advance `current_task`) BEFORE dispatching wave N+1. Stops the "all waves done, no work-doc updates" failure mode.
- **Pause-keyword detection** during an active wave. Trigger words: `pause`, `stop`, `exit`, `later`, `tomorrow`, `come back`, `pick this up later`. Match runs the 5-step Pause Checkpoint procedure ending with the surface text "Resume with 'continue work on <slug>'".

### Changed — Token + Haiku pass

- **`skills/hackify/SKILL.md`** Token-efficiency pass: 422 → 378 lines (T4.1, net 10.4%). Mandatory pause-checkpoint + wave-end-persistence insertion (T4.3) then added 8 lines, landing the final file at **386 lines**. Net AC10 target (≤380) missed by 6 lines because T4.3 is contract-required. Gross 20% target on pre-existing prose was deemed incompatible with AC fidelity; both gaps documented in the v0.2.0 work-doc Retrospective.
- **`skills/quick/SKILL.md`** 162 → 134 lines (net 17.3%, gross ~28 lines). Three prose-to-table conversions land most of the saving.
- **Soft-language audit** across both SKILL files: 0 matches for `if reasonable`, `consider`, `maybe`, `try to`, `usually`, `as appropriate`, `where possible` outside the Anti-rationalizations block and explicit examples.

### Changed — Validator

- **`scripts/validate-dod.sh`** extended with five new check groups: `[24]` `sync-runtimes` dry-run output; `[25]` new-skill SKILL.md presence + frontmatter + `name` regex (`^[a-z0-9-]{1,64}$`) for `brainstorm`, `writing-skills`, `receiving-code-review`; `[26]` sprint vocabulary tokens present in `references/work-doc-template.md`; `[27]` router classifier block present in both SKILL files; `[28]` pause-keyword list present in `skills/hackify/SKILL.md`.

### Fixed — Internal

- **`references/` count check** in `scripts/validate-dod.sh` updated from 9 to 10 to reflect the new `runtime-adapters.md` added by T3.2.

## [0.1.4] - 2026-05-11

> **Patch label, minor-level scope.** Two new ergonomics features ship under a patch label per release-cadence preference. No breaking change to the workflow shape or template contracts; v0.1.3 templates and wizard banks ship unchanged.

### Added — Summary table feature

- **Phase 6 Step F — Summary table.** Full hackify now ends with a concise 2-column Area/Change markdown table printed to chat AND appended to the archived work-doc under `## Summary of changes shipped`. Authoring rules + worked example in `references/finish.md`.
- **`/hackify:summary` slash command** at `commands/summary.md` — invokable any time during a task to print the current Area/Change recap on demand. Body conforms to the v0.1.3 7-section sub-agent contract (Shape B Self-checklist VERIFICATION; SEVERITY omitted as it is a generation task).
- **Phrase triggers** — saying "show summary", "summarize", "summary table", or "show me what changed" routes to the same logic as `/hackify:summary`.
- **Authoring guidance** — `references/finish.md` gains a "Summary table — authoring guidance" subsection covering Area-label rules (1–4 words, concept/theme), Change-cell rules (≤25 words, backticks for tech terms), grouping heuristics, and a 5-row worked example.

### Added — Compressed-flow `/hackify:quick` skill

- **New skill at `skills/quick/SKILL.md`** registers `/hackify:quick` as a compressed alternative to full hackify for small bug fixes, single-file edits, polish/typo work, and quick direct-effort tasks.
- **Workflow shape:** Phase 1 Clarify (full wizard if ambiguous; zero questions otherwise) → Phase 3 Implement (single agent or inline) → Phase 4 Verify (test + lint + typecheck) → Phase 6 Step F (Summary table — mandatory).
- **Skipped phases:** Phase 2 Plan+Gate, Phase 2.5 Spec self-review, Phase 5 Multi-reviewer, Phase 6 four-options finish. Phase 3b Debug-when-stuck is NOT skipped — the fallback rule below escalates to full hackify which handles Phase 3b normally.
- **Fallback-to-full-hackify** triggers (all testable predicates): (a) implementation-attempt counter reaches 2; (b) `git diff --name-only HEAD | wc -l > 3`; (c) any touched path matches `*auth*`/`*crypto*`/`*migration*`/`*secret*`/`*token*`/`*password*`; (d) user prompt during the task contains `Phase 5`, `multi-reviewer`, or `do full review`. Fallback procedure writes a work-doc from accumulated context and re-enters full hackify Phase 2.
- **Single-implementation-agent cap** — quick mode dispatches at most one implementation subagent. Needing parallel agents is a fallback signal.

### Changed

- **`skills/hackify/SKILL.md`** Phase 6 section gains explicit Step F (Summary table) between Step E and the section trailer; "When to invoke" section gains a one-line carve-out pointing readers at `/hackify:quick` for small tasks.

### Validator

- **Checks `[18]`–`[23]` added** to `scripts/validate-dod.sh`: `[18]` `commands/summary.md` exists with `description:` frontmatter and `Area`/`Change` body tokens; `[19]` SKILL.md Phase 6 section contains `Summary table` and references `/hackify:summary`; `[20]` `references/finish.md` contains the Summary-table authoring subsection with `| Area |` worked-example header; `[21]` `skills/quick/SKILL.md` exists with `name:` (regex `^[a-z0-9-]{1,64}$`) and `description:` frontmatter; `[22]` quick-mode SKILL.md contains `Skipped phases` and the 4 skipped-phase tokens (Phase 2, Phase 2.5, Phase 5, four-options); `[23]` quick-mode SKILL.md contains `Summary table` (mandatory step is documented).

## [0.1.3] - 2026-05-11

> **Patch label, minor-level scope.** Despite being a patch release, this is a substantial rewrite of every sub-agent prompt and every clarify-wizard bank in the plugin. The label reflects the maintainer's release-cadence preference, not the underlying change size. Users upgrading from 0.1.2 should expect templates to look different — the workflow phases and DoD shapes are unchanged.

### Closed — the six canonical bugs from the v0.1.0 post-mortem

1. **Soft severity language let unverifiable schema findings get downgraded.** Reviewer A flagged `"source": "."` as "Important — may break under future schema tightening." That qualifier let it be deferred. Result: v0.1.0 install rejected; v0.1.1 + v0.1.2 reshipping cost.
2. **No cross-file consistency requirement in author prompts.** The README author agent had no rule binding its hero tagline to the `plugin.json` / `marketplace.json` descriptions. Phase 5 caught the four-way drift after the fact.
3. **No inline verification scripts in many templates.** Agents reported "done" without running the checks that would have caught their own gaps (evals.json contamination almost shipped).
4. **No anchored severity rubrics.** "Mark Critical / Important / Minor" without anchored examples produced inconsistent reviewer outputs.
5. **No placeholder syntax for dispatch-time values.** Each dispatching call handwrote paths and constraints; drift between calls was inevitable.
6. **Research-phase prompts didn't verify the architectural behaviors the plan depended on.** The "commands inside a plugin are namespaced" property wasn't asked about explicitly — only Phase 2.5 caught it.

### Added

- **`references/parallel-agents.md` "Template Contract" preamble** — canonical 7-section structure (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY [review-only] / OUTPUT). Every sub-agent template in the file conforms. ROLE has 5 mandatory elements: identity + seniority, domain expertise, named standards (cited from a version-pinned allowlist — OWASP Top 10 2021, NIST SP 800-63B, RFC 6749, RFC 7519, WCAG 2.2 AA, SOLID, Clean Code, Conventional Commits 1.0.0, Semantic Versioning 2.0.0, Keep a Changelog 1.1.0, ISO 8601, Postel's law, expand-then-contract migrations), rejected anti-patterns (≥3), behavioral bias (`Bias to:` / `Bias against:`). VERIFICATION comes in two shapes: Executable bash for filesystem-touching templates, Self-checklist yes/no list for prose-producing ones.
- **`references/clarify-questions.md` "Wizard Contract" preamble** — canonical 4-section structure for every task-type bank (SCENARIO / COMPOSITION / QUESTIONS / EXIT CRITERIA). Recommended-first rule documented (option A suffixed " (Recommended)"). Decision-rule COMPOSITION replaces free-choice "use judgment" guidance.
- **`{{snake_case}}` placeholders** for every dispatch-time runtime value. Placeholders are documentation to the dispatching agent (not the sub-agent); a sub-agent receiving literal `{{...}}` text is a dispatch bug.
- **Verbatim canonical SEVERITY line** in every review template: "If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important."
- **`scripts/validate-dod.sh`** extended with six new checks: [9] template structural conformance, [10] SEVERITY conditional (review templates have it, build/research don't), [11] canonical SEVERITY phrase, [12] ROLE 5-element substance check, [13] no leaked absolute paths in template bodies, [14] wizard structural conformance. Existing checks [1]–[8] unchanged.

### Changed

- All 11 sub-agent templates in `references/parallel-agents.md` rewritten to the 7-section contract: Phase 1 Research, Phase 2.5 Spec-review A/B/C, Phase 3 Implementation wave, Phase 3b Debug evidence, Phase 4 Cross-package verification, Phase 5 Multi-reviewer A/B/C, Phase 5 Code-review escalation. Six are review/audit templates (SEVERITY mandatory); four are build/research (SEVERITY omitted); Code-review escalation is a single-specialist review (SEVERITY mandatory).
- All 7 clarify wizard banks in `references/clarify-questions.md` rewritten to the 4-section contract: Universal preamble, feature, fix, refactor, revamp/redesign, debug, research.
- The escalation reviewer in `references/review-and-verify.md` rewritten to the 7-section contract.
- `skills/hackify/SKILL.md` adds two short cross-references pointing readers at the Template Contract and the Wizard Contract; no other content drift.

### Migration notes (for users running 0.1.2)

- Existing in-flight work-docs need no migration — the workflow shape is unchanged.
- Custom sub-agent prompts in user projects can adopt the 7-section contract incrementally. Running `bash scripts/validate-dod.sh` from the plugin source after editing surfaces the same checks the plugin's own templates pass.

## [0.1.2] - 2026-05-11

### Fixed

- `marketplace.json` plugin source switched from `github` type (which delegates to the user's local git protocol — SSH by default for many setups) to the explicit `url` type with an HTTPS clone URL. Public-repo HTTPS clones need no SSH key or GitHub auth, so the plugin now installs for any user who can `git clone https://github.com/nadyshalaby/hackify.git` from their machine. Resolves "Permission denied (publickey)" install errors on machines without GitHub SSH access.

### Added

- README "Troubleshooting" section covering the three most common install failures: source-type rejection (fixed in 0.1.1), SSH host-key prompts (one-liner with `ssh-keyscan`), and SSH auth errors (the protocol switch shipped in 0.1.2).

## [0.1.1] - 2026-05-11

### Fixed

- `marketplace.json` `plugins[0].source` was set to the bare string `"."`, which the current Claude Code plugin-marketplace schema rejects with "This plugin uses a source type your Claude Code version does not support." Replaced with the documented typed-object form `{"source": "github", "repo": "nadyshalaby/hackify"}`. `/plugin install hackify@hackify-marketplace` now succeeds against the published GitHub repo.

## [0.1.0] - 2026-05-11

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
