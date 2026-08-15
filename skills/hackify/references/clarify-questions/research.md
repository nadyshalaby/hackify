# Type: `research`

Phase 1 loads this bank when the user wants to explore or evaluate an idea before committing to build it, feasibility studies, architecture trade-offs, library comparisons. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Use when the user wants to discuss or explore an idea before committing to build it, feasibility studies, architecture trade-off comparisons, library evaluations, "is X possible?" Triggers on patterns like "research", "explore", "evaluate", "compare X vs Y", "should we...". The Phase 2 gate is reframed from "approve the plan to build" to "approve the conclusions and whether to build."

**COMPOSITION**

- Always ask Q1 (Question shape), research with no testable question produces no testable answer.
- Always ask Q2 (Decision it informs), if no decision rides on the answer, the research is theatre.
- Always ask Q3 (Depth), sets the time-box and deliverable shape.
- Always ask Q4 (Output), determines where conclusions land.
- Always ask Q5 (Continuation), sets Phase 6's exit (auto-roll into build vs. pause for user decision).

**QUESTIONS**

Every question below is a TEMPLATE. Substitute the real names, files and current behavior you found before sending it, so the user can answer without opening anything. Angle-bracket slots are yours to fill. `What happens:` lines are mandatory and are what the user reads.

Q1. The question behind the question
- Text: You asked me to look into `<the topic, in their words>`. What's the one thing you most want to know at the end of it?
- Header: The question
- Options:
  - A. `<state the specific question you think they mean>` (Recommended)
    - What happens: I'll answer exactly that, with evidence, and skip anything that doesn't serve it.
  - B. Let me phrase it myself
    - What happens: Tell me in your own words and I'll aim at that instead.
  - C. There are a few things, help me untangle them
    - What happens: I'll lay out the separate questions and you say which matter most.
- Why-this-matters: Sets the Question-under-investigation line and gates whether sub-questions fan out into parallel research agents.

Q2. What you'll do with the answer
- Text: What decision are you trying to make here? Knowing that keeps me from researching things that won't change what you do.
- Header: Decision
- Options:
  - A. Whether to build `<the thing>` at all (Recommended)
    - What happens: I focus on the evidence that would make you say yes or no, not on general background.
  - B. Which of a few approaches to pick
    - What happens: I compare them head to head on the things that matter for your situation.
  - C. How big a job it would be
    - What happens: I come back with a realistic sense of effort and the risky parts.
- Why-this-matters: Frames the Approach section and what the Phase 6 conclusions report must contain.

Q3. How deep to go
- Text: How much time is this worth? Digging deeper gives more confidence but costs more.
- Header: Depth
- Options:
  - A. A quick read of the landscape, no code (Recommended)
    - What happens: You get a clear answer fast, based on reading and reasoning rather than building.
  - B. Build a rough throwaway version to see if it works
    - What happens: Much stronger evidence, because I actually try it. The code is scratch and gets thrown away.
  - C. A thorough comparison with evidence for each option
    - What happens: The most complete answer, and the slowest.
- Why-this-matters: Sets the Phase 1 time-box, whether a sandbox worktree is created, and how many parallel research agents fan out.

Q4. What you get at the end
- Text: How would you like the findings delivered?
- Header: Deliverable
- Options:
  - A. A written summary I can read (Recommended)
    - What happens: One document with what I found, what I recommend, and why.
  - B. A summary plus the rough code I tried
    - What happens: You get the write-up and can run the experiment yourself.
  - C. A summary plus a ready-to-go plan for building it
    - What happens: If the answer is yes, the next step is already written up and ready to start.
- Why-this-matters: Determines whether Phase 6 commits a spike branch and whether a follow-up work-doc is scaffolded.

Q5. What happens after
- Text: Once I've reported back, should I stop there or keep going?
- Header: Next step
- Options:
  - A. Stop, I'll decide (Recommended)
    - What happens: Nothing gets built until you say so.
  - B. If the answer is "build it", just start
    - What happens: I roll straight into planning and building without waiting.
  - C. Package it up for someone else to pick up
    - What happens: I write it so a person with no context can take it from there.
- Why-this-matters: Sets Phase 6's exit (pause vs auto-dispatch a new `feature` work-doc) and the handoff format.

**EXIT CRITERIA**

Q1, Q2, Q3, Q4, Q5 all answered; question sentence captured verbatim in the work-doc preamble; decision-it-informs captured in the Approach section; depth time-box recorded so Phase 1 has a hard checkpoint; Phase 2 gate framed as "approve the conclusions and whether to build" (not "approve the plan to build").
