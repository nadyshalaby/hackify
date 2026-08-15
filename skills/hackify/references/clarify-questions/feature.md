# Type: `feature`

Phase 1 loads this bank when the user is adding new behavior the system doesn't currently have. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when the user is adding new behavior the system doesn't currently have, a new endpoint, a new screen, a new role, a new flow, a new entity. Triggers on prompt patterns like "add", "build", "introduce", "ship", "let users do X." Not for changing how existing behavior works (that's `revamp`) or fixing it (that's `fix`).

**COMPOSITION**

- Always ask Q1 (Goal shape), it determines whether the plan needs a DoD sentence written by us or already supplied.
- If the user's prompt already lists out-of-scope items, skip Q2 (Scope boundary).
- Skip Q3 (Where it lives) and confirm in the preamble if the user prompt explicitly names a concrete file path.
- Always ask Q4 (Data model) and Q5 (Public API) unless the prompt rules them out (e.g. "no DB changes, no new endpoint").
- Skip Q6 (UI surface) if the task is explicitly backend-only or CLI-only.
- Always ask Q7 (Acceptance criteria), it gates Phase 2's DoD section.
- Always ask Q8 (Edge cases, multi-select), under-asking here is the most common Phase 5 review failure.

**QUESTIONS**

Every question below is a TEMPLATE. Before sending it, substitute the real feature name, the real files you found, and the real current behavior, so the user can answer without opening anything. Angle-bracket slots like `<the thing they asked for>` are yours to fill. Option descriptions are mandatory and say what happens next in plain words.

Q1. Is my understanding right
- Text: You asked for `<the thing they asked for>`. Before I plan anything, let me check I understood: `<one-sentence plain restatement of what you think they want, naming the real screen or behavior>`. Is that right?
- Header: The goal
- Options:
  - A. Yes, that's it (Recommended)
    - What happens: I'll build exactly that and check the details with you as I go.
  - B. Close, but something's off
    - What happens: Tell me what I got wrong and I'll re-check before writing any code.
  - C. Not sure yet, show me some options
    - What happens: I'll sketch two or three ways this could work and you pick.
- Why-this-matters: Locks the North-Star Goal in the anchor; a wrong restatement here poisons every downstream phase. Option C branches to a framing sub-question before Phase 2.

Q2. What stays untouched
- Text: Is there anything nearby you do NOT want me to change while I do this? For example `<name 1-2 real adjacent areas you spotted, e.g. "the existing signup email" or "the admin dashboard">`.
- Header: Keep as-is
- Options:
  - A. Use your judgment, just tell me before you touch anything big (Recommended)
    - What happens: I'll stay tight to the request and flag anything that spreads.
  - B. Let me list what to leave alone
    - What happens: Say which parts, and I'll treat them as off-limits.
  - C. Only build the smallest version, nothing else
    - What happens: I do the minimum that works and stop there.
- Why-this-matters: Fills Out-of-Scope / Non-Goals in the anchor. Drives the Phase 5 drift-check: a hunk serving no In-Scope bullet becomes a finding.

Q3. Where it should live
- Text: I can put this in `<real existing file or module you found>`, or start something new beside it. Do you have a preference?
- Header: Location
- Options:
  - A. You choose, follow whatever the codebase already does (Recommended)
    - What happens: I'll match the existing structure so it looks like the rest of the project.
  - B. Add it to `<the existing file>`
    - What happens: Everything stays in one place; that file gets bigger.
  - C. Start a new one
    - What happens: Cleaner separation; one more file to find later.
- Why-this-matters: Drives the Phase 2 file-creation list and whether Phase 4 cross-package verification runs.

Q4. Saving data
- Text: Does this need to remember anything between visits, like `<a concrete example for this feature, e.g. "when each invite was sent">`? Storing new information usually means a database change.
- Header: Saved data
- Options:
  - A. No, nothing new to store (Recommended)
    - What happens: No database change, which keeps this quicker and lower-risk.
  - B. Yes, a couple of new details on something that already exists
    - What happens: I add fields to an existing table and write a migration to update it safely.
  - C. Yes, a whole new kind of record
    - What happens: I add a new table plus the migration that creates it.
  - D. Not sure, tell me what you think
    - What happens: I'll look at the data you already have and come back with a recommendation.
- Why-this-matters: Determines whether a migration task enters the Sprint Backlog and whether the expand-then-contract pattern applies. B and C make Reviewer A's migration lens load-bearing.

Q5. Who else can reach it
- Text: Will anything outside this app need to use this, for example another service, a mobile app, or a customer's own script?
- Header: Outside use
- Options:
  - A. No, this app only (Recommended)
    - What happens: Keeps it internal. Simpler, and easy to change later.
  - B. Yes, I need a new address other systems can call
    - What happens: I add a new endpoint and lock it behind login by default.
  - C. It changes something outsiders already call
    - What happens: I keep the old behavior working so nothing breaks for them.
- Why-this-matters: Decides whether route registration and API docs are touched, and makes Reviewer A's auth/permission lens load-bearing in Phase 5.

Q6. Does it need a screen
- Text: Does someone need to see or click something for this, or does it all happen behind the scenes?
- Header: Screen
- Options:
  - A. Behind the scenes only (Recommended)
    - What happens: No visual work, so no design decisions needed.
  - B. A whole new page
    - What happens: I build a new page and wire it into navigation.
  - C. Something added to a page that already exists
    - What happens: I add it into `<real page you found>` without changing the rest.
  - D. A popup or an inline action
    - What happens: Appears in place when someone triggers it; no new page.
- Why-this-matters: Triggers (or skips) `references/frontend-design.md` and makes Reviewer E a standing reviewer on the diff for any answer other than A.

Q6b. What it should look like (ask only when Q6 is not A)
- Text: For the visual side, `<state what you found: "your project has a written design guide at docs/design/DESIGN.md" OR "I could not find a written design guide">`. How should I decide how this looks?
- Header: Look
- Options:
  - A. Follow the existing guide exactly (Recommended)
    - What happens: Colors, spacing and type all come from what's already agreed, so it blends in.
  - B. Match the current screens, and write down the rules as you go
    - What happens: I read the look out of your existing code and record it, so it stops drifting.
  - C. Nothing exists yet, propose a style first
    - What happens: I'll show you a few directions, you pick one, and I write it down before building.
- Why-this-matters: A makes the committed spec's tokens binding in Phase 3. B routes to `design-spec/extract-protocol.md` Mode A. C routes to `direction-library.md` plus the catalog and makes `docs/design/DESIGN.md` a Phase 2 deliverable authored BEFORE any component.

Q7. How we'll know it works
- Text: What would you check yourself to be satisfied this is done? For example: `<a concrete check for this feature, e.g. "an invite sent 8 days ago no longer opens">`.
- Header: Done when
- Options:
  - A. Use the check I just suggested (Recommended)
    - What happens: I'll prove exactly that with real output before calling it done.
  - B. Let me describe my own check
    - What happens: Tell me what you'd try, and I'll prove that instead.
  - C. There's already a test for this, I'll point you at it
    - What happens: Give me the name and I'll make sure it passes.
- Why-this-matters: Becomes the Acceptance Criteria bullets and the Success Signals in the anchor; every one needs a proving row in the Phase 4 Evidence Ledger.

Q8. What should happen when things go wrong (multi-select)
- Text: Which of these should I handle properly rather than let it break? Pick all that matter to you.
- Header: Edge cases
- Options (multiSelect):
  - A. Nothing there yet, the empty state (Recommended)
    - What happens: The screen says something helpful instead of looking broken.
  - B. Two people doing it at the same time
    - What happens: Neither one overwrites the other's work silently.
  - C. Someone who isn't allowed tries it
    - What happens: They get a clear refusal instead of a crash or, worse, access.
  - D. The network drops halfway
    - What happens: It either retries or tells the person clearly, never half-finishes.
- Why-this-matters: Each selected case becomes a required Phase 3 test case and a Phase 5 review-checklist item.

**EXIT CRITERIA**

Q1, Q4, Q5, Q7, Q8 answered (always required); Q2, Q3, Q6 answered if their COMPOSITION trigger fired; every answer reduced to A/B/C/D semantics (no free-text left ambiguous); the restatement from Q1 confirmed and captured verbatim as the North-Star Goal in the anchor.
