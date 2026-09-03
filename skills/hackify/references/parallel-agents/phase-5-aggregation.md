# Phase 5, Aggregation guidance (conflict resolution + anti-patterns)

This file holds the post-fan-out aggregation guidance shared by every parallel-agent wave in this directory. Load it whenever multiple parallel agents have returned and the parent must combine their findings. The per-template sub-agent prompts and the canonical 8-section sub-agent contract live in sibling files (`template-contract.md`, `investigation.md`, `phase-2.5-spec-reviewer.md`, `phase-3-implementation.md`, `phase-5-multi-review-a-security.md`, `phase-5-multi-review-b-quality-plan.md`, `phase-5-multi-review-d-performance.md`, `phase-5-multi-review-e-design.md`, `phase-5-multi-review-f-coherence.md`, `phase-5-multi-review-merged.md`, `phase-5-refute.md`). Every one of them holds exactly one prompt; no file in this directory carries two any more.

The guidance below is deliberately count-agnostic: it governs N returning agents, whether that is the Phase 5 reviewer panel or a flat batch of Phase 1 research agents.

---

## Which round shapes this file serves

Phase 5 routes to the merged all-lens reviewer by default in every mode, and one reviewer returns one report. **There is nothing to aggregate on that round.** That is this file's stage marked complete with a written reason, not a dead section: read the one report, run the refuter over its findings, go to the decision table. Nothing below is wrong there, it simply has no second report to weigh the first against. The anti-patterns at the foot of the file are the exception and still bind, because they are about how agents get DISPATCHED, and a fan-out of one breaks most of them just as readily as a fan-out of many.

Three shapes do reach the guidance below.

1. **The panel, dispatched on request.** Somebody asked for the lenses by name on this diff. Several reports return, they overlap by construction, and everything below applies as written.
2. **Both reviewers on one diff.** The parent dispatches the panel AND the merged reviewer on the same `base..head`, to review the diff properly and to measure the two shapes against each other on it. This is the shape a sprint that changes the review route uses to review itself. It gets its own section next, because the two reports are not peers.
3. **Any other wave that fans out.** Phase 1 research agents, a testing stage that split, a cross-package verification wave. None of that is review-specific and none of it changed.

---

## Both reviewers on one diff, where the reports are also the measurement

Both agents read the same `base..head`, so a defect either one names is one defect however many reports carry it. **Merge on the defect, never on the report.**

1. **Key every finding by its `file:line` and the failure it names**, not by which agent filed it. Two findings at one location naming one failure are one row in the decision table.
2. **Both filed it.** One row. Keep the citation set from whichever report grounds it better, keep the HIGHER of the two severities, and note in the row that both filed it. Agreement is evidence about the defect and never a licence to count the row twice or to skip the refuter on it.
3. **Only one filed it.** The row stands on its own evidence and goes to the refuter like every other. A lens the other agent did not carry, or carried and did not reach, explains a miss completely; silence from the other report is not a refutation, and reading it as one is how a real defect gets dropped for being unpopular.
4. **They contradict.** Conflict resolution below decides it unchanged, and rule 3 there is the one that does the work: a `file:line` beats a general claim whoever filed it.
5. **Count the overlap BEFORE the fix wave starts.** Three numbers, each split by severity: filed by both, filed only by the panel, filed only by the merged reviewer. That is the measurement, this round shape is the only place it exists, and the first fix edits the diff out from under it. Write it into the work-doc beside the decision table, not into a chat message.

---

## Conflict resolution after parallel agents return

When N agents return with overlapping or contradictory findings:

1. **Read all reports first** before reacting. Don't act on agent #1's conclusion before #2 returns.
2. **Compare evidence, not opinions.** Whichever report has the more grounded evidence wins.
3. **If reports contradict**, prefer the agent that pointed to specific file:line over the agent that gave a general claim.
4. If still unclear, fire one more focused agent with the conflicting claim attached: *"agent A says X, agent B says Y; here's the evidence, which is right?"*

---

## Anti-patterns

- Sending agent #1, waiting, sending agent #2, that's serial dressed as parallel. Send both in one message.
- Dispatching agents to "find answers" without enough context to ground the search, they'll generalize and waste tokens. Always include: workspace path, project, what you've ruled out, what you suspect, what files you think are involved.
- Dispatching agents to edit **the same file** in the same wave, the file stops mapping to exactly one task, so a partial diff cannot be read back as task IDs. The wave planner is what prevents this; if two tasks share a file, push one to a later wave.
- Dispatching agents to edit code in parallel **without a per-agent file allowlist**, without "you may only modify these files", agents drift. Always pin the file list.
- Dispatching agents to do **the same thing twice** for "redundancy", they'll come back with similar answers and you've doubled the cost. Multi-reviewer dispatches different *lenses* on the same diff, that's not redundancy. Neither is running the panel beside the merged reviewer on one diff: there the overlap IS the measurement, it is bought deliberately and once, on a round that says up front that it is paying for it.
- Forgetting agents can't see the conversation history. Their prompt MUST be self-contained.
- Skipping spec self-review because "the plan looks fine", the plan looks fine to the author; the parallel reviewers look at it from angles the author can't.
