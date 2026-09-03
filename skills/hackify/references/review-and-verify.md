# Verify & Review (Phases 4 + 5)

Phase 4 proves the **original ask** is met. Phase 5 ensures the **code is good**. Both run after the last Sprint Backlog checkbox is ticked.

---

## Phase 4, Verify (evidence ledger + three-layer re-verify)

**Rule.** Evidence before claims. Every "passes" / "done" / "works" must be backed by output you ran in THIS turn, not earlier, not remembered.

Phase 4 has three parts: an **Evidence Ledger** (prove every item landed), a **three-layer re-verify** (re-earn the proof and confirm you did not drift from the goal), and the **ship gate** (prove the app actually builds, boots, and serves the touched flow).

### Part 1, The Evidence Ledger (per-item proof)

One row per Sprint Backlog task AND per Acceptance-Criteria bullet. No item ships on a bare checkmark, each carries a real, trimmed proof sample.

| Column | Meaning |
|---|---|
| Item | Task ID (`T3`) or acceptance bullet (`AC2`). |
| Type | `task` or `acceptance`. |
| Claim | One line: what this item asserts is true now. |
| What I ran | The exact command, test, grep, or manual step that proves it. |
| Proof sample | A REAL, trimmed slice of the output, the few lines that show the pass. Never a summary, never invented. |
| Result | ✅ pass / ❌ fail. |

Worked rows:

| Item | Type | Claim | What I ran | Proof sample | Result |
|---|---|---|---|---|---|
| T3 | task | Expired tokens are rejected with 403 | `bun test invitations` | `✓ rejects expired token → 403 (4 pass)` | ✅ |
| AC2 | acceptance | Lint clean | `biome check src/` | `Checked 142 files. No fixes needed.` | ✅ |

**Ledger rules.**

- Cover EVERY task and EVERY acceptance bullet. A missing row is an unproven item, treat it as ❌.
- The proof sample is trimmed but real: copy the true lines that show the result, then cut the noise. Do not paraphrase output into prose.
- A ❌ row blocks Phase 5. Loop back to Phase 3 (or 3b if stuck).
- Each deterministic scout's staging table (or its explicit "no candidates" result) is itself a ledger row. Item `scout.perf` and `scout.law`, Type `protocol`, proof sample the trimmed table or `none` ([perf-scout.md](perf-scout.md), [law-scout.md](law-scout.md)).
- The three ship-gate rows (`ship.build`, `ship.boot`, `ship.smoke`) are mandatory in every mode, see Part 3.
- The full ledger is saved in the work-doc Sprint Review, and that is the only place it lives. The work-doc is itself the published page ([work-doc-artifact.md](work-doc-artifact.md)), so the cumulative proof is already in one place and nothing has to be re-rendered to keep it there.

The top-level triad still runs and appears as acceptance rows in the ledger:

```
- [ ] All tests pass, fresh test-command output, exit 0, 0 failures, 0 errors
- [ ] Linter clean, fresh lint output, 0 errors (warnings only if pre-existing)
- [ ] Typecheck clean, fresh typecheck output, 0 errors
- [ ] All Sprint Backlog checkboxes ticked
- [ ] No placeholders, no orphan TODOs, no debug logging left behind
- [ ] No new lint suppressions (zero tolerance)
- [ ] No new `!` non-null assertions in production code
- [ ] Manual smoke (if user opted in), steps + outcome logged
```

### Part 2, Three-layer re-verify (prove it without drifting)

Run the layers in order. Each layer can be re-run on demand, the point is that the proof survives a second, independent look, and never wanders off the goal.

**Layer 1. Fresh triad.** Re-run test + lint + typecheck from a CLEAN state (no warm cache, all packages). This is the ledger's mechanical backbone. See "Common verification failures" below for the traps.

**Layer 2. Goal-drift re-check.** Trace every ledger proof back to the goal anchor. For the **North-Star Goal** and each **Success Signal** in `## Primary Goal & Guardrails`, name the ledger row that proves it. A Success Signal with no proving row → the goal is NOT met yet. A proof that serves no In-Scope bullet → possible drift: justify it against the anchor or cut it ([goal-anchor.md](goal-anchor.md)).

**Layer 3. Independent re-prove.** Re-earn the proof WITHOUT trusting Layer 1's output. Either re-run from a clean checkout / fresh state, or dispatch a fresh foreground subagent that re-runs the ledger's commands and reports what it actually saw. If Layer 3 disagrees with Layer 1, Layer 1 was stale, investigate before advancing.

**How much to run.** Full hackify runs all three layers. quick runs Layers 1-2 (skips the heavier independent pass). Re-run any layer whenever the user asks "prove it again", that is why the layers are named.

### Part 3, The ship gate (prove it runs, not just that it compiles)

A green triad proves the code is well-formed. It does not prove the app **builds**, **boots**, or **serves a request**, and a missing env var, a broken bundler config, or a migration that never ran will pass every test you have and still ship a dead app.

Run the three legs in order and record one ledger row each. Full protocol, detection table per ecosystem, readiness-probe rules, and the secrets/state guards: [ship-gate.md](ship-gate.md).

| Leg | Row | Proves |
|---|---|---|
| 1 Build | `ship.build` | Builds clean from a cold cache, and the artifact exists on disk |
| 2 Boot | `ship.boot` | Starts, reaches a real ready signal (health endpoint / port / listening line), tears down clean |
| 3 Smoke | `ship.smoke` | The critical path this sprint touched works end to end against the running app |

**The contract: a leg is blocking whenever the diff touched something that leg's target consumes; a recorded skip otherwise; never silently skipped.** The trigger is the diff, not whether a run command exists, almost every repo has one and gating a typo fix on booting the app is how a mandatory check gets quietly disabled. A blocking build or boot command that fails is ❌ and blocks Phase 5, same as a failing test. When a leg is not triggered, or the project has no target for it (a library, a plugin repo), the row still exists and carries `⏭ skipped` plus a reason naming which manifest you read. A blank row, an `n/a`, or a missing row counts as ❌.

This gate runs in **every mode**, including quick, and takes no user opt-in. It is the difference between "the tests pass" and "you can ship this".

### How "evidence" looks

Bad:

> Tests should pass now. ✓

Good:

```
$ cd <project> && <test-runner-command>
✓ 87 pass
0 fail
Ran 87 tests across 12 files. [3.42s]
```

Bad:

> Lint is fine.

Good:

```
$ <lint-command> src/
Checked 142 files in 89ms. No fixes needed.
```

If you can't show the output, you don't know it's true. Re-run.

### Common verification failures (catch yourself)

| Failure | What to do |
|---|---|
| Output references caches / "warm" runs | Re-run from a clean state |
| One package green, another not run | Run all packages |
| Test command exits 0 but skips suites | Check the count, "0 tests ran" is a fail |
| Linter exits 0 with warnings | Confirm warnings are pre-existing; if new, fix |
| Typecheck "skipped" or "incremental" | Force fresh: delete the incremental typecheck cache if needed |

### Regression-test red-green cycle (a Layer 3 proof)

For bug fixes, prove the regression test actually catches the bug, this is an independent re-prove of the fix:

```
1. Apply your fix.        ← test passes
2. Revert the fix only.   ← test should fail (paste this output too)
3. Re-apply the fix.      ← test passes again (paste)
```

This proves the test is sensitive to the bug it claims to catch.

---

## Phase 5 (Review)

### Default: five-agent panel + self-review

For any non-trivial diff (anything beyond a one-line typo / config-only change), Phase 5 dispatches the five-agent panel as foreground reviewers in parallel in a single message, roster unchanged. The five-agent panel is Phase 5's default reviewer route in both quick and full mode, and the merged all-lens reviewer (`hackify:reviewer`) is the explicit, named, lower-cost opt-out. A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one. B carries quality/layering **and plan consistency** over one read. A is security/correctness, D is performance, F is cross-module coherence. E design-conformance is the one conditional lens, and it is omitted rather than folded when the diff has no UI surface. Cap at 5. **Use the merged reviewer, or ask for a single reviewer round, and Phase 5 dispatches it instead**, carrying every lens as five gated passes over one read of the diff. The panel table and the reason the evidence gate was retired are in [phases/phase-5-review.md](phases/phase-5-review.md). (Reviewer C folded into B in v0.13.0: both ran on every wave, so a permanent merge took a saving nothing else could reach.)

**On a panel round the scout tables split.** Two reviewers consume a deterministic scout run immediately beforehand and must re-judge every one of its rows: Reviewer B takes the law-scout table ([law-scout.md](law-scout.md)) as `{{law_scout_report}}` and cites lawkeeper `rule_id`s; Reviewer D takes the perf-scout table ([perf-scout.md](perf-scout.md)) as `{{perf_scout_report}}` and cites `rules/performance.md` catalog IDs. Every panel reviewer except B also takes `{{review_scope}}`, the git pathspec list for its lens, and diffs only that; the merged reviewer takes no scope at all, on the same argument that keeps B unsliced. **Every reviewer this phase dispatches also takes `{{plugin_root}}`**, each panel lens, the refuter behind them and the merged reviewer alike: the absolute filesystem path to the installed hackify plugin root, the directory holding `rules/` and `skills/`, and the anchor every REQUIRED READING path in those templates is built from. It never takes `none` or a blank, and the parent fills it from a path it ALREADY HOLDS, either the absolute path carried in any always-on rule injection it received this session or its own skill's base directory, never by searching the filesystem. **B is never sliced**, its semantic tier applies to every touched file and it re-judges every scout row, so no subset of the diff is safe to withhold; B takes `{{metrics_table}}` instead, so it judges precomputed size numbers rather than counting them by reading ([review-scope.md](review-scope.md)).

Reviewer F is the lens no other reviewer owns: it compares every boundary-crossing symbol's **producer** against every **consumer** for shape, semantic, error-contract, duplicate-concept, and wiring agreement. It exists because a wave's implementer writes against waves it never saw and against pre-existing code it did not write, which is precisely how two independently-correct halves of a feature end up disagreeing.

Dispatch templates: `parallel-agents/phase-5-multi-review-a-security.md`, `phase-5-multi-review-b-quality-plan.md`, `phase-5-multi-review-d-performance.md`, `phase-5-multi-review-e-design.md`, `phase-5-multi-review-f-coherence.md` for the default route, then, on request, `parallel-agents/phase-5-multi-review-merged.md`. Any other distinct concern takes a specialist from `phase-5-escalation.md` instead of E.

The self-review still happens, the parent walks the diff (`git diff <BASE_SHA>..HEAD`) and ticks each checklist item below. Note pass/fail and a 1-line note in the work-doc Sprint Review → Self-review table. **Self-review is the floor, the dispatched review round is the ceiling.** Both run for non-trivial diffs.

```
- [ ] DRY, no duplicated logic; existing helpers reused; new helpers extracted if 3+ uses
- [ ] Layering, presentation/domain/infrastructure separation honored
        Server-side: request handlers are pure delegation; services own business logic + data access; no transport-framework imports in services
        Client-side: route shells thin; features own logic; components dumb; shared lib is glue only
- [ ] Named types, every shape with ≥2 props has a named interface/type in the right folder
        Server-side: <module>/interfaces or shared common types
        Client-side: <feature>/types or shared lib types
- [ ] No lint suppressions, no linter or type-checker suppression directives
        Sole carve-out: a type-checker expect-error pragma in test files for deliberately invalid input, with WHY
- [ ] Size caps, headline: ≤40 LOC/function, ≤3 params, ≤3 nesting, ≤500 LOC/file; `rules/hard-caps.md` is canonical
- [ ] Dead code removed, no unused exports, methods, imports; no commented-out code
- [ ] Edge cases covered, null/undefined, empty arrays/strings, concurrent access, partial failures
- [ ] Naming for intent, variables/functions describe WHAT they DO, not HOW
- [ ] Error handling explicit, every path handled; no silent swallows
        Server-side: throw named domain errors from a dedicated errors module
        Client-side: throw named error subclasses with a stable name set
- [ ] No security regressions, no hardcoded secrets, no query-string concatenation against the data store, sanitized paths, validated inputs
- [ ] No new `!` non-null assertions in production code
- [ ] No empty catches, every catch either logs, rethrows, or transforms; bare `catch (e) {}` is banned
- [ ] No bare `Error` throws in domain code, domain code throws named, domain-specific error subclasses
- [ ] No query/remote call inside a loop (perf.data.*, perf.network.chatty-calls), batch or index instead
- [ ] Independent I/O parallelized; result sets, caches, and fan-out bounded (LIMIT/pagination, TTL/LRU, pool)
- [ ] No sync blocking I/O on a server path; large payloads streamed, not buffered
- [ ] One construct per file; types/constants/config/schemas/styles in their dedicated files
- [ ] Every boundary-crossing symbol agrees with its consumers on shape, units, and error contract
- [ ] Every symbol this diff added is reachable, route registered / handler subscribed / component mounted
```

### When to escalate to a reviewer subagent

Spawn a **foreground** general-purpose reviewer subagent when ANY of:

- Diff > 300 LOC
- Diff touches > 8 files
- Cross-module refactor (touches multiple bounded contexts)
- Touches **any** of: auth/permissions, cryptography, database migrations, payment/billing, public API contracts, security headers, cross-origin and request-forgery defenses, delegated-identity flows, session management
- Performance surface in dispute, a perf-scout candidate with catalog-default Critical that the implementer wants dismissed, or contested Reviewer D findings (`rules/performance.md`)
- User explicitly asked for deeper review

When you escalate, **also** complete the self-review, escalation is *additive* defense, not replacement.

### Reviewer subagent prompt template (the adjudication reviewer)

This template is the **adjudication reviewer**, the agent that reads the Phase 5 reviewer reports a wave actually produced, one merged report carrying a section per lens or, on a panel round, the reports the panel returned, and returns CONCUR or REBUT on every finding in them. The canonical sub-agent contract in `parallel-agents/template-contract.md` is 8 sections (ROLE / INPUTS / REQUIRED READING / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT), SEVERITY mandatory here because this is a review template. It carries all eight, REQUIRED READING included, anchored on `{{plugin_root}}` like every template in `parallel-agents/`; the performance catalog its METHOD rules against is bound on that list rather than merely cited, so the agent is told to open every canonical file it is told to apply.

**Fires when** finished reviewer reports are in hand and findings already filed need a verdict. Reports are its whole review input, so with none in hand it has nothing to rule on. When the diff instead needs findings nobody has filed yet, on a lens the dispatcher pins by name at fire-time, the specialist in `parallel-agents/phase-5-escalation.md` is the prompt that answers, and it takes no reviewer report at all. The triggers listed above decide whether to escalate; they never decide which of the two prompts you dispatch.

```
Subagent type: general-purpose

**ROLE**

You are a senior principal engineer with 15+ years of experience adjudicating
multi-reviewer findings in complex codebases, reconciling contradictory
review verdicts, distinguishing a real defect from a stylistic preference,
and signing off on diffs that touch sensitive surfaces (auth, migrations,
public API contracts, billing, cryptography).

Your stack expertise covers: server-side services in a strongly typed
language, relational database migrations and row-level security,
delegated-identity and session management, multi-tenant data isolation,
and cross-package monorepo refactors.

You apply SOLID, Clean Code (Martin), and the prevailing top-ten web
application security risk catalogue when the diff has a security
surface; RFC 2119 keywords when judging whether a prior reviewer's
finding is normative or advisory.

You reject: silent agreement with prior reviewers without a citation,
"looks fine" verdicts without a file:line anchor, severity downgrades
justified by author intent, unverifiable claims defended as "should work."

Bias to: citing file:line for every concur-or-rebut on a prior finding.
Bias against: paraphrasing a prior reviewer's claim without quoting it.

**INPUTS**

1. `{{work_doc_path}}`, absolute filesystem path to the work-doc
   (e.g. an absolute path ending in `docs/work/<slug>.md`).
2. `{{project_path}}`, absolute filesystem path to the project root.
3. `{{project_name}}`, string identifier for the project.
4. `{{base_sha}}`, git SHA marking the base of the diff.
5. `{{head_sha}}`, git SHA marking the head of the diff.
6. `{{diff_kind}}`, one of `feature` / `fix` / `refactor` / `redesign`.
7. `{{stack_summary}}`, one-line stack description
   (e.g. "server-side request handler + relational ORM + relational
   database" or "client-side build tool + component framework +
   component library + utility-CSS framework").
8. `{{sensitive_surfaces}}`, comma-separated list of sensitive areas the
   diff touches (e.g. "auth, migrations, public API contracts").
9. `{{reviewer_reports}}`, the verbatim text of every Phase 5 reviewer
   report produced on this wave, each labelled with the reviewer letter
   that produced it, a merged report labelled per lens section. How
   many reports arrive varies by wave and by route, so adjudicate
   however many reports arrive, never a fixed roster, and never a
   summary in place of the verbatim text.
10. `{{user_claude_md_path}}`, absolute filesystem path to the
    user-global CLAUDE.md (typically `~/.claude/CLAUDE.md`), or the
    string `none` if absent.
11. `{{project_claude_md_path}}`, absolute filesystem path to the
    project CLAUDE.md (typically `<project>/CLAUDE.md`), or `none`.
12. `{{plugin_root}}`, absolute filesystem path to the installed hackify
    plugin root, the directory holding `rules/` and `skills/`. Every
    REQUIRED READING path below is built from it.

**REQUIRED READING**.
Open every file below IN FULL before METHOD step 1. Each path is absolute, built
from `{{plugin_root}}`.
1. `{{plugin_root}}/rules/claim-integrity.md`, every CONCUR and REBUT you write
   is a claim about another reviewer's claim, and this governs what one must
   carry before you may make it.
2. `{{plugin_root}}/rules/expert-mindset.md`, how to approach the reports and the
   diff behind them before you adjudicate either.
3. `{{plugin_root}}/rules/performance.md`, the performance catalog METHOD step 6
   rules against, whose `perf.<domain>.<slug>` IDs every performance verdict you
   file keys on.
4. `{{plugin_root}}/skills/hackify/references/expert-mindset.md`, the fuller
   doctrine `rules/expert-mindset.md` names and does not itself carry: the hat
   table's QA / verifier row, whose "prove, do not claim" is the bar every
   CONCUR and every REBUT is held to, evidence re-derived over wording.

This list is EXHAUSTIVE and CLOSED. Every plugin file hackify requires of this
role is on it. Do not infer that another plugin file applies to you, do not
substitute a file you found by searching the tree, and do not treat a path cited
elsewhere in this prompt as required reading unless it also appears above: a
citation gives a finding its wording, this list is what binds you.

A path above that does not resolve is a dispatch bug and never a file to route
around. STOP before METHOD step 1, report `missing canon: <path>`, and produce no
other output.

**OBJECTIVE**

A severity-tagged adjudication report that concurs or rebuts every finding
in every supplied reviewer report, with a file:line citation per item,
and adds any net-new findings the prior reviewers missed.

**METHOD**

1. Read `{{work_doc_path}}` end-to-end. Build a mental index of every
   Definition-of-Done bullet (D1, D2, …) and every Task ID (T1, T2, …).
2. Read every report in `{{reviewer_reports}}` in full, however many
   there are. List every finding (Critical / Important / Minor) each
   reviewer raised, keyed by the reviewer letter that raised it.
   Do not summarise, keep the original wording so you can quote it
   later.
3. Run `git diff {{base_sha}}..{{head_sha}}` inside `{{project_path}}` to
   load the diff. Cross-reference every finding from step 2 against the
   actual diff hunks.
4. If `{{user_claude_md_path}}` ≠ `none`, read it. If
   `{{project_claude_md_path}}` ≠ `none`, read it. On rule conflict,
   apply the stricter rule. Note which rules apply to which findings.
5. For each finding from step 2, produce a `CONCUR` or `REBUT` verdict.
   CONCUR requires a file:line citation pointing at the offending hunk.
   REBUT requires a file:line citation pointing at the counter-evidence
   (the line that makes the prior reviewer's claim wrong) AND a one-line
   technical reason. Bare "I agree" or "I disagree" is forbidden, every
   verdict carries a citation.
6. Apply your specialist lenses to the diff to catch what the prior
   reviewers may have missed: SOLID violations, Clean Code (Martin)
   smells, when `{{sensitive_surfaces}}` mentions auth, sessions,
   tokens, crypto, or migrations, the relevant categories from the
   prevailing top-ten web application security risk catalogue, and when
   the diff touches data access, loops, hot paths, or caching, the
   performance catalog (`{{plugin_root}}/rules/performance.md`; cite
   `perf.<domain>.<slug>` IDs). Record any net-new finding with a
   file:line citation.
7. For every Definition-of-Done bullet in the work-doc, confirm the diff
   delivers it. Any DoD bullet not delivered by the diff is a Critical
   finding under "plan consistency."

**VERIFICATION**

Paste this checklist under a `## Verification` heading in your report and
answer every item yes or no. If ANY answer is "no", loop back to METHOD
before producing OUTPUT.

1. Did you read every prior reviewer report you were given, end-to-end,
   before writing any verdict? (yes / no)
2. Does every CONCUR or REBUT verdict carry a file:line citation in the
   diff? (yes / no)
3. Did you cross-reference every prior-reviewer finding against the
   actual `git diff {{base_sha}}..{{head_sha}}` output? (yes / no)
4. Did you check every Definition-of-Done bullet in `{{work_doc_path}}`
   against the diff and report any undelivered bullet as a Critical
   finding? (yes / no)
5. For every net-new finding you raised, is it grounded in a file:line
   citation rather than a general claim? (yes / no)
6. Are all Critical findings ones whose claim you verified against the
   live diff or live docs, not ones you inferred from prior-reviewer
   wording? (yes / no)
7. Did you open every REQUIRED READING path in full before METHOD step 1? (yes / no)

**SEVERITY**

- **Critical**. A defect that will ship broken work, lose data, leak
  credentials, or violate the work-doc's Acceptance Criteria if not
  fixed before merge. Anchored examples:
  - A schema field referenced in the diff cannot be verified against
    live docs or live source. Critical (uncertainty about contract
    surface is shipped-broken risk; see the canonical bug "soft severity
    language let unverifiable schema findings get downgraded").
  - Reviewer A flagged an auth-route guard as "Important" but the diff
    actually removes the guard from a route reachable by unauthenticated
    callers, escalate to Critical and cite the broken-access-control
    category from the prevailing top-ten web application security risk
    catalogue.
- **Important**. A defect that risks rework, scope drift, or quality
  regression but will not by itself ship a broken release. Anchored
  examples:
  - Reviewer B flags a helper as duplicating an existing utility and
    Reviewer F reads the same code as two deliberate module-local
    copies; the diff is correct but the duplication will surface as a
    refactor cost. Important.
  - A new public-method signature uses three positional parameters where
    a named DTO would be clearer (Clean Code (Martin), long parameter
    list); behavior is correct, design is brittle. Important.
- **Minor**. Editorial or stylistic issues that do not change behavior.
  Anchored examples:
  - Reviewer B noted a TODO comment with no owner; behavior unaffected
    Minor.
  - A variable name uses an abbreviation where the codebase convention
    is the full word; no functional impact. Minor.

If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important.

**OUTPUT**

≤300 words, terse review beats long review; longer reports get skimmed
and Critical findings get lost in prose. Use this exact report skeleton:

````
## Adjudication of prior reviewers

### Reviewer <letter> findings
- <finding wording, verbatim>. CONCUR | REBUT, <file:line>, <one-line reason>
- ...

<repeat that sub-section once per report in `{{reviewer_reports}}`, keyed
on the reviewer letter, in the order the reports were supplied. Open no
sub-section for a reviewer that did not run on this wave.>

## Net-new findings

### Critical
- <finding>, <file:line>

### Important
- <finding>, <file:line>

### Minor
- <finding>, <file:line>

## Verification
1. <yes|no>
2. <yes|no>
3. <yes|no>
4. <yes|no>
5. <yes|no>
6. <yes|no>
````

If a sub-section has no findings, write `None.` on its own line under the heading, never go silent. That binds every sub-section you opened, the fixed ones and each per-reviewer one alike, so a report that raised nothing still gets its heading and its `None.`
```

If the diff has BOTH a large security/auth surface AND a large UX/visual surface, that is two specialist lenses, not an adjudication. Dispatch `parallel-agents/phase-5-escalation.md` once per lens, with `{{specialist_lens}}` pinned to security/correctness on one and architecture/design on the other.

### Acting on reviewer feedback (the response pattern)

```
1. READ the full feedback without reacting.
2. UNDERSTAND each item, restate it in your own words. If unclear, ask
   the user (or, if reviewer is a subagent and you can re-dispatch, re-ask).
3. VERIFY against the codebase, grep for the function name, read the file,
   check whether the reviewer's claim matches reality.
4. EVALUATE, technically sound for THIS codebase? YAGNI check: grep for
   actual usage before "professionalizing" something.
5. RESPOND, technical acknowledgment OR reasoned pushback (with evidence).
6. IMPLEMENT, one item at a time. Test each. Don't bundle.
```

**Never** "You're absolutely right!" before verification. **Never** start implementing fixes before clarifying ambiguous items.

### Pushback criteria (push back when)

- The suggestion would break existing functionality.
- The suggestion is for a feature with no real consumers (YAGNI).
- The suggestion contradicts a documented architecture decision in CLAUDE.md.
- The suggestion is technically wrong for this stack/version.
- There's a reason in legacy or constraints the reviewer can't see.

On a **Critical** finding these criteria are never enough on their own. That row takes both refuter lenses, an adjudication verdict and the user's explicit sign-off before it may read `push-back` (address-all loop, step 2).

When pushing back, lead with the technical reason, not the disagreement:

> *"The reviewer suggests adding `retry` with backoff. But this is a request-scoped service inside a tenant route, retries would re-acquire the pool client, breaking `SET LOCAL search_path`. The right fix is at the caller, not in the service. Skipping."*

### Severity → action (address ALL findings)

Phase 5 addresses **every** finding, the address-all loop below drives the decision table to empty. No severity is silently deferred.

| Severity | Action |
|---|---|
| Critical | Fix now. Do NOT advance to Phase 6 until resolved. Re-run verification. |
| Important | Fix before claiming done. May extend the work-doc Sprint Backlog list (mark added tasks "review-driven"). |
| Minor | Fix too. Defer to a Retrospective follow-up ONLY with explicit user sign-off, never by default. |

### Address-all loop (drive the decision table to empty)

Modeled on the lawkeeper fix-loop. The exit condition is an empty decision table (step 4), not "the important ones are done." (`/hackify:review-triage` runs this table on demand.)

1. **Tabulate.** Build a decision table with columns **Finding / Severity / Decision / Evidence**, one row per finding from every reviewer plus the self-review, plus every `staged` row from the perf-scout ([perf-scout.md](perf-scout.md)) and law-scout ([law-scout.md](law-scout.md)) tables at its catalog-default severity. Decision is one of `accept` (fix) / `push-back` (needs file:line evidence, and on a Critical also the escalation in step 2) / `defer` (Minor only, with explicit user sign-off).
2. **Refute before you fix.** Dispatch ONE adversarial refuter ([parallel-agents/phase-5-refute.md](parallel-agents/phase-5-refute.md)) over the table, one per review round, judging every finding at every severity and carrying both lenses itself, reproduction first and then authority. Hand it the whole round verbatim as its `findings_batch` input, and on a round that found nothing hand it the literal `none` rather than a blank, which it refuses as a dispatch bug. Its verdicts fill the `Decision` and `Evidence` columns. **The default is to keep the finding**, uncertainty is never a refutation, and a Critical dies only when BOTH lenses refute it, each with its own file:line counter-citation. The bar was never two agents, it was two independent lines of attack that must both fail, and the lens is what does the attacking; a Critical whose reproduction lens refutes but whose authority lens upholds stays alive at its original severity. This is how a `push-back` earns its required evidence. On a Critical it is only the evidence: a Critical may never be `push-back` on a single lens, and a Critical refuted on BOTH lenses earns an escalation rather than the flip. Dispatch the adjudication reviewer (the inline template above) on that finding, hand it both counter-citations, and surface the conflict to the user; the row stays `accept`, and out of step 3, until that reviewer rules and the user signs off. The routing and its rationale are canonical in `parallel-agents/phase-5-refute.md`, section "Feeding the decision table".
3. **Fix in severity order, through dispatched agents.** Critical → Important → Minor. A Critical row still waiting on the step-2 escalation is not a survivor yet and is not dispatched here; close that escalation first, either back to `accept` and fix it, or into a signed-off `push-back`. A `needs-restatement` row is held out the same way; rewrite that claim from the reviewer's own text first, and once it names what breaks and where it is an ordinary `accept` row and is fixed here with the rest. Non-trivial fixes go through a batched approval wizard (propose 2-3 options per finding or tight cluster, ask before writing). **Every surviving finding is a code change, so it goes to a fix agent under a file allowlist, never to the parent's own edit** (the no-parent-authored-diff law in `SKILL.md`). Group the surviving findings into file-disjoint clusters and dispatch one agent per cluster in a single message; findings that touch the same file share one agent and are fixed in order. Test each cluster.
4. **Close the phase, once.** **Phase 5 dispatches exactly ONE review and ONE refuter, and the phase ends when the surviving findings are fixed.** Run the verify triad on the touched scope after the last fix batch and Phase 5 is over. There is no second review, no second refuter and no re-scan, however much the fixes changed. A `needs-restatement` row does not buy one either: the parent rewrites that claim inside this round, the rewritten finding rejoins this round's table as a survivor, and a claim the parent still cannot state joins the written list below instead of opening a round of its own (`parallel-agents/phase-5-refute.md`, section "Feeding the decision table"). A defect a fix introduces is fixed in the same fix sequence and reported in step 5; it does not open a new round. Anything still unresolved when the fixes are done goes to the user as a written list, never as another round. The reviewed diff stays `git diff <base>..HEAD -- . ':(exclude)docs/work/*'`. The exclusion is not optional and not a shortcut: the work-doc is the ruler the diff is measured against and cannot also be the measured, and this phase writes its gate line, its scope ledger and its decision table into that same file while the panel is reading.

   **What the cap gives up, stated plainly.** The rule it replaces was right about the mechanics. A clean review result describes the diff as it stood when the reviewer read it, not the diff after the fixes, so the last fixes ship without the reviewer ever having seen them. That risk is real and this cap does not remove it; it prices it. The cost it buys off is measured: one task in the sprint that shipped the cap took 14 review rounds and 32 waves, and each extra round bought less than the one before. Ten defects did surface after the panel closed, 3 created by fixes and 7 the panel had missed, and all 7 were one family, a summary restating a canonical fact that had since moved. Narrow, real and known, against a loop with no way to stop. The reasoning and the same evidence are canonical in [phases/phase-5-review.md](phases/phase-5-review.md).
5. **Record.** The final table (every Decision + Evidence, including every refuter verdict) goes into the work-doc Sprint Review; any deferred row carries its sign-off note, any `push-back` row carries its counter-citation so a refuted finding stays auditable rather than deleted, and a `push-back` on a Critical carries the adjudication verdict and the user's sign-off alongside it.

---

## After review (back to Phase 4 if anything changed)

If review found Critical or Important issues and you fixed them, **re-run Phase 4 verification** before going to Phase 6. New code = new evidence required.

---

## Self-review honesty

The self-review is only useful if you're honest about it. The temptation to tick all boxes and move on is real. Counter it:

- For any item you're tempted to tick without checking, **actually check**, open the file, grep, run the linter scoped to the file.
- For any item that's a soft pass ("mostly DRY"), **state the soft pass** in the notes column. The Retrospective will pick it up.
- If the diff has a section you genuinely don't understand well enough to review (e.g., a domain you haven't worked in), **escalate** even if the diff is small. Self-review only works when you can self-review.
