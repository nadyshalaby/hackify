# Type: `revamp` or `redesign`

Phase 1 loads this bank for deeper rework where old behavior is being replaced. UI redesign, API redesign, subsystem replacement, framework migration. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use for deeper rework. UI redesign, API redesign, replacing a subsystem, migrating to a new framework. Triggers on patterns like "redesign", "revamp", "rewrite", "replace X with Y", "modernize". Distinguished from `feature` because old behavior is being replaced (not just augmented), and from `refactor` because user-visible behavior IS allowed to change.

**COMPOSITION**

- This bank is standalone, do NOT chain to the `feature` bank. Authoritative questions duplicated here on purpose.
- Always ask Q1 (Is my understanding right), Q2 (What must survive), Q3 (What should go away), Q5 (Who else depends on this), Q7 (Moving people across).
- Ask Q4 (Visual reference) if the user prompt contains any of `UI`, `frontend`, `component`, `page`, `layout`, `design`, `visual`, `theme`, `styling`, `redesign`; otherwise skip.
- If the redesign touches a public API, ask Q5 (API impact); else skip.
- Always ask Q6 (Acceptance criteria), gates Phase 2's DoD section.
- If the project has a brand spec under `docs/`, confirm in the preamble and skip the brand portion of Q4.

**QUESTIONS**

Every question below is a TEMPLATE. Substitute the real names, files and current behavior you found before sending it, so the user can answer without opening anything. Angle-bracket slots are yours to fill. `What happens:` lines are mandatory and are what the user reads.

Q1. Is my understanding right
- Text: You asked me to rework `<the real thing>`. My reading is: `<one-sentence plain restatement of the end state you think they want>`. Is that the outcome you're after?
- Header: The goal
- Options:
  - A. Yes, that's it (Recommended)
    - What happens: I'll plan towards exactly that and confirm the details as I go.
  - B. Close, but let me correct it
    - What happens: Tell me what's off and I'll re-check before planning anything.
  - C. Show me a couple of interpretations
    - What happens: I'll describe two or three end states and you pick the one you meant.
- Why-this-matters: Locks the North-Star Goal in the anchor. A misread goal on a redesign is the most expensive miss in the workflow.

Q2. What must survive
- Text: What about the current version has to keep working exactly as it does now? For example `<name 1-2 real things you found, e.g. "existing bookmarked links" or "the CSV export format">`.
- Header: Must survive
- Options:
  - A. Nothing specific, use your judgment (Recommended)
    - What happens: I protect anything that looks load-bearing and check with you before removing it.
  - B. Let me name what must not change
    - What happens: Those become hard lines. I verify each one still works before finishing.
  - C. Nothing is sacred, rebuild it freely
    - What happens: I have a free hand. Faster and cleaner, with more chance of surprising you.
- Why-this-matters: Fills Guardrails/Invariants in the anchor and seeds the Phase 5 behavior-equivalence check.

Q3. What should go away
- Text: Is there anything in the current version you actively want removed, rather than carried over?
- Header: Remove
- Options:
  - A. Let me tell you what to drop (Recommended)
    - What happens: I remove exactly those and leave the rest alone.
  - B. Drop anything you judge to be dead weight
    - What happens: I'll list what I plan to remove and why before deleting anything.
  - C. Keep everything, just rework how it's built
    - What happens: Same features and screens, better underneath.
- Why-this-matters: Frames the deletion section of the plan and the Phase 6 communication note for affected consumers.

Q4. What it should look like (visual work only)
- Text: For the look and feel, `<state what you found: "your project has a written design guide at docs/design/DESIGN.md" OR "I could not find a written design guide">`. What should I follow?
- Header: Look
- Options:
  - A. Follow the existing guide (Recommended)
    - What happens: The result stays consistent with the rest of your product.
  - B. I have something to copy, I'll show you
    - What happens: Send a screenshot, a link, or a mockup and I'll match it and write the rules down.
  - C. Just match what's already on screen
    - What happens: I read the current look out of your code, write it down, and stay inside it.
  - D. Nothing exists, propose some options
    - What happens: I'll show you a few distinct directions with examples and you pick one before I build.
- Why-this-matters: Loads `references/frontend-design.md` (binding). A selects the committed spec as authority; B and C route to `design-spec/extract-protocol.md` (Mode B and Mode A); D routes to `direction-library.md`.

Q4b. How big a visual change (visual work only)
- Text: Should this still feel like the same product, just better, or does it need to look genuinely different?
- Header: How far
- Options:
  - A. Same product, sharper (Recommended)
    - What happens: Colors, type and spacing stay recognizable. Lower risk, no sign-off needed on the look.
  - B. A genuinely new look
    - What happens: This is a rebrand. I'll write the new style down and get your sign-off before building anything.
  - C. There's no consistent look right now, give it one
    - What happens: I'll pick a direction with you, write it down, then apply it everywhere.
- Why-this-matters: A keeps the committed `DESIGN.md` binding and scopes Reviewer E to conformance. B and C make authoring or refreshing `docs/design/DESIGN.md` an explicit Phase 2 deliverable, before any component, and require sign-off at the gate.

Q5. Who else depends on this
- Text: Does anything outside this app rely on `<the real thing>` as it works today, like another service, a mobile app, or a customer integration?
- Header: Outside use
- Options:
  - A. No, nothing outside depends on it (Recommended)
    - What happens: I can change it freely without worrying about breaking someone else.
  - B. Yes, but I can only add things, not change what's there
    - What happens: Everything that works today keeps working. New capability goes alongside.
  - C. Yes, and some of it will have to break
    - What happens: I'll keep the old way alive for a period and write down what others need to change.
- Why-this-matters: Determines whether a deprecation timeline is emitted and whether Phase 5 adds a back-compat lens.

Q6. How we'll know it's right
- Text: When this is finished, what would you look at to decide it worked? For example `<a concrete check, e.g. "the settings page loads in under a second and nothing I had saved is lost">`.
- Header: Done when
- Options:
  - A. Use the check I just suggested (Recommended)
    - What happens: I'll prove exactly that with real output before calling it done.
  - B. Let me describe my own check
    - What happens: Tell me what you'd try and I'll prove that instead.
  - C. It should behave the same as before, only better built
    - What happens: I compare old against new and show you they match.
- Why-this-matters: Becomes the Acceptance Criteria bullets and Success Signals in the anchor; each needs a proving row in the Phase 4 Evidence Ledger.

Q7. Moving people across
- Text: There are people using the current version right now. How should they move to the new one?
- Header: Switchover
- Options:
  - A. Everyone switches at once when it's ready (Recommended)
    - What happens: Simplest. Best when the change is low-risk and well tested.
  - B. Run both side by side for a while
    - What happens: Safest. People move gradually and you can compare the two.
  - C. Roll it out to a few people first
    - What happens: You catch problems on a small group before everyone sees them.
  - D. Nobody is using it yet
    - What happens: Nothing to move. I build the new version directly.
- Why-this-matters: Drives the migration section, whether a data-migration task enters the Sprint Backlog, and the Phase 6 rollout plan.

**EXIT CRITERIA**

Q1, Q2, Q3, Q5, Q6, Q7 answered (always required); Q4 and Q4b answered if the redesign is UI-bearing; invariants list and migration plan captured in the work-doc. If revamp Q4 indicates a UI-bearing change, the dispatching agent MUST load `references/frontend-design.md` and follow its rules BEFORE drafting the work-doc Approach section. This is binding, not advisory. If Q4b answers B or C, authoring or refreshing `<project>/docs/design/DESIGN.md` is a named Phase 2 deliverable that lands BEFORE any component work, and the gate covers it explicitly.
