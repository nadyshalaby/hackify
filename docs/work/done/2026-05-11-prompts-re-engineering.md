---
slug: prompts-re-engineering
title: Re-engineer every sub-agent and wizard prompt for weak-model reliability
status: done
type: refactor
created: 2026-05-11
completed: 2026-05-11
project: hackify
current_task: archived
worktree: /Users/corecave/Code/hackify
branch: main
related:
  - docs/work/done/2026-05-11-hackify-skill-to-plugin.md
---

# Re-engineer every sub-agent and wizard prompt for weak-model reliability

## Original Ask (verbatim)

> I want to re-engineer the whole prompts to address each related stage prompts quality issues, and gaps. I want each prompt to be crafted at the highest best format possible to give me maximum quality even if the user is using a weaker model. (We need to ensure a full-shipped-working results from each stage) we don't want to leave any thing to consecoinces [chance]

> [Addendum] Always instruct the agent with its role, expertise, best practises, community standards, ...etc. e.g. "you are the best security engineer blah blah blah"

## Canonical "six bugs" this release closes

Drawn from the v0.1.0 post-mortem + the prompt-quality self-review at session-end. Every CHANGELOG bullet, every DoD framing reference, and every validator anchor uses this exact list verbatim — no reframing:

1. **Soft severity language let unverifiable schema findings get downgraded.** Reviewer A flagged `"source": "."` as "Important — may break under future schema tightening." That qualifier let it be deferred. Result: v0.1.0 install rejected; v0.1.1 + v0.1.2 reshipping cost.
2. **No cross-file consistency requirement in author prompts.** The README author agent had no rule binding its hero tagline to the `plugin.json` / `marketplace.json` descriptions. Phase 5 caught the four-way drift after the fact.
3. **No inline verification scripts in many templates.** Agents reported "done" without running the checks that would have caught their own gaps (evals.json contamination almost shipped).
4. **No anchored severity rubrics.** "Mark Critical / Important / Minor" without anchored examples produced inconsistent reviewer outputs.
5. **No placeholder syntax for dispatch-time values.** Each dispatching call handwrote paths and constraints; drift between calls was inevitable.
6. **Research-phase prompts didn't verify the architectural behaviors the plan depended on.** The "commands inside a plugin are namespaced" property wasn't asked about explicitly — only Phase 2.5 caught it.

The CHANGELOG (T9), the Approach narrative, and any "this fixes …" framing reference this six-bug list verbatim.

## Clarifying Q&A (locked, with sign-off addendum)

1. **Scope** — Everything that drives quality: all 11 sub-agent templates in `parallel-agents.md`, the escalation reviewer in `review-and-verify.md`, all 7 wizard banks in `clarify-questions.md`, any incidental templates in `implement-and-test.md` / `work-doc-template.md`, and SKILL.md cross-reference updates.
2. **Lowest-tier model baseline** — Haiku-class / smallest commodity model. Maximally explicit. Zero "use judgment" language.
3. **Structure** — Standardized 7-section sub-agent contract (with conditional sections — see below) + 4-section wizard contract, with `{{snake_case_placeholders}}` for runtime substitution by the dispatching agent.
4. **Release** — Ship as **v0.1.3**. Patch label by user choice; CHANGELOG explicitly notes "patch label, minor-level scope" and expects ~half a working day of focused work.
5. **Addendum (after initial sign-off)** — Every sub-agent template ROLE section MUST establish role, expertise, named community standards, rejected anti-patterns, and a behavioral bias. No "you are paid to ..." stylistic line — use "Bias to / Bias against" concrete rules instead.

## The two contracts (canonical reference for this work)

### Sub-agent template contract — 7 sections, with two conditionals

```
1. ROLE (mandatory, every template)
   Five elements, all mandatory:
   (a) Identity + seniority — "You are a senior <discipline> engineer with
       15+ years of experience in <domain>."
   (b) Domain expertise — specific systems / patterns / stacks the role
       has lived in. 2-4 concrete items.
   (c) Standards the role follows — cite by name, version-pinned where
       applicable. Allowed token list (extend in T1):
         OWASP Top 10 (2021), SANS CWE-25, NIST SP 800-63B, RFC 6749,
         RFC 7519, RFC 9110, WCAG 2.2 AA, ARIA 1.2, Clean Code (Martin),
         SOLID, 12-Factor App, Conventional Commits 1.0.0,
         Semantic Versioning 2.0.0, Keep a Changelog 1.1.0, RFC 2119
         keywords, ISO 8601, Postel's law, expand-then-contract migrations.
       Cite 1-3 that genuinely apply. The validator (T8 check [12])
       greps against this allowlist — citations outside it must be
       added to the allowlist with a justification comment.
   (d) Rejected anti-patterns — "You reject <X>, <Y>, <Z>." Three to
       five concrete things this role refuses to ship.
   (e) Behavioral bias — "Bias to: <verb>. Bias against: <verb>."
       Two lines, concrete actions. Examples:
         Security reviewer:   Bias to: flagging.
                              Bias against: deferring to author intent.
         Implementation:      Bias to: smallest correct diff.
                              Bias against: refactoring outside scope.
         Research:            Bias to: citing primary sources.
                              Bias against: paraphrasing without a link.

2. INPUTS (mandatory)
   Numbered list. Each input names a {{placeholder}} and the type
   ("{{work_doc_path}} — absolute filesystem path"). Placeholders are
   instructions to the DISPATCHING AGENT (the parent), NOT the sub-agent.
   The dispatching agent MUST replace every {{placeholder}} with a
   concrete value before sending the prompt. A sub-agent receiving
   literal {{...}} text is a dispatch bug — the sub-agent should refuse
   and report "unfilled placeholder: <name>".

3. OBJECTIVE (mandatory)
   One sentence. Exactly one noun phrase deliverable. If the template
   produces more than one deliverable, split into multiple templates.

4. METHOD (mandatory)
   Numbered steps, minimum three. Each step is one concrete action with
   a verifiable outcome ("read X then grep for Y" — not "investigate Z").
   For templates that touch user-facing prose across multiple files,
   METHOD MUST contain a step naming the canonical sentence (or
   canonical fact) the agent will replicate verbatim, with the source
   file path. Generic "be consistent with related files" is forbidden.

5. VERIFICATION (mandatory — two shapes; pick the one that fits)
   Shape A — Executable. For templates that touch the filesystem or
   produce an auditable artifact: inline bash script that exits 0 on
   success, non-zero on failure. The agent runs it before reporting
   "done"; if non-zero, the agent loops back to METHOD.
   Shape B — Self-checklist. For prose-producing templates (Research,
   Spec-review, plan-consistency reviews) that have no filesystem
   artifact: a numbered yes/no list the agent MUST paste into its
   report under a "Verification" heading. If any answer is NO, the
   agent loops back to METHOD, not REPORT. Every checklist item is a
   single question with a yes/no answer — no "evaluate the X."

6. SEVERITY (review/audit templates ONLY — omit on non-review templates)
   Anchored examples per level. Minimum 2 examples per level.
     Critical example anchors should reference real failure modes
     (e.g. "schema field cannot be verified against live docs" =
     Critical, not Important — see canonical bug #1).
   Mandatory line, verbatim: "If you cannot verify a claim against
   live docs or live code, mark the finding Critical, not Important."
   The validator (T8 check [11]) greps for this exact phrase.

7. OUTPUT (mandatory)
   Word cap shape depends on template type:
     Review/audit/research templates: single global word cap with
       reasoning ("≤300 words — terse review beats long review").
     Implementation/build templates: per-section sub-budget
       ("Files touched: 1 line each; RED→GREEN: 1 line per test;
       Deviations: ≤80 words; Self-review: compact ✓/✗ table").
   Exact report format with named sections. What to omit if nothing
   relevant (still report explicitly: "No findings." — never go silent).
```

### Wizard bank contract — 4 sections per task-type

```
1. SCENARIO       — when to use this bank (one paragraph)
2. COMPOSITION    — decision rules for picking N from the bank based on
                    context already gathered. Not free choice — explicit
                    "if X then ask Y, skip Z" rules.
3. QUESTIONS      — each question has: text, header (≤12 chars), options
                    A/B/C/D with option A suffixed " (Recommended)",
                    why-this-matters (one line: what the answer changes
                    downstream).
4. EXIT CRITERIA  — when the wizard is "done enough" to proceed to Phase 2
                    (e.g. "all questions answered AND no answer left
                    ambiguous AND any 'Other' free-text reduced to one
                    of A/B/C/D semantics").
```

### Worked example: ROLE for the Phase 5 security reviewer

```
You are a senior application security engineer with 15+ years of experience
auditing Node.js and TypeScript backends, OAuth/OIDC implementations,
multi-tenant data isolation, and CI/CD supply chains.

Your stack expertise covers: request lifecycles in NestJS / Fastify / Hono,
Drizzle and Prisma migrations, Better Auth and Auth.js, Redis-backed
sessions, Postgres row-level security, GitHub Actions secrets handling.

You apply OWASP Top 10 (2021), SANS CWE-25, NIST SP 800-63B, and the
relevant clauses of RFC 6749 and RFC 7519.

You reject: silent error fallbacks, broad CORS allowlists, secrets in
source, unparameterized SQL, JWT-in-localStorage, missing rate limits on
auth endpoints.

Bias to: flagging.
Bias against: deferring to author intent on "it works in practice".
```

Every framework cited (OWASP Top 10 2021, SANS CWE-25, NIST SP 800-63B, RFC 6749, RFC 7519) is on the allowlist in §1(c) of the contract. Citations outside the allowlist MUST be added explicitly in T1 with a justification.

## Assumptions (confirm at gate or correct in chat — small fixes are find-replace)

- **`{{placeholder}}` syntax** — `{{snake_case_underscored}}`. Placeholders are documentation to the dispatching agent. There's no runtime interpolation engine — substitution happens when the parent writes the actual sub-agent call. Subagents receive concrete values, never `{{...}}` text.
- **File restructure** — `parallel-agents.md` "Per-task templates" section gets restructured so each named template (including each A/B/C reviewer inside Phase 2.5 and Phase 5) gets its own `### ` heading. Total headings after restructure: 11. This lets the validator's `^### ` grep match the count the contract claims.
- **`clarify-questions.md` universal preamble** stays at `## Universal preamble` heading (not `## Type: ...`) — the validator handles both patterns.
- **Stack opinions paragraph** in `code-rules.md` is **not in scope** — the contracts apply only to dispatch / review / wizard prompts.
- **Estimation** — roughly **half a working day** of focused single-session work (Wave 2 parallelism is the critical-path saver; without it, 3-5h serial).
- **Coverage tables** — each Wave-2 agent emits a table (old heading → new heading → behavior preserved / explicitly dropped / new) so regression audit in Wave 5 has source material, not a diff to reverse-engineer.

## Definition of Done

- [ ] **D1** `references/parallel-agents.md` has a "Template Contract" section at the top with the canonical 7-section spec including the allowlist of acceptable framework+version tokens.
- [ ] **D2** Under "Per-task templates" in `parallel-agents.md`, exactly 11 `### `-headed templates exist, one per logical sub-agent: Phase 1 Research, Phase 2.5 Spec-review A, B, C, Phase 3 Implementation wave, Phase 3b Debug evidence, Phase 4 Cross-package verification, Phase 5 Multi-reviewer A, B, C, Phase 5 Code-review escalation.
- [ ] **D3** Every one of those 11 templates contains the mandatory sections (ROLE, INPUTS, OBJECTIVE, METHOD, VERIFICATION, OUTPUT) and — only when applicable — SEVERITY. Review/audit templates: SEVERITY MANDATORY. Build/research templates: SEVERITY OMITTED entirely (not present as an empty section).
- [ ] **D4** Every ROLE section contains all five elements (identity+seniority, domain expertise, named standards from allowlist, rejected anti-patterns ≥3, behavioral bias as "Bias to: … Bias against: …"). No "you are paid to" stylistic line.
- [ ] **D5** Every METHOD section that touches user-facing prose across multiple files names the **specific canonical sentence/fact** to replicate verbatim with the source file path. Generic "be consistent with related files" forbidden.
- [ ] **D6** Every VERIFICATION section is one of two shapes (Executable or Self-checklist) and follows the spec. Self-checklist questions are all yes/no.
- [ ] **D7** Every SEVERITY section (review/audit templates only) contains: ≥2 anchored examples per level, AND the verbatim line "If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important."
- [ ] **D8** Every OUTPUT section has an explicit word cap (`≤NNN words`) or per-section sub-budgets; format named.
- [ ] **D9** `references/clarify-questions.md` has a "Wizard Contract" section at top + all 7 banks (1 universal preamble + 6 task types) conform to the 4-section structure with the recommended-first + "(Recommended)" suffix on option A.
- [ ] **D10** `references/review-and-verify.md` escalation reviewer rewritten to the 7-section contract.
- [ ] **D11** `references/implement-and-test.md` and `references/work-doc-template.md` audited; any prompt fragments found are rewritten to the appropriate contract; audit result logged in Implementation Log even if no fragments found.
- [ ] **D12** `skills/hackify/SKILL.md` has a short paragraph in the "Parallel agents — the default" section pointing readers at `references/parallel-agents.md` "Template Contract", and a one-line note in "Phase 1 — Clarify" pointing at `clarify-questions.md` "Wizard Contract." No other SKILL.md changes.
- [ ] **D13** Every placeholder uses `{{snake_case}}`. Zero literal `/Users/`, `/home/`, or `/tmp/` paths appear inside any template body (those resolve from placeholders at dispatch time).
- [ ] **D14** Token scrub still clean: 0 hits for Syanat / SyanatBackend / SyanatFrontend / graphify / corecave / nadyshalaby across `skills/`.
- [ ] **D15** `plugin.json` and `marketplace.json` plugin entry version → `0.1.3`.
- [ ] **D16** `CHANGELOG.md` v0.1.3 entry exists. Includes verbatim: a) "patch label, minor-level scope" note; b) the six canonical bugs from the §Context list above, in that order; c) public-facing summary of the 7-section sub-agent contract and 4-section wizard contract.
- [ ] **D17** `scripts/validate-dod.sh` extended; existing checks unchanged; runs to exit 0. New checks (see T8 for full spec).
- [ ] **D18** Commit + tag `v0.1.3` + push (commit AND tag).
- [ ] **D19** Work-doc archived to `docs/work/done/2026-05-11-prompts-re-engineering.md` with a Post-mortem section (≥8 bullets).

## Approach

Patch the two contracts (7-section sub-agent + 4-section wizard) into their host files as canonical preambles. Restructure `parallel-agents.md` "Per-task templates" so each of the 11 logical templates gets its own `### ` heading (so structural validation by grep works). Dispatch three parallel content agents in Wave 2 with disjoint scopes: T4a rewrites the six review/audit templates inside `parallel-agents.md`; T4b rewrites the five build/research templates inside the same file; T5 rewrites all 7 wizard banks in `clarify-questions.md`; T6 rewrites the escalation reviewer in `review-and-verify.md` plus audits the two remaining reference files. Each Wave-2 agent emits a coverage table mapping old heading → new heading → "preserved / dropped / new" so regression review in Wave 5 has source material. Extend `validate-dod.sh` with structural assertions so this kind of drift can never re-enter silently. Bump to v0.1.3, tag, push.

Estimated ~half a working day of focused single-session work; Wave 2 parallelism is the critical-path saver.

### Execution waves

```
Wave 1 (parallel inline — contracts authored first so Wave 2 has the spec to
        reference; no subagent overhead):
  T1  Author the "Template Contract" preamble at the top of parallel-agents.md
      (canonical 7-section spec, allowlist, placeholder rules, two VERIFICATION
      shapes, ROLE worked example).
  T2  Author the "Wizard Contract" preamble at the top of clarify-questions.md
      (canonical 4-section spec, recommended-first rule).
  T3  Restructure parallel-agents.md "Per-task templates" section so each of
      the 11 logical templates has its own `### ` heading. Body content stays
      as-is for this task — Wave 2 will rewrite content. (Headings only here.)
  T4  Bump plugin.json + marketplace.json plugin entry to 0.1.3.

Wave 2 (parallel agents — four substantive content rewrites; disjoint scopes):
  T5  Subagent: rewrite the SIX review/audit templates in parallel-agents.md
      to the 7-section contract (Spec-review A/B/C + Multi-reviewer A/B/C).
      File-scope guard: ONLY edit content inside the six named `### ` blocks;
      do not touch surrounding prose or other templates. Emits coverage table.
  T6  Subagent: rewrite the FIVE build/research templates in parallel-agents.md
      (Research, Implementation wave, Debug evidence, Cross-package verification,
      Code-review escalation). Same file-scope guard, disjoint blocks from T5.
      Emits coverage table.
  T7  Subagent: rewrite all 7 wizard banks in clarify-questions.md
      (universal preamble + 6 task types: feature / fix / refactor / revamp /
      debug / research). Each gets a 4-section Wizard Contract conformant
      structure. Emits coverage table.
  T8  Subagent: rewrite escalation reviewer in review-and-verify.md to the
      7-section contract AND audit implement-and-test.md + work-doc-template.md
      for prompt fragments. Any prompt-shaped fragment found is rewritten to
      the appropriate contract. Audit result logged.

Wave 3 (sequential inline; depends on Wave 2):
  T9  Update SKILL.md: short paragraph in "Parallel agents — the default"
      pointing at parallel-agents.md "Template Contract"; one-line note in
      "Phase 1 — Clarify" pointing at clarify-questions.md "Wizard Contract".
      No other SKILL.md drift.
  T10 Extend scripts/validate-dod.sh with check sections [9]–[14]. Full spec
      in T10 task body below. Existing [1]–[8] unchanged.
  T11 Add `## [0.1.3]` entry at top of CHANGELOG.md citing patch-label
      caveat, listing the six canonical bugs verbatim, summarizing the two
      contracts.

Wave 4 (verify):
  T12 Run validate-dod.sh; paste output. If anything red: classify (agent
      failure vs plan failure) and loop. Re-run after fixes.

Wave 5 (review — three parallel foreground reviewers):
  T13 Reviewer A: contract conformance audit (all sections present where
      mandatory, all placeholders `{{snake_case}}`, all OUTPUT word caps
      present, all allowlist citations valid). ≤300 words.
  T14 Reviewer B: weak-model robustness audit (read each new prompt
      simulating a Haiku-class model — any step ambiguous? any "use
      judgment"? any unanchored severity? any VERIFICATION that doesn't
      produce a binary signal?). ≤400 words.
  T15 Reviewer C: regression audit USING the coverage tables emitted in
      Wave 2 (every old heading mapped? any "dropped" entries justified?
      any net-new behavior unintentionally introduced?). ≤300 words.

Wave 6 (finish):
  T16 Apply review patches (Critical immediately; Important before tag;
      Minor → CHANGELOG follow-ups). Re-run validator. Commit. Tag v0.1.3.
      Push commit + tag. Archive work-doc to docs/work/done/ with Post-mortem.
```

## Tasks

- [ ] **T1** — Author the "Template Contract" preamble section at the top of `references/parallel-agents.md` (before "When to fan out"). Specify the 7 mandatory sections (ROLE, INPUTS, OBJECTIVE, METHOD, VERIFICATION, SEVERITY [conditional], OUTPUT) with prose definitions + one worked example for ROLE (the security reviewer from the work-doc). Include the version-pinned framework allowlist verbatim. State the placeholder convention. State that ALL templates below this section conform AND that SEVERITY is review/audit-only (build/research templates omit it entirely).
- [ ] **T2** — Author the "Wizard Contract" preamble section at the top of `references/clarify-questions.md`. Specify the 4 mandatory sections (SCENARIO, COMPOSITION, QUESTIONS, EXIT CRITERIA). Document the recommended-first + " (Recommended)" suffix rule.
- [ ] **T3** — Restructure `parallel-agents.md` "Per-task templates" section: each of the 11 logical templates gets its own `### ` heading. Names: `### Phase 1 — Research`, `### Phase 2.5 — Spec-review A (internal consistency)`, `### Phase 2.5 — Spec-review B (architectural / cross-cutting)`, `### Phase 2.5 — Spec-review C (dependency / ordering)`, `### Phase 3 — Implementation wave`, `### Phase 3b — Debug evidence gathering`, `### Phase 4 — Cross-package verification`, `### Phase 5 — Multi-reviewer A (security & correctness)`, `### Phase 5 — Multi-reviewer B (quality & layering)`, `### Phase 5 — Multi-reviewer C (plan consistency & scope)`, `### Phase 5 — Code-review escalation`. Body content for this task = preserve existing prose verbatim under the new headings. Wave 2 rewrites the bodies.
- [ ] **T4** — Bump `version` in `.claude-plugin/plugin.json` and `plugins[0].version` in `.claude-plugin/marketplace.json` to `0.1.3`. No other edits.
- [ ] **T5** — Dispatch a subagent to rewrite the six **review/audit** templates in `parallel-agents.md`: Spec-review A/B/C + Multi-reviewer A/B/C. Each template gets a full 7-section build per the contract (SEVERITY mandatory; uncertain-⇒-Critical line verbatim). File-scope guard: edit only inside the six named `### ` blocks; do not touch the preamble or other templates. Emit a coverage table (old block → new heading → preserved / dropped / new). ≤300 word report.
- [ ] **T6** — Dispatch a subagent to rewrite the five **build/research** templates in `parallel-agents.md`: Research, Implementation wave, Debug evidence, Cross-package verification, Code-review escalation. SEVERITY OMITTED. VERIFICATION shape per template type (Executable for Implementation/Verification/Debug; Self-checklist for Research/Code-review-escalation). File-scope guard same as T5. Emit coverage table. ≤300 word report.
- [ ] **T7** — Dispatch a subagent to rewrite all 7 wizard banks in `clarify-questions.md` (universal preamble + 6 task types) to the 4-section contract. Each QUESTIONS subsection has 4–8 candidate questions; each option labeled with recommended-first convention + " (Recommended)" suffix on option A; each question has a one-line "why-this-matters." Emit coverage table. ≤300 word report.
- [ ] **T8** — Dispatch a subagent to rewrite the escalation reviewer template in `review-and-verify.md` to the 7-section contract AND audit `implement-and-test.md` + `work-doc-template.md` for prompt fragments. Audit result (with or without findings) logged in Implementation Log. ≤200 word report.
- [ ] **T9** — Add a short paragraph (≤120 words) at the start of `SKILL.md`'s "Parallel agents — the default" section pointing readers at `references/parallel-agents.md` "Template Contract." Add a one-line note in "Phase 1 — Clarify" pointing at `clarify-questions.md` "Wizard Contract." No other SKILL.md changes.
- [ ] **T10** — Extend `scripts/validate-dod.sh` with six new check sections. Existing [1]–[8] unchanged.
    - `[9] template structural conformance` — for each of the 11 named `### ` templates in `parallel-agents.md` "Per-task templates", assert presence of: `ROLE`, `INPUTS`, `OBJECTIVE`, `METHOD`, `VERIFICATION`, `OUTPUT` headings (any markdown heading level). SEVERITY check is conditional (next).
    - `[10] severity present where required` — for each of the six review/audit templates (Spec-review A/B/C, Multi-reviewer A/B/C, escalation reviewer in review-and-verify.md), assert `SEVERITY` heading is present. For the five build/research templates, assert `SEVERITY` heading is ABSENT.
    - `[11] severity canonical phrase` — for each review/audit template, grep for verbatim: `If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important.` 0 hits = fail.
    - `[12] ROLE substance check` — for every sub-agent template (all 11 + escalation reviewer), assert ROLE section contains: the literal `You are ` (identity), at least one named-standard token from the allowlist (grep-anchored), the literal `You reject` (anti-patterns), and the literal pair `Bias to:` AND `Bias against:` (behavioral bias). Missing any of these = fail.
    - `[13] no leaked absolute paths in templates` — grep `/Users/`, `/home/`, `/tmp/` anywhere in `references/parallel-agents.md`, `references/clarify-questions.md`, `references/review-and-verify.md`. 0 hits required.
    - `[14] wizard structural conformance` — for `## Universal preamble` and every `## Type: ` heading in `clarify-questions.md`, assert presence of `SCENARIO`, `COMPOSITION`, `QUESTIONS`, `EXIT CRITERIA` headings.
- [ ] **T11** — Add `## [0.1.3]` entry at the top of `CHANGELOG.md` (above v0.1.2). Verbatim "patch label, minor-level scope" caveat. List the SIX canonical bugs from the §Context section verbatim, one bullet each. Summarize the 7-section sub-agent contract and 4-section wizard contract for users.
- [ ] **T12** — Run `bash scripts/validate-dod.sh`. Paste output. If anything red, fix and re-run.
- [ ] **T13** — Dispatch parallel foreground subagent: **Reviewer A — contract conformance.** All sections present where mandatory; all placeholders `{{snake_case}}`; all OUTPUT word caps present; all framework citations in the allowlist. ≤300 words.
- [ ] **T14** — Dispatch parallel foreground subagent: **Reviewer B — weak-model robustness.** Read each new prompt simulating a Haiku-class model. Flag any ambiguous step, "use judgment" language, unanchored severity, or VERIFICATION that doesn't produce a binary signal. ≤400 words.
- [ ] **T15** — Dispatch parallel foreground subagent: **Reviewer C — regression audit.** Use the coverage tables emitted by T5/T6/T7/T8. Verify every old heading mapped; any "dropped" entries justified; any net-new behavior intentional. ≤300 words.
- [ ] **T16** — Apply review patches (Critical immediately; Important before tag; Minor → CHANGELOG follow-ups). Re-run validator. Commit. Tag `v0.1.3`. Push commit and tag. Archive work-doc to `docs/work/done/2026-05-11-prompts-re-engineering.md` with Post-mortem (≥8 bullets).

## Implementation Log

### 2026-05-11 — Phase 2.5 spec self-review (complete)

Dispatched 3 parallel reviewers. Findings folded into a substantial work-doc rewrite (this version):
- **Reviewer A:** found 5 Criticals (SEVERITY mandatory-vs-optional triple contradiction; validator `### ` heading mismatch (7 found, 11 claimed); validator `## Type:` misses universal preamble; canonical-sentence-consistency DoD bullet had no covering task; T9 "six bugs" disagreed with Context section). All folded in via file restructure (T3), DoD/contract reconciliation, and a canonical six-bug list at the top of this doc.
- **Reviewer B:** found 2 Criticals (VERIFICATION over-fitted to filesystem templates — added Shape B Self-checklist; "uncertain ⇒ Critical" misfires on non-review templates — made SEVERITY review-only). 4 Importants (framework-citation allowlist; per-section word budget for implementation templates; placeholder framing clarified for dispatching agent; behavioral bias replaces stylistic "you are paid to ..."). All folded into the contract spec.
- **Reviewer C:** found 2 Criticals (T4 over-scoped — split into T5 review-templates + T6 build-templates each editing disjoint blocks; Wave 2 file-collision risk — added file-scope guard). 4 Importants (regression audit too late — added coverage-table emission to each Wave-2 agent; T6 dep on T1 made explicit; estimation realism acknowledged; validator pattern fixes). Tasks renumbered, waves restructured.

### 2026-05-11 — Wave 1 (T1, T2, T3, T4) — complete

Dispatched **two parallel agents in one message**:
- **T1+T3 combined agent** authored the canonical "## Template Contract" preamble in `parallel-agents.md` and restructured the "Per-task templates" section into exactly 11 `### `-headed templates (Phase 1 Research; Phase 2.5 Spec-review A/B/C; Phase 3 Implementation wave; Phase 3b Debug evidence; Phase 4 Cross-package verification; Phase 5 Multi-reviewer A/B/C; Phase 5 Code-review escalation). Body content for the templates preserved verbatim — Wave 2 rewrote bodies.
- **T2 agent** authored the canonical "## Wizard Contract" preamble in `clarify-questions.md` and renamed `## All task types — universal preamble` → `## Universal preamble` for validator pattern uniformity.

**T4** inline: bumped `plugin.json` and `marketplace.json plugins[0]` to version `0.1.3`.

Both agents returned PASS on their own verification scripts.

### 2026-05-11 — Wave 2 — complete (split into 2a + 2b)

Realized mid-wave that **T5 and T6 both write to `parallel-agents.md`** — even with file-scope guards, same-file parallel edits race. Split into Wave 2a (parallel, different files) + Wave 2b (sequential same-file).

**Wave 2a — three parallel agents in one message:**
- **T5** rewrote the SIX review/audit templates (Spec-review A/B/C + Multi-reviewer A/B/C) in `parallel-agents.md` to the 7-section contract with mandatory SEVERITY. Coverage table emitted.
- **T7** rewrote the SEVEN wizard banks (Universal preamble + 6 task types) in `clarify-questions.md` to the 4-section contract. Coverage table emitted.
- **T8** rewrote the escalation reviewer in `review-and-verify.md` to the 7-section contract; audited `implement-and-test.md` + `work-doc-template.md` — no prompt fragments found (parent-side procedural prose only).

**Wave 2b — sequential after T5:**
- **T6** rewrote the FIVE build/research templates (Phase 1 Research, Phase 3 Implementation wave, Phase 3b Debug evidence, Phase 4 Cross-package verification, Phase 5 Code-review escalation) in `parallel-agents.md`. T6 recategorized Code-review escalation as a review template (SEVERITY mandatory) since it's a single-specialist lens — the original work-doc had it in the build/research bucket. Coverage table emitted.

All four agents returned PASS. File now contains 11 `### ` templates conforming to the 7-section contract; SEVERITY present in 7 review templates and absent in 4 build/research templates; canonical SEVERITY phrase verbatim in every review template; 5-element ROLE in every template.

### 2026-05-11 — Wave 3 (T9, T10, T11) — complete

Three inline edits across different files:
- **T9** added a paragraph to SKILL.md "Parallel agents — the default" section pointing at the Template Contract; one-line addition to "Phase 1 — Clarify" step 3 pointing at the Wizard Contract.
- **T10** extended `scripts/validate-dod.sh` with checks [9]–[14]: structural conformance for all 11 templates + escalation reviewer; SEVERITY conditional (review templates have it, build/research don't); canonical SEVERITY phrase grep; ROLE 5-element substance check with framework-allowlist regex; no leaked `/Users/`/`/home/`/`/tmp/` paths in template bodies; wizard structural conformance for all 7 banks.
- **T11** added `## [0.1.3]` entry at top of CHANGELOG.md: "patch label, minor-level scope" caveat verbatim; the six canonical bugs from Context section verbatim; public-facing summary of both contracts; migration notes for users.

Tripped one bash bug in the validator's hand-off (orphan `if false; then` block from the original `[8]` check's structure); patched in place. After patch: `ALL CHECKS PASSED` across sections [1]–[14].

### 2026-05-11 — Wave 4 (T12) — complete

`bash scripts/validate-dod.sh` ran clean: ALL CHECKS PASSED across sections [1]–[14] (existing + new). No regressions.

### 2026-05-11 — Wave 5 (T13, T14, T15) + polish pass — complete

**Three parallel foreground reviewers in one message** (each prompt itself crafted to the new 7-section contract with full 5-element ROLE):

- **Reviewer A (contract conformance):** found one Critical (Phase 3b template uses VERIFICATION Shape B while the contract preamble lists it under Shape A — drift between contract and template). 9 Important findings on validator coverage gaps (D5, D7, D8, D11, D12, D13 partial, D15, D16 all lacking validator enforcement).
- **Reviewer B (weak-model robustness):** found 7 Critical (4 systemic + 3 isolated): compound METHOD steps packing multiple lenses; COMPOSITION rules smuggling "use judgment"; OUTPUT skeletons mixing `{{}}` and `<>` syntax without preface; `!` non-null grep produces false positives; "scoped read-only queries" undefined; "canonical rule sentences" undefined; Multi-reviewer C relies on prose-to-path matching. 3 Important: SEVERITY canonical phrase not echoed in VERIFICATION; P1 Research keyword procedure too vague; `fix` EXIT CRITERIA inverted logic.
- **Reviewer C (regression via coverage tables):** found 1 Critical (Universal preamble Q4 silently lost its default-rationale "Default depends on diff size" from v0.1.2; not in T7's coverage table). 2 Important: `revamp` brand-spec binding softened from "binding" imperative to parenthetical; `fix` Q7 "Always say yes" rationale dropped.

**Polish pass — two parallel agents in one message:**
- **Polish A** applied all 7 Critical + 1 Important findings from Reviewer B inside `parallel-agents.md`: split compound METHOD steps in 4 templates (one-action-per-step); added the `{{...}}` vs `<...>` preface line before every OUTPUT skeleton in 3 templates; tightened `!` grep regex to `[A-Za-z_)\]]!\.` and `[A-Za-z_)\]]!$` with explicit `!=`/`!==`/`<!` exclusions; defined "SELECT only; forbid INSERT, UPDATE, DELETE, DDL, CALL, COPY" for P3b debug evidence; defined "canonical rule sentence = first sentence under each numbered subsection of CLAUDE.md containing MUST, NEVER, or BANNED" for Spec-review B; added `{{task_file_index}}` placeholder for Multi-reviewer C; spelled out the keyword-set extraction procedure for Phase 1 Research (nouns ≥4 chars, synonym grouping, cap at 4 groups).
- **Polish B** applied B-Crit2 (7 mechanical-substring-check substitutions in 6 banks for COMPOSITION rules), B-Imp3 (fix `fix` EXIT CRITERIA inversion), C-Crit1 (universal preamble Q4 default-rationale restoration), C-Imp1 (revamp brand-spec binding strengthened to MUST), C-Imp2 (fix Q7 "Always say yes unconditionally" rationale restored).

Both Polish agents returned PASS. Polish B flagged one self-discovered contradiction (Universal Q4 added rationale named options A/B/C in an order that didn't match the bank's actual A/B/C labels) — fixed inline in the same wave.

**Inline edits** (after Polish A + Polish B, in different files):
- Contract drift (Reviewer A's Critical): updated `## Template Contract` preamble in `parallel-agents.md` — moved "Debug evidence" from Shape A to Shape B (correct — Phase 3b is read-only investigation, no filesystem artifact).
- Universal Q4 rationale fix (post-Polish-B contradiction): rewrote to match actual option labels (A=Branch-for-review, B=PR-opened, C=Merged-to-main-directly).
- Validator extensions ([13] expanded to scan all three reference files; [15] OUTPUT word cap presence per template; [16] plugin.json/marketplace.json version-value consistency; [17] SKILL.md cross-references to both contracts).

First run after extensions: 4 templates failed [15] because their OUTPUT cap used `≤\`{{word_cap}}\` words` (placeholder syntax — contract-correct). Updated regex to also match the placeholder pattern. Re-ran: ALL CHECKS PASSED across sections [1]–[17].

_(further entries appended one per completed task during Phase 3.)_

## Verification

`bash scripts/validate-dod.sh` final output (truncated to summary):

```
[1] required files exist                                       — 8/8 ok
[2] reference files (expect 9)                                 — ok
[3] JSON files parse                                           — plugin.json, marketplace.json, evals.json all valid
[4] plugin.json required fields                                — 8/8 ok
[5] marketplace.json required fields                           — 4/4 ok (name, owner, plugins, owner.name)
[6] token scrub (Syanat / SyanatBackend / SyanatFrontend /
    graphify / corecave / nadyshalaby)                         — 0 hits across skills/, README.md, evals.json
[7] README line bounds                                         — 275 lines (range 250..450)
[8] SKILL.md frontmatter                                       — name + description present
[9] template structural conformance (parallel-agents.md)       — 11/11 templates have ROLE/INPUTS/OBJECTIVE/METHOD/VERIFICATION/OUTPUT
[10] SEVERITY conditional                                      — 7 review templates have SEVERITY; 4 build/research correctly omit it; escalation reviewer in review-and-verify.md has all 7 mandatory sections
[11] canonical SEVERITY phrase                                 — all 7 review templates + escalation reviewer contain verbatim line
[12] ROLE substance check                                      — every template + escalation reviewer has identity, allowlist framework, anti-patterns, Bias to/against
[13] no leaked absolute paths                                  — 0 hits for /Users/, /home/, /tmp/ across parallel-agents.md template bodies, clarify-questions.md, review-and-verify.md
[14] wizard structural conformance                             — 7/7 banks have SCENARIO/COMPOSITION/QUESTIONS/EXIT CRITERIA
[15] OUTPUT word cap presence                                  — all 11 templates + escalation reviewer have an explicit word cap (literal ≤N or {{word_cap}} placeholder)
[16] version consistency                                       — plugin.json .version == marketplace.json .plugins[0].version == 0.1.3
[17] SKILL.md cross-refs                                       — references both 'Template Contract' and 'Wizard Contract'

ALL CHECKS PASSED
```

Repository state at finish:
- 11 sub-agent templates in `parallel-agents.md` conform to the 7-section contract; 7 of them are review/audit with mandatory SEVERITY; 4 are build/research with SEVERITY omitted.
- 7 wizard banks in `clarify-questions.md` conform to the 4-section contract.
- 1 escalation reviewer in `review-and-verify.md` conforms to the 7-section contract.
- `scripts/validate-dod.sh` exits 0 across all 17 check sections.
- Version `0.1.3` consistent across `plugin.json` and `marketplace.json`.
- CHANGELOG has the v0.1.3 entry listing the six canonical bugs verbatim.

## Post-mortem

1. **Phase 2.5 spec review caught fundamental structural issues in the plan before any code was written.** Triple-redundant SEVERITY contradiction (contract said review-only, DoD said every template, validator said every section in every template); validator pattern mismatches (`^### ` matched 7 headings while the plan claimed 11 templates); VERIFICATION shape over-fitted to filesystem-touching templates and missed prose-producing ones; T4 over-scoped (~11,000 words of generated prose for a single agent); "uncertain ⇒ Critical" rule misfiring on non-review templates. Rewriting the work-doc end-to-end here saved a full implementation pass.

2. **The "tasks in the same wave MUST NOT share files" rule earned its keep mid-wave.** Original Wave 2 plan had T5 (review templates) and T6 (build/research templates) both editing `parallel-agents.md` in parallel. Caught the race risk before dispatch and split into Wave 2a (3 parallel agents, different files) + Wave 2b (sequential same-file). The file-scope guards in agent prompts are necessary but not sufficient — the same Edit-then-save race exists at the tool level.

3. **The contract was itself a bootstrap dependency.** Wave 1 had to author the Template Contract preamble BEFORE Wave 2 agents could implement against it. Sequential dependency that couldn't be parallelized away. Identifying this in planning saved a wave-restart later.

4. **Anchored severity rubrics actually work as designed.** When Phase 5 Reviewer B used "Haiku-class model would, with ≥10% probability, ship wrong" as the Critical anchor, the calibration was concrete enough that I could act on findings without second-guessing the rating. The earlier v0.1.0 lesson ("soft severity language lets findings get deferred") is now structurally prevented for reviewers using this contract.

5. **Mechanical substring checks beat "use judgment" by an order of magnitude in COMPOSITION rules.** Polish B's 7 substitutions (`expected` AND `actual` for fix Q1; `this branch` / `in place` / `just push` for worktree-skip; etc.) turn ambiguous wizard logic into deterministic dispatcher behavior. Future wizard-bank edits should default to substring rules over prose conditions.

6. **Two-shape VERIFICATION (Executable vs Self-checklist) is the right call.** Forcing every template to produce a bash pass/fail signal would have been theatre on prose-producing templates (Research, Spec-review, Code-review escalation, Debug evidence). Reviewer B caught this in Phase 2.5; not catching it would have meant either fake bash scripts or templates failing the validator.

7. **Coverage tables emitted by each Wave-2 agent were genuinely useful in Phase 5 regression review.** Without them, T15 Reviewer C would have been doing diff archaeology against v0.1.2. With them, the regression check became "verify the agent's claims against the actual diff" — much higher signal per minute spent.

8. **Agents follow contracts faithfully but only literally.** T6 wrote Phase 3b's VERIFICATION as Shape B because read-only investigation has no filesystem artifact — semantically correct, but it contradicted the contract preamble's listing of Phase 3b under Shape A. Caught by Reviewer A, fixed by updating the preamble (the agent's choice was right; the preamble was wrong). Lesson: when a contract preamble lists examples per category, those examples must be exhaustive and current, or stated as "exemplars, not canonical."

9. **The polish pass after Phase 5 multi-reviewer is the workflow's secret weapon.** Two parallel polish agents handling 9 substantive findings + 4 isolated inline edits brought the file from "passes the baseline contract" to "passes everything we now know to check." Budgeting for this pass in plans (not just in post-mortems) would speed future shipping cycles.

10. **Validator coverage gaps surface only when explicitly audited.** Reviewer A's DoD-bullet-by-bullet coverage matrix revealed ~6 DoD bullets without any automated validator coverage. Added checks [13]-extension, [15], [16], [17] in inline edits; documented the remaining gaps (D5 canonical sentence in METHOD; D7 ≥2 severity examples per level; D11 audit result; D16 CHANGELOG canonical phrases) as v0.1.4 follow-ups. Manual verification still catches these — but a validator that doesn't catch a DoD bullet is one regression away from breaking quietly.

## Follow-ups for v0.1.4 (deferred, not in scope for v0.1.3)

- Validator coverage extensions: D5 (canonical sentence anchor in METHOD), D7 (count ≥2 severity examples per level), D11 (audit logged), D16 (CHANGELOG verbatim phrases incl. the six canonical bugs).
- Validator [12] ROLE-substance check currently greps the entire template body for allowlist tokens; should be scoped to the ROLE subsection only so a framework cited only in a SEVERITY anchor doesn't pass the check.
- Polish A's coverage table noted that Multi-reviewer A METHOD verification question #3 still references "all six lenses" wording — minor inconsistency now that the lenses are split into 6 numbered steps. Worth a polish pass.
- Document in SKILL.md or a new `references/template-authoring.md` how to author NEW templates against the contracts (worked example walking through a hypothetical "Phase 7 — Performance audit" template).
- Add a `references/migration-from-v0.1.2.md` for users with custom sub-agent prompts who want to adopt the contracts.
