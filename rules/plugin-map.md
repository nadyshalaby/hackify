# hackify, what ships and where to go

Injected once per session by the `SessionStart` hook. This is a MAP, not a law.
It says what exists and when each thing is right. It restates no rule, because a
copy that loads once decays while the injected original does not, and a fading
copy that still looks authoritative is worse than no map at all.

## Entry points

| Entry | Right when |
|---|---|
| `/hackify:quick` | The default build route for any substantive prompt. Keeps every guarantee of the full workflow and drops only Plan+Gate, spec review and the 4-options finish. |
| `/hackify:hackify` | The full workflow, and only when the user asks for it by name. Never auto-fires, and quick never escalates into it: no size, file-count or sensitivity check promotes. |
| `/hackify:groom` | The idea is not a task yet. One or two forking questions per turn, and it graduates to quick on the first build verb. |
| `/hackify:codewalk` | Understanding code nobody in the room wrote. Traces one execution path to the leaves into a browser call-stack viewer. |
| `/hackify:lawkeeper` | Auditing a WHOLE codebase against its own engineering laws. Not a per-diff review. |
| `/hackify:review-triage` | A batch of review findings needs a per-finding accept, push-back, defer or needs-restatement decision. |
| `/hackify:skillsmith` | Authoring a NEW skill that has to pass hackify's own contracts. |
| `/hackify:designify` | Authoring, extracting or refreshing the project's design spec. |
| `/hackify:summary` | Printing the plain-language update log for the current task. |

## The law, injected on every prompt

These five bind verbatim and are the authority. Open the file for what it says;
the right-hand column is a label, never the rule.

| File | Governs |
|---|---|
| `rules/hard-caps.md` | Size caps, the zero-tolerance bans, one thing per file. |
| `rules/expert-mindset.md` | How to approach a task before touching it. |
| `rules/perf-guardrails.md` | The performance floor every diff owes. |
| `rules/phase-discipline.md` | The phase ledger, in-order execution, the wizard mandate. |
| `rules/claim-integrity.md` | Evidence before claims. |

## Vocabulary you will hear

Phases run in order and none is skipped: 1 Clarify, 2 Plan + Gate, 2.5 Spec
review, 3 Implement, 3b Debug (only when stuck), 4 Verify, 5 Review, 6 Finish.
The only mandatory user gate sits between Plan and Spec review; after that,
implementation begins on its own. A phase that does not apply is marked complete
with a one-line reason.

Phase 3 runs in waves: a solo foundation wave, then concurrent module tracks,
then a solo assembly wave that boots the system, then a testing wave.

Phase 5 dispatches ONE merged all-lens reviewer by default. Ask for the
five-agent panel by name and the same lenses come back as one report each.

Full mode keeps its state in one file, `docs/work/<YYYY-MM-DD>-<slug>.md`, which
moves under `done/` once it ships. That file is the source of truth and the thing
a resumed session reads back, so it is written at every phase flip rather than at
the end. Quick mode keeps no such file and cannot be resumed across sessions.
