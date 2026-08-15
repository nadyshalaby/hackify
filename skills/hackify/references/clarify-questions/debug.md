# Type: `debug`

Phase 1 loads this bank when the user has a mystery to solve rather than a clear ask, intermittent failures, weird behavior with no reliable reproduction. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when the user has a mystery to solve rather than a clear ask, weird behavior with no reliable reproduction, intermittent failures, "sometimes X happens and I don't know why." Triggers on patterns like "I'm seeing weird X", "sometimes Y fails", "I can't figure out why", "no error but Z is wrong". Phase 3b's 4-phase debugging method runs during clarify; evidence gathering is part of Phase 1.

**COMPOSITION**

- Q1 wording mirrors `fix` Q1 by design, keep in sync if either is edited.
- Skip Q1 (Reproduction shape) if the user prompt contains BOTH `expected` AND `actual` (same rule as `fix` Q1); else ask Q1 as discovery.
- Always ask Q2 (Evidence collected) and Q3 (Hypotheses tried), they prevent us from re-running work the user already did.
- Always ask Q4 (Instrumentation boundary), gates whether Phase 3b can add logs/telemetry.
- Always ask Q5 (Outcome), determines Phase 6's exit shape.
- Always ask Q6 (Time-box), debug tasks have the highest risk of unbounded exploration.

**QUESTIONS**

Every question below is a TEMPLATE. Substitute the real names, files and current behavior you found before sending it, so the user can answer without opening anything. Angle-bracket slots are yours to fill. `What happens:` lines are mandatory and are what the user reads.

Q1. Can you make it happen on demand
- Text: Can you make `<the problem, in their words>` happen again reliably by repeating the same steps?
- Header: Repeatable
- Options:
  - A. Yes, every time (Recommended)
    - What happens: I reproduce it myself first. That's the fastest possible route, because I can test each theory directly.
  - B. Sometimes, but not predictably
    - What happens: I add temporary logging to catch it in the act. Slower, but guessing at an intermittent problem usually fixes nothing.
  - C. It happened once and I can't repeat it
    - What happens: I work backwards from whatever evidence exists. I'll tell you honestly if there isn't enough to be sure.
- Why-this-matters: A reliable repro skips Phase 3b's instrumentation-first loop; B and C require evidence gathering before any hypothesis.

Q2. What you already have
- Text: Do you have anything saved from when it went wrong, like an error message, a screenshot, or server logs?
- Header: Evidence
- Options:
  - A. Yes, I'll paste it now (Recommended)
    - What happens: This usually cuts the search dramatically. Even a partial error message narrows it a lot.
  - B. No, nothing saved
    - What happens: I'll tell you exactly what to capture next time it happens, and start from the code meanwhile.
  - C. Some of it, I'll describe what's missing
    - What happens: I'll work with what you have and say clearly what would speed things up.
- Why-this-matters: Determines whether Phase 3b starts from a known-evidence baseline or from zero.

Q3. What you already ruled out
- Text: Have you already tried anything to fix this? Knowing what didn't work saves me repeating it.
- Header: Already tried
- Options:
  - A. Yes, I'll tell you what I tried (Recommended)
    - What happens: I skip those paths and start from where you left off.
  - B. Nothing yet, this is fresh
    - What happens: I start from the beginning with no assumptions.
  - C. I tried a lot and lost track
    - What happens: I'll start clean and work methodically rather than trusting a half-remembered list.
- Why-this-matters: Prevents Phase 3b from re-running failed approaches and seeds the hypothesis list.

Q4. Can I add temporary logging
- Text: To find this, I often need to add temporary logging that prints what the code is doing at each step. It gets removed before anything ships. Is that OK?
- Header: Logging
- Options:
  - A. Yes, go ahead (Recommended)
    - What happens: Much faster diagnosis. I remove every line of it before finishing and prove it's gone.
  - B. Yes, but keep it switched off by default
    - What happens: Slightly slower, but nothing extra ever prints in production.
  - C. No, just read the code
    - What happens: I work from the code alone. Slower and less certain, especially for anything timing-related.
- Why-this-matters: Sets Phase 3b's evidence toolkit and whether Phase 6 Step C.5 carries a remove-instrumentation cleanup item.

Q5. How far you want me to go
- Text: Once I find the cause, do you want me to fix it too, or stop and tell you first?
- Header: Outcome
- Options:
  - A. Find it and fix it (Recommended)
    - What happens: I keep going through to a tested fix and show you the proof it works.
  - B. Find it and explain it, I'll decide on the fix
    - What happens: You get a clear write-up of the cause and your options, with no code changed.
  - C. Get it working now, investigate properly later
    - What happens: I stop the bleeding today and write down what still needs a real fix.
- Why-this-matters: Determines Phase 6's exit shape (fix lands vs report-only vs mitigation plus a follow-up entry).

Q6. When I should check back
- Text: Investigations can run long. At what point do you want me to stop and report what I've found, even if I haven't cracked it?
- Header: Check-in
- Options:
  - A. After a couple of hours of digging (Recommended)
    - What happens: You get an honest progress report and can redirect me before more time goes in.
  - B. After half a day
    - What happens: More room to chase a hard one, less frequent updates.
  - C. Keep going until it's solved
    - What happens: No interruptions. Be aware a genuinely hard bug can absorb a lot of time this way.
- Why-this-matters: Phase 3b inserts a hard checkpoint at the named duration; without it, debug tasks run unbounded past the 3-hypothesis circuit breaker.

**EXIT CRITERIA**

Q1, Q2, Q3, Q4, Q5, Q6 all answered; evidence pasted (or "none yet" explicitly confirmed); hypotheses-tried list captured; instrumentation boundary recorded so Phase 3b knows its toolkit; the work-doc Approach section is replaced by an Investigation Plan with components-to-instrument, evidence-to-gather, and hypotheses-to-test in order.
