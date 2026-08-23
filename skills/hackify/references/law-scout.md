# Law-scout (deterministic engineering-law scan)

A predictable scan that surfaces **engineering-law violations** in the code this sprint touched, keyed to the stable `rule_id`s in [lawkeeper's rule catalog](../../lawkeeper/references/rule-catalog.md). Run by the parent at fixed points in the workflow; its output feeds the Phase 5 address-all decision table and Reviewer B (quality & layering).

Sibling protocol to [perf-scout.md](perf-scout.md). Same contract, different law: the perf-scout finds `perf.*` waste, the law-scout finds `ban.*` / `cap.*` / `sec.*` / `clean.*` rule breaks. Both feed the same decision table.

## WHAT

- **Deterministic finder.** Same files in, same findings out. The mechanical tier is lawkeeper's tested scanner (`skills/lawkeeper/scripts/audit_scan.py`), not a hand-derived grep. Every finding carries `rule_id, category, severity, confidence, file, line, end_line, message, fixable, snippet`. The last three were emitted for releases while this line still named seven fields, and `end_line` is the one check `[80b]` reads to compare the scanner against `wc -l`.
- **A bundled script, not a skill call.** Hackify stays self-contained: it runs a **file inside this plugin** by path, the same way it reads `rules/performance.md` by path. It does NOT invoke the lawkeeper skill, does not depend on a sibling plugin being installed, and does not enter lawkeeper's report-and-approve workflow. Running it sits outside the three-tier skill-call rule in [SKILL.md](../SKILL.md) entirely, because no skill is invoked.
- **Scoped to the diff, always.** Whole-codebase sweeps stay lawkeeper's job (`/hackify:lawkeeper`). The scout only ever looks at files this sprint touched, so a legacy repo does not drown a new feature in inherited findings.
- **Candidates, not verdicts, for the two syntactic rules.** `ban.bare-error` and `ban.inline-type` are matched exactly but need a one-step scope check (is the throw in domain code, does the type have 2+ props). Everything else is `confidence: exact`, the match IS the violation.

## WHEN

| Run point | Scope | What happens with findings |
|---|---|---|
| **Phase 3, every wave-end** | Union of the wave's file allowlists, before tasks tick | Trivial fixes inside the wave's allowlist land in-wave (mark `fixed`); everything else is `staged` |
| **Phase 5, start** | The whole sprint diff (`git diff --name-only <base>..HEAD`) | Staging table handed to Reviewer B as `{{law_scout_report}}`; `staged` rows join the address-all decision table |
| **quick (5-lite mirror)** | Touched files, before the single-lens review | Resolved in the same pass; the quick lens carries the law lens too |
| **yolo (mirror)** | Same two points as full hackify | Findings enter yolo's address-all loop, auto-fixed at every severity |

The write-time ban hook (`hooks/block-banned-tokens.sh`) already blocks some of these tokens *as they are typed*, but only for net-new lines in JS/TS files. The scout is what catches everything the hook cannot see: file-size caps, inline types, ownerless debt markers, `// removed:` leftovers, project `ban-patterns.txt` lines, non-JS stacks, and any file written by a tool the hook does not intercept. Running both is not redundant.

## HOW

```bash
# 1. Build the scoped path list for this run point.
git diff --name-only "<base_sha>..HEAD" > "$SCOUT_PATHS"          # Phase 5 start
# ... or the union of the wave's file allowlists, one path per line, at wave-end.

# 2. Run the bundled scanner over ONLY those paths.
python3 "<plugin-root>/skills/lawkeeper/scripts/audit_scan.py" "<project_root>" \
  --paths-from "$SCOUT_PATHS" \
  --max-file-lines "<project cap, default 500>" \
  --ban-patterns "<project_root>/.claude/hooks/ban-patterns.txt" \
  > "$SCOUT_REPORT"                          # ban-patterns: omit the flag if the file is absent

# 3. Reconcile the coverage BEFORE reading a single finding.
python3 - "$SCOUT_REPORT" <<'RECONCILE'
import json, sys
report = json.load(open(sys.argv[1]))
stats, handed = report['stats'], report['config']['scoped_paths']
drops = sum(v for k, v in stats.items() if k.startswith('paths_') and k != 'paths_unaccounted')
covered = stats['files_scanned'] + stats['files_skipped'] + drops
print(f"{covered}/{handed} paths accounted, {stats['paths_unaccounted']} unaccounted")
RECONCILE
```

Resolve `<plugin-root>` from the `Base directory for this skill:` line surfaced when hackify loads, then walk up two levels from `skills/hackify/`. Pass `--text-only-ext .py --text-only-ext .go` (etc.) for a mixed repo, those files get the file-line cap and the project's own bans only, so the JS checks cannot misfire on other syntax.

**Reconcile before you trust the result.** `stats.paths_unaccounted` must read 0, and `files_scanned + files_skipped +` the four `paths_*` drop buckets must add up to `config.scoped_paths`. A non-zero drop bucket is normal and expected (`paths_not_found` counts files the diff deleted, `paths_unsupported` counts every path whose extension the scanner does not read); a shortfall in the total is not. Treat any shortfall as MISSING COVERAGE, say so in the staging table, and re-run with the gap closed. A scan that quietly covered less than the diff it was handed reports as clean, and that is precisely how a scoped-path bug once survived a whole sprint.

**Non-JS stacks.** The bundled scanner's full check suite is ECMAScript-family only. On a Python / Go / Rust / Java project the deterministic tier covers the file-line cap plus the project's `ban-patterns.txt` through `--text-only-ext`, and the semantic tier below carries the rest. Say so in the staging table rather than reporting a thin scan as a clean one.

**If `python3` is absent**, rare on a dev machine, possible on a locked-down runtime: record `deterministic tier unavailable (no python3)` as a staging row and run the semantic tier only. The semantic lenses are interpreter-free. Never drop the mechanical tier silently, a scan that skipped an engine without saying so reads as "clean" when it is not.

## The semantic tier (what greps cannot see)

The scanner deliberately stops where precision needs a parser or real understanding. Those rules are Reviewer B's job in Phase 5, and the quick lens's job in 5-lite. Reviewer B already owns DRY, layering, size caps, and dead code; the law-scout adds the lenses lawkeeper covers that no hackify reviewer owned before. Each cites its `rule_id` from the catalog:

| Lens | rule_ids | What it looks for in the touched files |
|---|---|---|
| One construct per file | `scope.one-construct`, `scope.one-component`, `folder.one-component` | A type, enum, constant, config, schema, or style map declared in an implementation file instead of its dedicated `*.types` / `*.constants` / `*.config` / `*.schema` / `*.styles` file; two components in one file |
| Folder conformance | `folder.placement`, `folder.type-home`, `folder.entity-uniqueness` | A new file placed against the project's documented topology; a duplicate entity/model class name |
| Controller purity | `scope.controller-purity`, `scope.re-export` | A request handler doing more than one service call, or a re-export from a non-canonical source |
| Single responsibility | `style.srp`, `style.naming`, `style.ternary` | A unit that needs "and" to describe it; a name that describes what-not-why; a nested or chained ternary |
| Reuse & generalization | `style.reuse`, `style.magic-literal` | A near-duplicate that should have been generalized into one shared parameterized helper; an un-named literal (honor the project's do-not-extract floors) |
| SOLID & YAGNI | `solid.ocp`, `solid.lsp`, `solid.isp`, `solid.dip`, `solid.yagni` | Stable code edited instead of extended; a speculative abstraction or an unused knob |
| Test coverage | `test.untested`, `test.edge-cases` | A service method, guard, or branch shipped by this sprint with no covering test; happy-path-only coverage |

Carve-outs are honored before anything is reported: test files, generated code, migrations, and the project's own documented exceptions (`skills/lawkeeper/references/carve-outs.md`). Flagging a documented exception teaches the user to ignore the scout.

## STAGING

Stage findings in exactly this table (append it to the work-doc section for the run point, the wave log at wave-end, the Phase 5 review section at review start):

```markdown
### Law-scout (<wave-id or phase-5>, <YYYY-MM-DD>)

| Finding | rule_id | file:line | Evidence | Proposed fix | Status |
|---|---|---|---|---|---|
| Empty catch swallows the parse error | ban.empty-catch | src/import/parse.ts:41 | `catch (e) {}` | log and rethrow as `ImportParseError` | staged |
| Service file over the line cap | cap.file-lines | src/billing/billing.service.ts:1 | 612 lines (cap 500) | split invoicing out into `invoices.service.ts` | staged |
| Inline `type` in a scoped module | ban.inline-type | src/users/users.service.ts:12 | `type CreateArgs = { … }`, 4 props | move to `users.types.ts` | fixed |
| Bare Error in a UI asset | ban.bare-error | web/src/boot.tsx:9 | throw is in presentation, not domain code | none | false-positive: not domain code |
```

- **Status** is one of `staged` / `fixed` / `false-positive: <one-line reason>`.
- **Into the Phase 5 decision table** (Finding / Severity / Decision / Evidence): Finding, file:line, and Evidence carry over; Severity maps from the catalog (`critical` → Critical, `high` → Critical, `medium` → Important, `low` → Minor), and Reviewer B may move it one level in context with the reason stated. `staged` rows enter as accept-candidates.

## TRIAGE

- **Every finding gets exactly one disposition**, `staged`, `fixed`, or `false-positive`. A finding that vanishes without a row is a protocol violation, not a judgment call.
- **Dismissing needs a one-line reason** tied to a documented carve-out or the run context (test fixture, generated file, project exception).
- **`sec.hardcoded-secret` can never be dismissed by the implementer.** It is the only catalog-critical mechanical rule. Reviewer A (security) co-signs any dismissal; in quick mode the 5-lite reviewer co-signs.
- **The two syntactic rules need the one-step check before staging.** `ban.bare-error`: is the throw in domain code? `ban.inline-type`: does the declaration have 2+ properties? Record the answer in Evidence, not the fact that you checked.
- **Fix-in-wave is allowed** only for trivial fixes inside the wave's file allowlist; mark them `fixed` with the diff in the wave log. Everything else waits for the address-all loop.
- **Pre-existing findings in touched files are in scope.** A cap break or empty catch that the sprint did not introduce, but which lives in a file the sprint edited, is a Phase 6 Step C.5 class (g) item: surface it and offer to fix so touched files end clean. Untouched files stay out of scope.

## See also

- [lawkeeper's rule catalog](../../lawkeeper/references/rule-catalog.md), the canonical `rule_id` → category / severity / engine map every ID here resolves against.
- [lawkeeper's carve-outs](../../lawkeeper/references/carve-outs.md), the exemption floors the semantic tier must honor.
- [rules/hard-caps.md](../../../rules/hard-caps.md), the always-on caps and bans the mechanical tier enforces.
- [perf-scout.md](perf-scout.md), the sibling deterministic scan, same run points, same staging shape.
- [review-and-verify.md](review-and-verify.md), the Phase 5 address-all loop the staging table feeds.
