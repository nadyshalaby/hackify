# Law-scout (deterministic engineering-law scan)

A predictable scan that surfaces **engineering-law violations** in the code this sprint touched, keyed to the stable `rule_id`s in [lawkeeper's rule catalog](../../lawkeeper/references/rule-catalog.md). Run at fixed points in the workflow, by the wave agent over its own file allowlist and by the parent over the wider scopes; its output feeds the Phase 5 address-all decision table and the round's quality-and-layering lens, which is the merged reviewer's quality pass by default and Reviewer B when the user has asked for the panel.

Sibling protocol to [perf-scout.md](perf-scout.md). Same contract, different law: the perf-scout finds `perf.*` waste, the law-scout finds `ban.*` / `cap.*` / `sec.*` / `clean.*` rule breaks. Both feed the same decision table.

## WHAT

- **Deterministic finder.** Same files in, same findings out. The mechanical tier is lawkeeper's tested scanner (`skills/lawkeeper/scripts/audit_scan.py`), not a hand-derived grep. Every finding carries `rule_id, category, severity, confidence, file, line, end_line, message, fixable, snippet`. The last three were emitted for releases while this line still named seven fields, and `end_line` is the one check `[80b]` reads to compare the scanner against `wc -l`.
- **A bundled script, not a skill call.** Hackify stays self-contained: it runs a **file inside this plugin** by path, the same way it reads `rules/performance.md` by path. It does NOT invoke the lawkeeper skill, does not depend on a sibling plugin being installed, and does not enter lawkeeper's report-and-approve workflow. Running it sits outside the three-tier skill-call rule in [SKILL.md](../SKILL.md) entirely, because no skill is invoked.
- **Scoped to the diff, always.** Whole-codebase sweeps stay lawkeeper's job (`/hackify:lawkeeper`). The scout only ever looks at files this sprint touched, so a legacy repo does not drown a new feature in inherited findings.
- **Candidates, not verdicts, for the two syntactic rules.** `ban.bare-error` and `ban.inline-type` are matched exactly but need a one-step scope check (is the throw in domain code, does the type have 2+ props). Everything else is `confidence: exact`, the match IS the violation.

## WHEN

| Run point | Scope | What happens with findings |
|---|---|---|
| **Phase 3, the AGENT, before it returns** | That wave's OWN file allowlist, the files it landed | Trivial in-allowlist candidates are fixed in place (mark `fixed`); everything else is `staged` in the wave report |
| **Phase 3, the PARENT, every round-end** | The round-touched files (what the round's waves DECLARED under `## Paths written`, never the allowlist union), before the round commits, never before a tick | Each wave's dispositions carry forward unchanged; what the wider scope newly shows is `staged` for Phase 5, or sent back out as a one-task wave, a new finding, never an un-tick. The parent never writes the fix |
| **Phase 5, start** | The whole sprint diff (`git diff --name-only <base>..HEAD -- . ':(exclude)docs/work/*'`) | Staging table handed to the round's reviewer as `{{law_scout_report}}`; `staged` rows join the address-all decision table |
| **quick (5-lite mirror)** | Touched files, before the 5-lite review | Resolved in the same pass; that one reviewer carries the law lens too |

**Why the Phase 3 run point is BOTH the wave and the round.** The two scans answer questions the other cannot, so neither replaces it. The AGENT scan is keyed to the wave because that is the only moment fix-in-wave is possible at all: the agent is still holding its files, they sit inside its own allowlist, and a trivial fix lands in the same diff. The PARENT scan is keyed to the round because the round commits once and the parent runs its repo-wide checks once per round, so a parent scan keyed to wave-end would run before the thing it is meant to gate. Ticks are not that thing: they already landed, one at a time as each agent returned, so what this scan raises is a new finding, never an un-tick. Where a round holds two or more waves it also reaches what no agent scan can: the round's declared set is the only scope in which a defect crossing two waves is visible, because no agent can scan a file it never held. **On a single-wave round that scope reason is void**, the round's declared set IS what that one wave declared, and the mandate still holds because two questions survive the collapse. First, whether the agent ran its scan at all: the wave report is a claim, and the parent's own scan is what checks it. Second, whether a fix-in-wave regressed the file after the agent's scan had already passed: a fix-in-wave edit lands AFTER the scan that surfaced the candidate, and nothing at the agent's run point re-reads the file once it has been edited, so the agent's green grades the pre-fix state and the parent's scan is the first read of the post-fix one. Canonical statement of both run points and the loop they sit in: [phases/phase-3-implement.md](phases/phase-3-implement.md).

The write-time ban hook (`hooks/block-banned-tokens.sh`) already blocks some of these tokens *as they are typed*, but only for net-new lines in JS/TS files. The scout is what catches everything the hook cannot see: file-size caps, inline types, ownerless debt markers, `// removed:` leftovers, project `ban-patterns.txt` lines, non-JS stacks, and any file written by a tool the hook does not intercept. Running both is not redundant.

## HOW

```bash
# 1. Build the scoped path list for this run point.
git diff --name-only "<base_sha>..HEAD" -- . ':(exclude)docs/work/*' > "$SCOUT_PATHS"   # Phase 5 start
# The exclusion is the SAME literal Phase 5 builds its reviewed diff with, and it is
# not optional here. Without it the scout walks the work-doc, stages rows against a
# file no reviewer grades, and those rows rejoin the address-all table, which reopens
# the loop the exclusion exists to close. Latent only while `.md` sits outside the
# scanner's default extensions, and the `--text-only-ext .md` line below makes it live.
# ... or, at the parent's round-end run point, the round-touched files (what the round's
# waves DECLARED under `## Paths written`, never the allowlist union), one path per line.
# At the AGENT's run point it is that wave's own share of the same set: just the files
# that wave landed, inside its own allowlist and no other wave's.

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
stats, config = report['stats'], report['config']
handed, lines = config['scoped_paths'], config['listed_lines']
def family(prefix):  # sums a bucket family by name prefix, minus its own subtraction
    return sum(v for k, v in stats.items()
               if k.startswith(prefix) and not k.endswith('_unaccounted'))
# COVERED IS files_scanned AND NOTHING ELSE. It used to add `files_skipped` in, which is
# how a readable 2.3MB file 400x over the line cap reconciled as covered and reported 0
# findings. Unread is its own family now, and it is not coverage.
if not config['path_list_supplied']:
    print('whole-tree sweep, no path list handed, so both path reconciles read 0 by construction')
else:
    print(f"parse: {lines} lines in, {handed} paths out ({family('lines_')} dropped, "
          f"{stats['lines_unaccounted']} unaccounted). Equality is the check, not the subtraction.")
    print(f"scan:  {stats['files_scanned']}/{handed} paths READ, {family('paths_')} dropped "
          f"(deleted or unsupported, expected), {stats['paths_unaccounted']} unaccounted")
print(f"unread: {family('unread_')} file(s) located but never opened. Never covered, in any mode.")
RECONCILE
```

Resolve `<plugin-root>` from the `Base directory for this skill:` line surfaced when hackify loads, then walk up two levels from `skills/hackify/`. Pass `--text-only-ext .py --text-only-ext .go` (etc.) for a mixed repo, those files get the file-line cap and the project's own bans only, so the JS checks cannot misfire on other syntax.

**Reconcile before you trust the result, at BOTH stages, and read the unread bucket as neither.** The scanner loses inputs in two places and publishes a subtraction for each. The parse stage runs FIRST, so a line lost there never reaches `scoped_paths` and the scan stage then reconciles cleanly over a list that had already shrunk, which is why one number was never enough.

- **Parse stage, where equality is the check and the subtraction is not.** `config.scoped_paths +` the `lines_*` buckets (blank, comment, duplicate, malformed) must add up to `config.listed_lines`, and `stats.lines_unaccounted` must read 0. That balances perfectly for a list carrying a blank, a duplicate and a comment while three of its four lines never become paths, because each drop is bucketed. A `git diff --name-only` dump contains none of those shapes, so compare `config.listed_lines` against `config.scoped_paths` DIRECTLY: anything but equality means the list you handed in is not the list that got scanned. Check `[80b]` in this repo asserts exactly that pair.
- **Scan stage, where a non-zero drop bucket is normal.** `files_scanned +` the `unread_*` buckets `+` the four `paths_*` buckets must add up to `config.scoped_paths`, and `stats.paths_unaccounted` must read 0. `paths_not_found` counts files the diff deleted and `paths_unsupported` counts paths whose extension the scanner does not read; both are expected on a real diff. A shortfall in the total is not.
- **Unread is never covered.** `unread_too_large` (past the scanner's 2MB ceiling) and `unread_unreadable` (permissions, binary, non-UTF-8) count files that were located, were in scope, and had not one rule run against them. They balance the arithmetic and cover nothing, which is why they are their own family and not a `paths_*` bucket that every prefix-summing consumer would fold into "covered". Any value above 0, in scoped or whole-tree mode alike, is MISSING COVERAGE: name the file in the staging table, then split it or raise the ceiling and re-run.
- **A supplied path list is never a tree walk.** `config.path_list_supplied` says whether `--paths-from` was passed at all, which `scoped_paths: 0` cannot: a whole-tree sweep covers everything and a scoped run handed an empty list covers nothing, and both print 0.

Treat any shortfall as MISSING COVERAGE, say so in the staging table, and re-run with the gap closed. A scan that quietly covered less than the diff it was handed reports as clean, and that is precisely how a scoped-path bug once survived a whole sprint.

**Non-JS stacks.** The bundled scanner's full check suite is ECMAScript-family only. On a Python / Go / Rust / Java project the deterministic tier covers the file-line cap plus the project's `ban-patterns.txt` through `--text-only-ext`, and the semantic tier below carries the rest. Say so in the staging table rather than reporting a thin scan as a clean one.

**If `python3` is absent**, rare on a dev machine, possible on a locked-down runtime: record `deterministic tier unavailable (no python3)` as a staging row and run the semantic tier only. The semantic lenses are interpreter-free. Never drop the mechanical tier silently, a scan that skipped an engine without saying so reads as "clean" when it is not.

## The semantic tier (what greps cannot see)

The scanner deliberately stops where precision needs a parser or real understanding. Those rules belong to the round's quality-and-layering lens, in Phase 5 and in 5-lite alike, since both modes route to the same reviewer. That lens already owns DRY, layering, size caps, and dead code; the law-scout adds the lenses lawkeeper covers that no hackify reviewer owned before. Each cites its `rule_id` from the catalog:

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

Stage findings in exactly this table (the AGENT appends it to its own wave report under `## Scout dispositions`, the parent transcribes those rows into the wave log and appends the round-end table beside them, and at review start it goes in the Phase 5 review section):

```markdown
### Law-scout (<run-point-id>, <YYYY-MM-DD>)

| Finding | rule_id | file:line | Evidence | Proposed fix | Status |
|---|---|---|---|---|---|
| Empty catch swallows the parse error | ban.empty-catch | src/import/parse.ts:41 | `catch (e) {}` | log and rethrow as `ImportParseError` | staged |
| Service file over the line cap | cap.file-lines | src/billing/billing.service.ts:1 | 612 lines (cap 500) | split invoicing out into `invoices.service.ts` | staged |
| Inline `type` in a scoped module | ban.inline-type | src/users/users.service.ts:12 | `type CreateArgs = { … }`, 4 props | move to `users.types.ts` | fixed |
| Bare Error in a UI asset | ban.bare-error | web/src/boot.tsx:9 | throw is in presentation, not domain code | none | false-positive: not domain code |
```

- **`<run-point-id>`** names the run point that produced the table, and it is what tells two tables apart where both sit in one wave log under this same heading grammar: `<wave-id>-agent` for the wave agent's own scan over the files it landed, taking the wave id the Approach's execution-wave plan already assigns (`W9c-agent`); `R<n>-round-end` for the parent's scan over what that round's waves declared (`R9-round-end`); `phase-5` for the sprint-diff scan. Without it the round scan's first question, whether the agent ran its own scan at all, has no answer a reader can read off the log. On a single-wave round the two scopes coincide by construction and the id still earns its place, because the two SCANS do not: run point 1's green graded the pre-fix-in-wave state, and run point 2 is the first read of the post-fix one.
- **Status** is one of `staged` / `fixed` / `false-positive: <one-line reason>`.
- **Into the Phase 5 decision table** (Finding / Severity / Decision / Evidence): Finding, file:line, and Evidence carry over; Severity maps from the catalog (`critical` → Critical, `high` → Critical, `medium` → Important, `low` → Minor), and the quality-and-layering lens may move it one level in context with the reason stated. `staged` rows enter as accept-candidates.

## TRIAGE

- **Every finding gets exactly one disposition**, `staged`, `fixed`, or `false-positive`. A finding that vanishes without a row is a protocol violation, not a judgment call.
- **Dismissing needs a one-line reason** tied to a documented carve-out or the run context (test fixture, generated file, project exception).
- **`sec.hardcoded-secret` can never be dismissed by the implementer.** It is the only catalog-critical mechanical rule. The round's security lens co-signs any dismissal, and it carries over to whichever agent carries that lens: the merged reviewer's security pass, in full mode and in 5-lite alike, or Reviewer A when the user has asked for the panel. Both modes route the same way now, so there is no route where the co-signer is missing.
- **The two syntactic rules need the one-step check before staging.** `ban.bare-error`: is the throw in domain code? `ban.inline-type`: does the declaration have 2+ properties? Record the answer in Evidence, not the fact that you checked.
- **Fix-in-wave is allowed** only for trivial fixes inside the wave's file allowlist, and only at the AGENT's run point, where the agent still holds those files; mark them `fixed` with the diff in the wave report. **The parent never fixes at round-end**, it stages, or sends the work back out as a one-task wave scoped to the owning file's allowlist, because every code change is written by a dispatched agent under an allowlist. Everything else waits for the address-all loop.
- **Pre-existing findings in touched files are in scope.** A cap break or empty catch that the sprint did not introduce, but which lives in a file the sprint edited, is a Phase 6 Step C.5 class (g) item: surface it and offer to fix so touched files end clean. Untouched files stay out of scope.

## See also

- [lawkeeper's rule catalog](../../lawkeeper/references/rule-catalog.md), the canonical `rule_id` → category / severity / engine map every ID here resolves against.
- [lawkeeper's carve-outs](../../lawkeeper/references/carve-outs.md), the exemption floors the semantic tier must honor.
- [rules/hard-caps.md](../../../rules/hard-caps.md), the always-on caps and bans the mechanical tier enforces.
- [perf-scout.md](perf-scout.md), the sibling deterministic scan, same run points, same staging shape.
- [review-and-verify.md](review-and-verify.md), the Phase 5 address-all loop the staging table feeds.
