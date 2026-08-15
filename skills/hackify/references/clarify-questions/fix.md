# Type: `fix`

Phase 1 loads this bank when the user is reporting broken behavior with a clear reproduction. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when the user is reporting broken behavior, an observable defect, a stack trace, a flow that no longer produces the expected outcome. Triggers on patterns like "X is broken", "Y doesn't work", "throws an error", "regressed since...". Not for mysteries with no clear reproduction (that's `debug`).

**COMPOSITION**

- Skip Q1 (Reproduction shape) and confirm if the user prompt contains BOTH the substring `expected` AND `actual`.
- Skip Q2 (Frequency) if the user prompt contains any of the literal substrings `always`, `every time`, `intermittently`, `once`, or `sometimes`.
- Skip Q3 (Recent changes) if the user prompt contains any of `started failing`, `regressed`, `after the`, `since we merged`.
- Always ask Q4 (Regression scope), silently affected flows are the top source of incomplete fixes.
- Always ask Q5 (Severity), it determines polish-vs-ship tradeoff.
- Always ask Q6 (Solution shape), it gates whether Phase 3 dispatches a refactor sub-agent.
- Always ask Q6 (Guard against it returning), defaults to A; the only gate that prevents silent re-breakage. Q1 wording aligns with `debug` Q1 by design (keep in sync if either is edited).

**QUESTIONS**

Every question below is a TEMPLATE. Substitute the real names, files and current behavior you found before sending it, so the user can answer without opening anything. Angle-bracket slots are yours to fill. `What happens:` lines are mandatory and are what the user reads.

Q1. Can you make it happen on demand
- Text: Can you make `<the bug, in their words>` happen again whenever you want, by following the same steps?
- Header: Repeatable
- Options:
  - A. Yes, every time, and here are the steps (Recommended)
    - What happens: I reproduce it myself first, so I'm certain I'm fixing the real thing and not guessing.
  - B. It happens sometimes, not every time
    - What happens: I'll gather evidence first to find the pattern. Slower, but an intermittent bug fixed by guesswork usually comes back.
  - C. It happened once and I can't repeat it
    - What happens: I'll investigate properly from logs and code before changing anything, rather than patching a symptom.
- Why-this-matters: Routes the task: stay in `fix` flow (A) vs escalate to Phase 3b evidence-gathering (B/C). No reliable repro means no honest RED test.

Q2. Did something change just before it started
- Text: Do you remember anything changing around the time this started, like a release, an update, or a settings change?
- Header: Trigger
- Options:
  - A. Yes, I know roughly what changed (Recommended)
    - What happens: I look there first, which is usually the fastest route to the real cause.
  - B. No, it just started on its own
    - What happens: I'll trace it from the symptom backwards instead of from a suspected change.
  - C. No idea, can you work it out
    - What happens: I'll walk back through your project's history to find the commit where it broke.
- Why-this-matters: Determines whether Phase 1 ends with a bisect step or goes straight to root-cause analysis.

Q3. How far it spreads
- Text: As far as you know, does this break only `<the specific flow they named>`, or have you seen it affect other things too?
- Header: Reach
- Options:
  - A. Just that one thing (Recommended)
    - What happens: I keep the fix tight and focused on that flow.
  - B. That, plus a few related things
    - What happens: I check the related areas too and make sure the fix covers all of them.
  - C. It seems to affect lots of unrelated places
    - What happens: That usually means something shared underneath is broken. I'll find that instead of patching each place.
- Why-this-matters: Decides whether Phase 4 cross-package verification runs and whether Reviewer F's seam sweep needs a wider consumer grep.

Q4. How urgent
- Text: How much is this hurting you right now?
- Header: Urgency
- Options:
  - A. It's blocking people, I need the fastest safe fix (Recommended)
    - What happens: I make the smallest change that genuinely fixes it, and leave any tidying for later.
  - B. It's annoying but nothing is stopping
    - What happens: I fix it properly and tidy the surrounding area while I'm in there.
  - C. No rush, do it whenever
    - What happens: I take the time to fix the underlying cause well, even if that means a bigger change.
- Why-this-matters: Trades Phase 3 minimum-diff against a broader refactor, and whether Phase 6 fast-paths to a hotfix.

Q5. Patch it or fix the cause
- Text: `<State what you found, e.g. "The immediate cause looks like a missing check in checkout.ts, but the deeper reason is that nothing validates the cart before payment.">` Which do you want?
- Header: Depth
- Options:
  - A. Fix the underlying cause properly (Recommended)
    - What happens: Takes a bit longer, but this class of bug stops coming back.
  - B. Just patch the immediate problem for now
    - What happens: Quickest route to working. The same root cause can bite again elsewhere.
  - C. Patch it now, and write down the real fix for later
    - What happens: You get it working today, plus a written note of what still needs doing.
- Why-this-matters: Determines whether Phase 3 dispatches one implementer or also a refactor task, and whether a Retrospective follow-up is filed.

Q6. Guard against it returning
- Text: Do you want me to add an automated check that fails if this exact bug ever comes back?
- Header: Guard
- Options:
  - A. Yes, please (Recommended)
    - What happens: I prove the check catches the bug by watching it fail before the fix, then pass after. That's how you know it's real.
  - B. No, just fix it
    - What happens: Quicker now. Nothing stops this breaking again silently in a future change.
- Why-this-matters: Determines whether Phase 3 starts with a watched RED test. Recommend A unconditionally unless the user prompt contains `no test`, `quick fix only`, or `can't test`.

**EXIT CRITERIA**

Q4, Q5, Q6 answered (always required); for Q1, Q2, Q3: either the question was answered OR its COMPOSITION skip condition fired and was logged; if Q1 = C, the task is re-routed to the `debug` bank and this bank's exit is bypassed; the regression-guard decision captured in the work-doc.
