# Phase 5 — Aggregation guidance (conflict resolution + anti-patterns)

This file holds the post-fan-out aggregation guidance shared by every parallel-agent wave in this directory. Load it whenever multiple parallel agents have returned and the parent must combine their findings. The per-template sub-agent prompts and the canonical 7-section sub-agent contract live in sibling files (`template-contract.md`, `phase-2.5-spec-review-*.md`, `phase-3-implementation.md`, `phase-3b-debug-evidence.md`, `phase-5-multi-review.md`).

---

## Conflict resolution after parallel agents return

When N agents return with overlapping or contradictory findings:

1. **Read all reports first** before reacting. Don't act on agent #1's conclusion before #2 returns.
2. **Compare evidence, not opinions.** Whichever report has the more grounded evidence wins.
3. **If reports contradict**, prefer the agent that pointed to specific file:line over the agent that gave a general claim.
4. If still unclear, fire one more focused agent with the conflicting claim attached: *"agent A says X, agent B says Y; here's the evidence — which is right?"*

---

## Anti-patterns

- Sending agent #1, waiting, sending agent #2 — that's serial dressed as parallel. Send both in one message.
- Dispatching agents to "find answers" without enough context to ground the search — they'll generalize and waste tokens. Always include: workspace path, project, what you've ruled out, what you suspect, what files you think are involved.
- Dispatching agents to edit **the same file** in the same wave — file conflicts. The wave planner is what prevents this; if two tasks share a file, push one to a later wave.
- Dispatching agents to edit code in parallel **without a per-agent file allowlist** — without "you may only modify these files", agents drift. Always pin the file list.
- Dispatching agents to do **the same thing twice** for "redundancy" — they'll come back with similar answers and you've doubled the cost. Multi-reviewer dispatches different *lenses* on the same diff — that's not redundancy.
- Forgetting agents can't see the conversation history. Their prompt MUST be self-contained.
- Skipping spec self-review because "the plan looks fine" — the plan looks fine to the author; the parallel reviewers look at it from angles the author can't.
