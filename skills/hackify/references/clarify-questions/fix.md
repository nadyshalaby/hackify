# Type: `fix`

Phase 1 loads this bank when the user is reporting broken behavior with a clear reproduction. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when the user is reporting broken behavior — an observable defect, a stack trace, a flow that no longer produces the expected outcome. Triggers on patterns like "X is broken", "Y doesn't work", "throws an error", "regressed since...". Not for mysteries with no clear reproduction (that's `debug`).

**COMPOSITION**

- Skip Q1 (Reproduction shape) and confirm if the user prompt contains BOTH the substring `expected` AND `actual`.
- Skip Q2 (Frequency) if the user prompt contains any of the literal substrings `always`, `every time`, `intermittently`, `once`, or `sometimes`.
- Skip Q3 (Recent changes) if the user prompt contains any of `started failing`, `regressed`, `after the`, `since we merged`.
- Always ask Q4 (Regression scope) — silently affected flows are the top source of incomplete fixes.
- Always ask Q5 (Severity) — it determines polish-vs-ship tradeoff.
- Always ask Q6 (Solution shape) — it gates whether Phase 3 dispatches a refactor sub-agent.
- Always ask Q7 (Regression test) — defaults to A; the only gate that prevents silent re-breakage. Q1 wording aligns with `debug` Q1 by design (keep in sync if either is edited).

**QUESTIONS**

Q1 — Reproduction shape
- Text: How is the reproduction already specified?
- Header: Repro
- Options:
  - A. Prompt has full steps + expected + actual — confirm and proceed (Recommended)
  - B. I'll walk through the repro now in chat
  - C. No reliable repro yet — switch to `debug` flow
- Why-this-matters: Routes the task: stay in `fix` flow vs. escalate to `debug` (Phase 3b evidence-gathering).

Q2 — Frequency
- Text: How often does this defect occur?
- Header: Frequency
- Options:
  - A. Always reproducible (Recommended)
  - B. Intermittent / flaky
  - C. Happened once
- Why-this-matters: Intermittent/once-only routes require evidence gathering in Phase 3b before patching.

Q3 — Recent changes
- Text: Is the regression linked to a recent change?
- Header: Trigger
- Options:
  - A. Known trigger (deploy / dep upgrade / config change) (Recommended)
  - B. No known trigger — appeared on its own
  - C. Unknown — needs git-bisect or log review
- Why-this-matters: Determines whether Phase 1 ends with a bisect step or jumps directly to root-cause analysis.

Q4 — Regression scope
- Text: What is the blast radius of this defect?
- Header: Blast radius
- Options:
  - A. Just this one flow (Recommended)
  - B. This flow plus a small set of related flows
  - C. Cross-cutting — multiple unrelated areas affected
- Why-this-matters: Decides whether Phase 4 cross-package verification runs and whether the fix needs a feature-flag rollback path.

Q5 — Severity
- Text: How urgent is this fix?
- Header: Severity
- Options:
  - A. Production blocker — minimum viable fix now (Recommended)
  - B. Important but not blocking — polish acceptable
  - C. Nice-to-have — can be batched with other work
- Why-this-matters: Trades off Phase 3 minimum-diff vs. broader refactor and whether Phase 6 fast-paths to a hotfix tag.

Q6 — Solution shape
- Text: What shape should the fix take?
- Header: Fix shape
- Options:
  - A. Small targeted patch + regression test (Recommended)
  - B. Broader refactor of the broken area (more risk, more value)
  - C. Workaround now + follow-up work-doc filed
- Why-this-matters: Determines whether Phase 3 dispatches a single implementation agent or also a refactor agent.

Q7 — Regression test
- Text: Should a regression test be added that fails before the fix and passes after?
- Header: Regression
- Options:
  - A. Yes — write the failing test first (Recommended)
  - B. No — fix only, no new test
- Why-this-matters: Determines whether Phase 3 starts with a RED test step (TDD) or skips straight to the patch. A regression test that fails before the fix and passes after is the only way to prove the bug is actually fixed. Recommend A (yes) unconditionally unless the user prompt contains `no test`, `quick fix only`, or `can't test`.

**EXIT CRITERIA**

Q4, Q5, Q6, Q7 answered (always required); for Q1, Q2, Q3: either the question was answered OR its COMPOSITION skip condition fired and was logged; if Q1 = C, the task is re-routed to the `debug` bank and this bank's exit is bypassed; regression-test decision captured in the work-doc.
