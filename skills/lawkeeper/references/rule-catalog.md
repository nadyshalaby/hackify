# Rule catalog — rule_id → category, severity, engine, source

This is a MAP, not a copy of the laws. Each row names where the rule is actually defined
(the canonical source resolved in Phase 1) and which engine checks it. The thresholds and
ban tokens are read from those sources at audit time — never hardcoded here. If a project's
`CLAUDE.md` is silent on a rule, the global-doctrine floor applies (stricter wins).

Engines:
- **deterministic** — `scripts/audit_scan.py`, exact `file:line`. Eight rules are
  zero-false-positive (`confidence: exact`); `ban.bare-error` and `ban.inline-type` are
  `confidence: syntactic` — matched exactly in syntax, but a true positive needs a one-step
  scope/threshold check (is this domain code? does the type have 2+ props?).
- **linter** — the project's own ESLint/Biome with the cap rule configured; exact.
- **semantic** — a Phase-3 subagent that reads the code and judges (see `semantic-pass.md`).

Categories: **folder-structure**, **code-style**, **file-scoping**, **security**,
**performance**, **testing**, **cleanup**. Design principles (SOLID/YAGNI) report under
**code-style**.

## Code-Styles

| rule_id | what | severity | engine | canonical source |
|---|---|---|---|---|
| `cap.file-lines` | file over the line cap | medium | deterministic | global §2.2 / hook (≤500) |
| `cap.fn-lines` | function over the line cap | medium | linter → semantic | global §2.1 / hook (≤40) |
| `cap.fn-params` | over the parameter cap | medium | linter → semantic | global §2.1 / hook (≤3) |
| `cap.fn-nesting` | over the nesting cap | medium | linter → semantic | global §2.1 / hook (≤3) |
| `ban.suppression` | lint/type suppression in prod | high | deterministic | global §2.3 / ban-patterns.txt |
| `ban.empty-catch` | `catch {}` | high | deterministic | global §2.5 / ban-patterns.txt |
| `ban.bare-error` | `throw new Error(...)` in domain code | high | deterministic (syntactic) | global §2.5 / ban-patterns.txt |
| `ban.non-null` | non-null `!` in prod | high | deterministic | global §2.4 |
| `ban.custom` | project-defined ban-patterns.txt line | high | deterministic | project `ban-patterns.txt` |
| `sec.hardcoded-secret` | credential/secret in source | critical | deterministic | global §2.6 |
| `style.dry` | duplicated logic; existing helper exists | high | semantic | global §1.1 |
| `style.reuse` | near-duplicate that should be generalized into a shared, parameterized helper | medium | semantic | global §1.8 (reusable/generic/shareable) |
| `style.naming` | name describes what-not-why; needs a comment | low | semantic | global §1.4 |
| `style.ternary` | nested/chained ternary | low | semantic | global §1.4 |
| `style.srp` | unit does more than one thing | medium | semantic | global §1.5 |
| `style.magic-literal` | un-named string/number (honor floors) | low | semantic | workspace §6.3 |
| `solid.ocp` | stable code edited instead of extended | medium | semantic / `code-reviewer` | global §1.x SOLID |
| `solid.lsp` | subtype breaks base-type contract | medium | semantic / `code-reviewer` | SOLID |
| `solid.isp` | consumer depends on a fat interface | low | semantic / `code-reviewer` | SOLID |
| `solid.dip` | depends on concretion, not abstraction | medium | semantic / `code-reviewer` | SOLID |
| `solid.yagni` | speculative abstraction / unused knob | medium | semantic / `code-reviewer` | global YAGNI |

## File-Scoping

| rule_id | what | severity | engine | canonical source |
|---|---|---|---|---|
| `ban.inline-type` | `interface`/`type` declared in a scoped module | high | deterministic (syntactic) | global §3.1 (service/controller/routes/middleware/guard) |
| `scope.one-construct` | impl file declares a type/enum/constant/config/schema/style not in its dedicated file (broader than the deterministic `ban.inline-type` scope — covers components/pages/routes) | medium | semantic | global §3.5 |
| `scope.one-component` | 2+ components (public or private) declared in one file | medium | semantic | global §3.5 |
| `scope.layer` | layer leak (controller→DB, service→HTTP, etc.) | high | semantic | global §1.3 / workspace §5.1 |
| `scope.controller-purity` | controller does more than one service call | medium | semantic | global §3.3 |
| `scope.dead-code` | method/export/registration with zero callers | medium | semantic | global §3.2 |
| `scope.re-export` | re-export from a non-canonical source | low | semantic | global §3.4 |

## Folder-Structure

Folder rules only exist when the project documents a topology (Phase 1). With no documented
layout, skip this category and say so in the report — do not invent a structure.

| rule_id | what | severity | engine | canonical source |
|---|---|---|---|---|
| `folder.placement` | file in the wrong tier/dir vs documented topology | medium | semantic | project `CLAUDE.md` / `architecture.md` |
| `folder.type-home` | type/enum/constant/config/schema/style not in its dedicated file/dir | low | semantic | project topology / global §3.5 |
| `folder.one-component` | multi-part component not split into a `<component>/` folder | low | semantic | project topology / global §3.5 |
| `folder.entity-uniqueness` | duplicate entity/model class name | high | semantic | global §3.4 |

## Security

Deep auth/PII/SSRF analysis is delegated to the project's `security-auditor` agent when
installed; these are the built-in fallback concerns.

| rule_id | what | severity | engine | canonical source |
|---|---|---|---|---|
| `sec.hardcoded-secret` | credential/secret in source | critical | deterministic | global §2.6 |
| `sec.injection` | string-concat SQL / shell from input | critical | semantic / `security-auditor` | global §2.6 |
| `sec.authz` | route/mutation missing permission check | critical | semantic / `security-auditor` | OWASP A01 |
| `sec.input-validation` | external input unvalidated at boundary | high | semantic / `security-auditor` | global §2.6 |
| `sec.unsafe-op` | untrusted deserialization / SSRF | high | semantic / `security-auditor` | OWASP A08/A10 |
| `sec.migration` | migration not idempotent / unguarded | high | semantic / `security-auditor` | global §2.7 |
| `sec.pii-log` | PII or secret written to logs | medium | semantic / `security-auditor` | global §2.6 |

## Performance

Delegated to the `performance-auditor` agent when installed; diff/hot-path scoped by nature.

| rule_id | what | severity | engine | canonical source |
|---|---|---|---|---|
| `perf.n-plus-1` | query inside a loop / missing index | high | semantic / `performance-auditor` | data-layer practice |
| `perf.algorithmic` | O(n²) nesting / unhoisted repeated work | medium | semantic / `performance-auditor` | — |
| `perf.blocking-io` | sync I/O on request/render path | high | semantic / `performance-auditor` | — |
| `perf.memory` | unbounded cache/buffer | medium | semantic / `performance-auditor` | — |
| `perf.render` | FE re-render thrash | low | semantic / `performance-auditor` | — |

## Testing

| rule_id | what | severity | engine | canonical source |
|---|---|---|---|---|
| `test.untested` | service method/guard/logic with no test | medium | semantic | global §1.6 |
| `test.edge-cases` | happy-path-only; edge cases untested | medium | semantic | global §1.7 |

## Cleanup

| rule_id | what | severity | engine | canonical source |
|---|---|---|---|---|
| `clean.removed-comment` | leftover `// removed:` marker | low | deterministic | hook refuse-on-sight |
| `clean.debt-marker` | TODO/FIXME/HACK/XXX without owner/ticket | low | deterministic | hook refuse-on-sight |
| `clean.commented-code` | block of commented-out code | low | semantic / `cleanup-scout` | global §3.2 |
| `clean.unused-dep` | dependency imported nowhere | medium | semantic / `cleanup-scout` | global §3.2 |
| `clean.unref-file` | file imported by nothing | medium | semantic / `cleanup-scout` | global §3.2 |
| `clean.dead-flag` | feature flag defined, never read | low | semantic / `cleanup-scout` | global §3.2 |
| `clean.orphan-env` | env var validated-not-used or used-not-validated | medium | semantic / `cleanup-scout` | global §3.4 |

## Severity → handling

- **critical** — secrets, auth/permission leaks. Surface first; fix is usually urgent.
- **high** — zero-tolerance bans, layer leaks, DRY. Strong recommend-to-fix.
- **medium** — caps, SRP, placement. Fix or record a deliberate waiver.
- **low** — naming, magic literals, re-exports. Batch or defer; never auto-apply silently.
