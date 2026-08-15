# Type: `refactor`

Phase 1 loads this bank when behavior should NOT change but structure should, moving, renaming, extracting, deduplicating, restoring layer boundaries. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when behavior should NOT change but structure should, moving code, renaming, extracting, deduplicating, restoring layer boundaries, prepping for an upcoming feature. Triggers on patterns like "clean up X", "extract Y", "consolidate Z", "this is getting messy", "prep for...". Not for user-visible changes (that's `feature` or `revamp`).

**COMPOSITION**

- Always ask Q1 (Driver), drives the Phase 2 plan narrative.
- Always ask Q2 (Behavior contract), the central refactor invariant. If the user names exceptions in the prompt, present them as confirmation.
- If the prompt names the scope (one file, one module, cross-project), skip Q3 (Scope).
- Always ask Q4 (Test coverage), gates whether a "write tests first" sub-phase is inserted.
- Always ask Q5 (Migration shape), determines whether Phase 2 plans a single PR or a staged rollout.
- If the user's prompt cites an exemplar module to mimic, skip Q6 (Pattern reference) and link it in the preamble.

**QUESTIONS**

Every question below is a TEMPLATE. Substitute the real names, files and current behavior you found before sending it, so the user can answer without opening anything. Angle-bracket slots are yours to fill. `What happens:` lines are mandatory and are what the user reads.

Q1. What's bothering you about it
- Text: What's the main reason you want `<the real module or area>` reworked?
- Header: Reason
- Options:
  - A. It's hard to read and work with (Recommended)
    - What happens: I focus on making it clearer and simpler, without changing what it does.
  - B. I'm about to add something and this is in the way
    - What happens: Tell me what's coming next and I'll shape it so that lands easily.
  - C. It's too slow
    - What happens: I measure first to find the real bottleneck, then fix that specifically rather than guessing.
  - D. It's doing things it shouldn't, in the wrong place
    - What happens: I move the misplaced logic to where it belongs so the boundaries are clean again.
- Why-this-matters: Frames the Phase 2 plan narrative and selects the Phase 5 reviewer focus (quality vs performance vs layering).

Q2. Should anything look different afterwards
- Text: After this, should anyone using the app notice any difference at all?
- Header: Visible change
- Options:
  - A. No, it should behave exactly the same (Recommended)
    - What happens: I capture how it behaves now and prove it still behaves identically afterwards.
  - B. Yes, some things should change too
    - What happens: Tell me which, and I'll treat those as intended rather than as mistakes.
- Why-this-matters: Determines whether a behavior-equivalence check runs in Phase 5 and whether Phase 3 captures a before/after snapshot test.

Q3. How much should move
- Text: I found this pattern in `<real file(s) you found>`. Should I stay inside that, or follow it everywhere it appears?
- Header: Reach
- Options:
  - A. Just that area for now (Recommended)
    - What happens: Small and safe. Easy to review, easy to undo.
  - B. That area and the closely related ones
    - What happens: More consistent result, bigger change to read through.
  - C. Everywhere it appears, across the whole project
    - What happens: Nothing left inconsistent, but it's a large change and takes longer to verify.
- Why-this-matters: Decides whether Phase 4 cross-package verification runs and how many waves Phase 3 needs.

Q4. Safety net
- Text: `<State what you found, e.g. "This area has almost no automated tests right now.">` Reworking code with no tests is where silent breakage comes from. How do you want to handle that?
- Header: Safety net
- Options:
  - A. Write tests that capture today's behavior first (Recommended)
    - What happens: Slower to start, but I can prove nothing broke. Without this, neither of us can be sure.
  - B. Go ahead, the existing tests are enough
    - What happens: Faster. I rely on what's already covered and flag anything that looks unprotected.
  - C. Check the coverage first, then decide
    - What happens: I'll report what's actually covered and you choose from there.
- Why-this-matters: Inserts a characterization-test sub-phase in Phase 2 when A or C is selected; gates Phase 3 entry.

Q5. How it should land
- Text: Do you want this as one clean change, or eased in gradually so nothing switches over at once?
- Header: Rollout
- Options:
  - A. One clean change (Recommended)
    - What happens: Simplest to review and reason about. Best when the area is well covered by tests.
  - B. Keep the old way working alongside the new one for a while
    - What happens: Safer for anything other people depend on, but the code holds both versions for a period.
  - C. Put it behind a switch I can flip
    - What happens: You control exactly when it goes live and can turn it back off instantly.
- Why-this-matters: Determines Phase 6 release shape and whether deprecation shims are emitted in Phase 3.

Q6. Is there a good example already
- Text: Is there somewhere in your project that already does this the way you want it done? `<If you spotted a candidate, name it: "e.g. orders/ looks like the shape you're describing.">`
- Header: Example
- Options:
  - A. Yes, copy that pattern (Recommended)
    - What happens: The result matches what you already have, so it looks like the same author wrote it.
  - B. No, suggest a shape and I'll pick
    - What happens: I'll show you two or three options with the trade-offs before writing anything.
- Why-this-matters: Phase 2 mimics the named exemplar verbatim; without one, Phase 2 spends time deriving the target shape.

**EXIT CRITERIA**

Q1, Q2, Q4, Q5 answered (always required); Q3, Q6 answered if their COMPOSITION trigger fired; behavior-contract decision and migration shape captured in the work-doc; if Q4 = B, the work-doc Tasks list opens with a "write characterization tests" task before any structural change.
