# Verify & Review — Phases 4 + 5

Phase 4 proves the **original ask** is met. Phase 5 ensures the **code is good**. Both run after the last Tasks checkbox is ticked.

---

## Phase 4 — Verify (DoD with fresh evidence)

**Rule.** Evidence before claims. Every "passes" / "done" / "works" must be backed by output you ran in this turn — not earlier.

### The DoD checklist (every task type)

```
- [ ] All tests pass — fresh test-command output, exit 0, 0 failures, 0 errors
- [ ] Linter clean — fresh lint output, 0 errors (warnings only if pre-existing)
- [ ] Typecheck clean — fresh typecheck output, 0 errors
- [ ] All Tasks checkboxes ticked
- [ ] Every Definition-of-Done bullet from Phase 2 verified — paste evidence per bullet
- [ ] No placeholders, no orphan TODOs, no debug logging left behind
- [ ] No new lint suppressions (zero tolerance)
- [ ] No new `!` non-null assertions in production code
- [ ] Manual smoke (if user opted in) — steps + outcome logged
```

### How "evidence" looks

Bad:

> Tests should pass now. ✓

Good:

```
$ cd <project> && bun test
✓ 87 pass
0 fail
Ran 87 tests across 12 files. [3.42s]
```

Bad:

> Lint is fine.

Good:

```
$ bun run lint
$ biome check src/
Checked 142 files in 89ms. No fixes needed.
```

If you can't show the output, you don't know it's true. Re-run.

### Common verification failures (catch yourself)

| Failure | What to do |
|---|---|
| Output references caches / "warm" runs | Re-run from a clean state |
| One package green, another not run | Run all packages |
| Test command exits 0 but skips suites | Check the count — "0 tests ran" is a fail |
| Linter exits 0 with warnings | Confirm warnings are pre-existing; if new, fix |
| Typecheck "skipped" or "incremental" | Force fresh: delete `tsconfig.tsbuildinfo` if needed |

### Regression-test red-green cycle

For bug fixes, prove the regression test actually catches the bug:

```
1. Apply your fix.        ← test passes
2. Revert the fix only.   ← test should fail (paste this output too)
3. Re-apply the fix.      ← test passes again (paste)
```

This proves the test is sensitive to the bug it claims to catch.

---

## Phase 5 — Review

### Default: parallel multi-reviewer + self-review

For any non-trivial diff (anything beyond a one-line typo / config-only change), Phase 5 dispatches THREE foreground reviewers in parallel — security/correctness, quality/layering, plan-consistency — in a single message. The dispatch templates live in `references/parallel-agents.md` under "Multi-reviewer (Phase 5)". Add a 4th reviewer for diffs with a 4th distinct concern (e.g., heavy UI redesign on top of backend changes); cap at 4.

The self-review still happens — the parent walks the diff (`git diff <BASE_SHA>..HEAD`) and ticks each checklist item below. Note pass/fail and a 1-line note in the work-doc Verification → Self-review table. **Self-review is the floor, the parallel reviewers are the ceiling.** Both run for non-trivial diffs.

```
- [ ] DRY — no duplicated logic; existing helpers reused; new helpers extracted if 3+ uses
- [ ] Layering — presentation/domain/infrastructure separation honored
        Backend: routes are pure delegation; services own business logic + DB; no HTTP framework imports in services
        Frontend: routes thin; features own logic; components dumb; lib is glue only
- [ ] Named types — every shape with ≥2 props has a named interface/type in the right folder
        Backend: <module>/interfaces or src/common/types
        Frontend: <feature>/types.ts or src/lib/types
- [ ] No lint suppressions (biome-ignore, eslint-disable, @ts-ignore, @ts-expect-error)
        Sole carve-out: @ts-expect-error in test files for deliberately invalid input, with WHY
- [ ] File-size cap — no file >500 LOC; split by responsibility
- [ ] Function caps — ≤40 LOC, ≤3 params, ≤3 nesting levels
- [ ] Dead code — no unused exports, methods, imports; no commented-out code
- [ ] Edge cases — null/undefined, empty arrays/strings, concurrent access, partial failures
- [ ] Naming for intent — variables/functions describe WHAT they DO, not HOW
- [ ] Error handling — explicit per path; no silent swallows; no empty catches
        Backend: throw named domain errors from src/errors/
        Frontend: throw named Error subclasses with .name set
- [ ] No `!` non-null assertions in production code
- [ ] Security — no hardcoded secrets, no SQL string-concat, sanitized paths, validated inputs
- [ ] Tests cover behavior not implementation; no mocks where real code would work
- [ ] Comments only on WHY (non-obvious constraints), never WHAT
```

### When to escalate to a reviewer subagent

Spawn a **foreground** general-purpose reviewer subagent when ANY of:

- Diff > 300 LOC
- Diff touches > 8 files
- Cross-module refactor (touches multiple bounded contexts)
- Touches **any** of: auth/permissions, cryptography, database migrations, payment/billing, public API contracts, security headers, CORS/CSRF, OAuth flows, session management
- User explicitly asked for deeper review

When you escalate, **also** complete the self-review — escalation is *additive* defense, not replacement.

### Reviewer subagent prompt template

This template is the **escalation reviewer** — the specialist fired when the default Phase 5 multi-reviewer pass (security/correctness + quality/layering + plan-consistency) surfaces a finding that needs a deeper second opinion, or when the diff trips one of the escalation triggers above. It conforms to the 7-section sub-agent contract in `references/parallel-agents.md` "Template Contract" (SEVERITY mandatory because this is a review template).

```
Subagent type: general-purpose

**ROLE**

You are a senior principal engineer with 15+ years of experience adjudicating
multi-reviewer findings in complex codebases — reconciling contradictory
review verdicts, distinguishing a real defect from a stylistic preference,
and signing off on diffs that touch sensitive surfaces (auth, migrations,
public API contracts, billing, cryptography).

Your stack expertise covers: TypeScript backend services on Bun / Node,
Postgres migrations and row-level security, OAuth/OIDC and session
management, multi-tenant data isolation, and cross-package monorepo
refactors.

You apply SOLID, Clean Code (Martin), and OWASP Top 10 (2021) when the
diff has a security surface; RFC 2119 keywords when judging whether a
prior reviewer's finding is normative or advisory.

You reject: silent agreement with prior reviewers without a citation,
"looks fine" verdicts without a file:line anchor, severity downgrades
justified by author intent, unverifiable claims defended as "should work."

Bias to: citing file:line for every concur-or-rebut on a prior finding.
Bias against: paraphrasing a prior reviewer's claim without quoting it.

**INPUTS**

1. `{{work_doc_path}}` — absolute filesystem path to the work-doc
   (e.g. an absolute path ending in `docs/work/<slug>.md`).
2. `{{project_path}}` — absolute filesystem path to the project root.
3. `{{project_name}}` — string identifier for the project.
4. `{{base_sha}}` — git SHA marking the base of the diff.
5. `{{head_sha}}` — git SHA marking the head of the diff.
6. `{{diff_kind}}` — one of `feature` / `fix` / `refactor` / `redesign`.
7. `{{stack_summary}}` — one-line stack description
   (e.g. "Bun + Hono + Drizzle + Postgres" or
   "Vite + React 19 + shadcn/ui + Tailwind v4").
8. `{{sensitive_surfaces}}` — comma-separated list of sensitive areas the
   diff touches (e.g. "auth, migrations, public API contracts").
9. `{{reviewer_a_report}}` — verbatim text of the Phase 5 Reviewer A
   (security & correctness) report.
10. `{{reviewer_b_report}}` — verbatim text of the Phase 5 Reviewer B
    (quality & layering) report.
11. `{{reviewer_c_report}}` — verbatim text of the Phase 5 Reviewer C
    (plan consistency & scope) report.
12. `{{user_claude_md_path}}` — absolute filesystem path to the
    user-global CLAUDE.md (typically `~/.claude/CLAUDE.md`), or the
    string `none` if absent.
13. `{{project_claude_md_path}}` — absolute filesystem path to the
    project CLAUDE.md (typically `<project>/CLAUDE.md`), or `none`.

**OBJECTIVE**

A severity-tagged adjudication report that concurs or rebuts every finding
raised by Reviewer A, B, and C — with a file:line citation per item — and
adds any net-new findings the prior reviewers missed.

**METHOD**

1. Read `{{work_doc_path}}` end-to-end. Build a mental index of every
   Definition-of-Done bullet (D1, D2, …) and every Task ID (T1, T2, …).
2. Read `{{reviewer_a_report}}`, `{{reviewer_b_report}}`, and
   `{{reviewer_c_report}}` in full. List every finding (Critical /
   Important / Minor) each reviewer raised. Do not summarise — keep the
   original wording so you can quote it later.
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
   technical reason. Bare "I agree" or "I disagree" is forbidden — every
   verdict carries a citation.
6. Apply your specialist lenses to the diff to catch what the three prior
   reviewers may have missed: SOLID violations, Clean Code (Martin)
   smells, and — when `{{sensitive_surfaces}}` mentions auth, sessions,
   tokens, crypto, or migrations — the relevant OWASP Top 10 (2021)
   categories. Record any net-new finding with a file:line citation.
7. For every Definition-of-Done bullet in the work-doc, confirm the diff
   delivers it. Any DoD bullet not delivered by the diff is a Critical
   finding under "plan consistency."

**VERIFICATION**

Paste this checklist under a `## Verification` heading in your report and
answer every item yes or no. If ANY answer is "no", loop back to METHOD
before producing OUTPUT.

1. Did you read all three prior reviewer reports end-to-end before
   writing any verdict? (yes / no)
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
   live diff or live docs — not ones you inferred from prior-reviewer
   wording? (yes / no)

**SEVERITY**

- **Critical** — A defect that will ship broken work, lose data, leak
  credentials, or violate the work-doc's Definition of Done if not
  fixed before merge. Anchored examples:
  - A schema field referenced in the diff cannot be verified against
    live docs or live source — Critical (uncertainty about contract
    surface is shipped-broken risk; see the canonical bug "soft severity
    language let unverifiable schema findings get downgraded").
  - Reviewer A flagged an auth-route guard as "Important" but the diff
    actually removes the guard from a route reachable by unauthenticated
    callers — escalate to Critical and cite OWASP Top 10 (2021) A01
    (Broken Access Control).
- **Important** — A defect that risks rework, scope drift, or quality
  regression but will not by itself ship a broken release. Anchored
  examples:
  - Reviewer B and Reviewer C disagree on whether a helper duplicates an
    existing utility; the diff is correct but the duplication will
    surface as a refactor cost — Important.
  - A new public-method signature uses three positional parameters where
    a named DTO would be clearer (Clean Code (Martin) — long parameter
    list); behavior is correct, design is brittle — Important.
- **Minor** — Editorial or stylistic issues that do not change behavior.
  Anchored examples:
  - Reviewer C noted a TODO comment with no owner; behavior unaffected —
    Minor.
  - A variable name uses an abbreviation where the codebase convention
    is the full word; no functional impact — Minor.

If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important.

**OUTPUT**

≤300 words — terse review beats long review; longer reports get skimmed
and Critical findings get lost in prose. Use this exact report skeleton:

````
## Adjudication of prior reviewers

### Reviewer A findings
- <finding wording, verbatim> — CONCUR | REBUT — <file:line> — <one-line reason>
- ...

### Reviewer B findings
- <finding wording, verbatim> — CONCUR | REBUT — <file:line> — <one-line reason>
- ...

### Reviewer C findings
- <finding wording, verbatim> — CONCUR | REBUT — <file:line> — <one-line reason>
- ...

## Net-new findings

### Critical
- <finding> — <file:line>

### Important
- <finding> — <file:line>

### Minor
- <finding> — <file:line>

## Verification
1. <yes|no>
2. <yes|no>
3. <yes|no>
4. <yes|no>
5. <yes|no>
6. <yes|no>
````

If a sub-section has no findings, write `None.` on its own line under the heading — never go silent.
```

If the diff has BOTH a large security/auth surface AND a large UX/visual surface, **dispatch two reviewers in parallel** — one focused on security/correctness, one on architecture/design. They'll independently flag different issues.

### Acting on reviewer feedback (the response pattern)

```
1. READ the full feedback without reacting.
2. UNDERSTAND each item — restate it in your own words. If unclear, ask
   the user (or, if reviewer is a subagent and you can re-dispatch, re-ask).
3. VERIFY against the codebase — grep for the function name, read the file,
   check whether the reviewer's claim matches reality.
4. EVALUATE — technically sound for THIS codebase? YAGNI check: grep for
   actual usage before "professionalizing" something.
5. RESPOND — technical acknowledgment OR reasoned pushback (with evidence).
6. IMPLEMENT — one item at a time. Test each. Don't bundle.
```

**Never** "You're absolutely right!" before verification. **Never** start implementing fixes before clarifying ambiguous items.

### Pushback criteria — push back when

- The suggestion would break existing functionality.
- The suggestion is for a feature with no real consumers (YAGNI).
- The suggestion contradicts a documented architecture decision in CLAUDE.md.
- The suggestion is technically wrong for this stack/version.
- There's a reason in legacy or constraints the reviewer can't see.

When pushing back, lead with the technical reason, not the disagreement:

> *"The reviewer suggests adding `retry` with backoff. But this is a request-scoped service inside a tenant route — retries would re-acquire the pool client, breaking `SET LOCAL search_path`. The right fix is at the caller, not in the service. Skipping."*

### Severity → action

| Severity | Action |
|---|---|
| Critical | Fix now. Do NOT advance to Phase 6 until resolved. Re-run verification. |
| Important | Fix before claiming done. May extend the work-doc Tasks list (mark added tasks "review-driven"). |
| Minor | Either fix now if cheap (≤5 min) OR add a Post-mortem entry as a follow-up. Do not silently drop. |

---

## After review — back to Phase 4 if anything changed

If review found Critical or Important issues and you fixed them, **re-run Phase 4 verification** before going to Phase 6. New code = new evidence required.

---

## Self-review honesty

The self-review is only useful if you're honest about it. The temptation to tick all boxes and move on is real. Counter it:

- For any item you're tempted to tick without checking, **actually check** — open the file, grep, run the linter scoped to the file.
- For any item that's a soft pass ("mostly DRY"), **state the soft pass** in the notes column. The Post-mortem will pick it up.
- If the diff has a section you genuinely don't understand well enough to review (e.g., a domain you haven't worked in), **escalate** even if the diff is small. Self-review only works when you can self-review.
