# Type: `debug`

Phase 1 loads this bank when the user has a mystery to solve rather than a clear ask — intermittent failures, weird behavior with no reliable reproduction. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when the user has a mystery to solve rather than a clear ask — weird behavior with no reliable reproduction, intermittent failures, "sometimes X happens and I don't know why." Triggers on patterns like "I'm seeing weird X", "sometimes Y fails", "I can't figure out why", "no error but Z is wrong". Phase 3b's 4-phase debugging method runs during clarify; evidence gathering is part of Phase 1.

**COMPOSITION**

- Q1 wording mirrors `fix` Q1 by design — keep in sync if either is edited.
- Skip Q1 (Reproduction shape) if the user prompt contains BOTH `expected` AND `actual` (same rule as `fix` Q1); else ask Q1 as discovery.
- Always ask Q2 (Evidence collected) and Q3 (Hypotheses tried) — they prevent us from re-running work the user already did.
- Always ask Q4 (Instrumentation boundary) — gates whether Phase 3b can add logs/telemetry.
- Always ask Q5 (Outcome) — determines Phase 6's exit shape.
- Always ask Q6 (Time-box) — debug tasks have the highest risk of unbounded exploration.

**QUESTIONS**

Q1 — Reproduction shape
- Text: How reliable is the current reproduction?
- Header: Repro
- Options:
  - A. Reliable — I can reproduce on demand (Recommended)
  - B. Intermittent — happens but not predictably
  - C. Once-only — no current reproduction
- Why-this-matters: Reliable repro skips Phase 3b's evidence-gathering loop; intermittent/once-only triggers instrumentation-first investigation.

Q2 — Evidence collected
- Text: What logs / stack traces / screenshots have you already gathered?
- Header: Evidence
- Options:
  - A. I'll paste them now in chat (Recommended)
  - B. None yet — I need help collecting
  - C. Some collected — I'll describe what's missing
- Why-this-matters: Determines whether Phase 3b starts from a known-evidence baseline or from zero.

Q3 — Hypotheses tried
- Text: What have you already tried, and what was the outcome?
- Header: Tried
- Options:
  - A. I'll list attempts and outcomes now in chat (Recommended)
  - B. Nothing tried yet — fresh investigation
  - C. Tried many things, lost track — start over
- Why-this-matters: Prevents Phase 3b from re-running failed approaches and seeds the hypothesis list.

Q4 — Instrumentation boundary
- Text: May I add instrumentation (logs, telemetry, breakpoints) as part of the investigation?
- Header: Instrument
- Options:
  - A. Yes — add freely, I'll remove after (Recommended)
  - B. Yes, but only with a temporary feature-flag / DEBUG guard
  - C. No — read-only investigation
- Why-this-matters: Sets Phase 3b's evidence-gathering toolkit and whether Phase 6 includes a "remove instrumentation" cleanup task.

Q5 — Outcome
- Text: What outcome do you want from this investigation?
- Header: Outcome
- Options:
  - A. Root cause identified + fix shipped (Recommended)
  - B. Root cause identified + handed back to you
  - C. Mitigation now, deeper investigation later
- Why-this-matters: Determines Phase 6's exit shape (fix lands vs. report-only vs. mitigation + follow-up doc).

Q6 — Time-box
- Text: How long are you OK with this investigation running before we stop and reassess?
- Header: Time-box
- Options:
  - A. 2-4 hours, then checkpoint (Recommended)
  - B. Half a day, then checkpoint
  - C. As long as it takes — no time-box
- Why-this-matters: Phase 3b inserts a hard checkpoint at the named duration; without it, debug tasks run unbounded.

**EXIT CRITERIA**

Q1, Q2, Q3, Q4, Q5, Q6 all answered; evidence pasted (or "none yet" explicitly confirmed); hypotheses-tried list captured; instrumentation boundary recorded so Phase 3b knows its toolkit; the work-doc Approach section is replaced by an Investigation Plan with components-to-instrument, evidence-to-gather, and hypotheses-to-test in order.
