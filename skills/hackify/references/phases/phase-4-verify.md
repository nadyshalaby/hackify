# Phase 4, Verify (evidence before claims + the ship gate)

Loaded by `SKILL.md` when this phase opens. The phase's entry conditions, hard gates and exit artifact are stated in `SKILL.md`; this file is the protocol.

**Goal.** Prove every task and requirement landed AND that the app actually runs. Evidence before claims. Three parts, full spec in `references/review-and-verify.md`.

**Ledger, at phase open.** Set the phase ledger's `Phase 4. Verify (Evidence Ledger + triad green)` to in-progress in the work-doc's `## 0. Phase ledger` block, with frontmatter `status: verifying` in the same edit, and re-print the whole block after that edit is saved. Never open it while `Phase 3. Implement` is still open. That is the **phase** ledger, a different artifact from the Evidence Ledger this phase builds. Contract: [../phase-ledger.md](../phase-ledger.md).

**Part 1. Evidence Ledger (per-item proof).** One row per Sprint Backlog task AND per Acceptance-Criteria bullet: `Item | Type | Claim | What I ran | Proof sample | Result`. The proof sample is a REAL, trimmed slice of output, never a summary, never invented. A missing or ❌ row blocks Phase 5. The ledger is saved in the work-doc Sprint Review and rendered again in the Phase 6 HTML report's evidence appendix (cumulative proof in one place).

**Part 2. Three-layer re-verify (prove it without drifting).** Run in order; re-run any layer on demand when the user says "prove it again".

| Layer | What | Runs in |
|---|---|---|
| 1 Fresh triad | test + lint + typecheck from a clean state (all packages, no warm cache) | all |
| 2 Goal-drift re-check | trace every proof to the North-Star Goal + Success Signals in the anchor; a signal with no proving row = not done | all |
| 3 Independent re-prove | re-earn the proof without trusting Layer 1, clean re-run or a fresh subagent | hackify |

**Part 3. Ship gate (prove it runs).** A green triad says the code is well-formed, not that it starts. Run three legs and record one ledger row each: `ship.build` (builds clean from a cold cache, artifact on disk), `ship.boot` (starts, reaches a real ready signal, tears down clean), `ship.smoke` (the critical path this sprint touched works against the running app). **A leg is blocking whenever the diff touched something that leg's target consumes (source the build compiles, config read at startup, the touched flow); a written `⏭ skipped` row with the reason otherwise; never silently absent.** The trigger is the diff, not whether a run command exists, so a docs-only change records skips rather than booting the app. Detection table per ecosystem, readiness-probe rules, and the secrets/state guards: [references/ship-gate.md](../ship-gate.md). Runs in every mode, quick included.

**Top-level acceptance rows (each appears in the ledger):**

- [ ] All tests pass, fresh test output (exit 0, 0 failures, 0 errors)
- [ ] Linter clean, fresh lint output (0 errors)
- [ ] Typecheck clean, fresh typecheck output (0 errors)
- [ ] All `Sprint Backlog` checkboxes ticked
- [ ] Every Phase 2 acceptance bullet has a ledger row with a proof sample
- [ ] No placeholders, no `TODO` without owners, no `console.log`/`println!`, no commented-out code
- [ ] No new lint or type-checker suppressions (inline ignore directives, file-level disables, expect-error pragmas outside test files), zero tolerance
- [ ] No new `!` non-null assertions in production code
- [ ] Perf-scout AND law-scout run on the sprint diff, every candidate dispositioned (fixed / staged / false-positive with reason)
- [ ] No new Critical or Important violation of `rules/performance.md` (Reviewer D confirms in Phase 5)
- [ ] No new Critical or Important violation of the engineering law (Reviewer B confirms the law-scout rows in Phase 5)
- [ ] Ship gate: `ship.build`, `ship.boot`, `ship.smoke` rows all present, each ✅ or `⏭ skipped` with a written reason
- [ ] Manual smoke check (if user opted in), list steps and outcomes

**On any red, do NOT advance to Phase 5.** Loop back to Phase 3 (or 3b if stuck).

**Ledger, at phase exit.** A proof row per task and per acceptance bullet, a green fresh triad, and all three ship-gate rows present first, then one line of reflection (what changed, did it pass, what is next), then tick the phase ledger's `Phase 4. Verify` and open `Phase 5. Review (decision table empty)` in the work-doc's section 0, saved before the re-print. A ship-gate leg that does not apply is a written `⏭ skipped` row carrying its reason, never a missing row.
