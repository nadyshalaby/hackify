# The repo brief (build it once, hand it to every agent)

A dispatched agent starts cold. Left to itself it re-derives the same facts every other agent on the wave is deriving at the same moment: what the stack is, how tests run, where things live, which layering rules apply. On a fifteen-task sprint that is fifteen rediscoveries of one repo, and the reviewer panel does it again.

**The parent already knows all of it** by the end of Phase 1. Write it down once, pass it as `{{repo_brief}}` to every implementer and every reviewer, and tell them not to re-derive it.

## When to build it

At the **end of Phase 2**, alongside the work-doc. It is a work-doc block, not a separate file, so it survives pause/resume like everything else. Refresh it only when the sprint itself changes one of its facts (a new package, a changed test command).

## What goes in it

Cap it at **~200 words**. It is a briefing, not documentation; anything longer is a second thing for the agent to read.

| Line | Content | Example shape |
|---|---|---|
| Stack | language, runtime, framework, package manager | `TypeScript / Node 22 / NestJS / bun` |
| Commands | the exact test, lint and typecheck commands, verbatim | `bun test` / `bunx biome check .` / `bunx tsc --noEmit` |
| Layout | where each layer lives, one line | `routes in src/*/​*.controller.ts, logic in *.service.ts, data in *.repository.ts` |
| Layering rule | the one boundary that matters here | `controllers delegate only, services own their data access` |
| Rules source | which rule file governs, and who wins on conflict | `project CLAUDE.md at root; stricter wins over user-global` |
| Test convention | where tests live and what they are named | `*.spec.ts beside the source file` |
| Landmines | facts an agent would get wrong on its own | `the ORM lazy-loads relations by default` |

## What stays out

- **Anything the agent's own file allowlist already tells it.** The brief is repo-wide, not task-specific.
- **Anything it can see in the diff.** The brief explains the ground, not the change.
- **Opinions, history, rationale.** No "we used to do X". A brief is facts an agent would otherwise spend reads discovering.
- **Anything you have not verified this session.** A wrong brief is worse than no brief, because every agent inherits the error at once. If you did not run the test command, do not name it.

## The contract on the receiving end

Every prompt that takes `{{repo_brief}}` says the same thing: *treat it as given, do NOT re-derive it, spend your reads on the diff instead*. An agent that re-derives the brief anyway has burned the saving; an agent that finds the brief **wrong** says so in its report rather than silently working around it.

## See also

- [phases/phase-3-implement.md](phases/phase-3-implement.md), the wave dispatch that first uses it.
- [phases/phase-5-review.md](phases/phase-5-review.md), the reviewer panel that reuses the same block unchanged.
- [parallel-agents/README.md](parallel-agents/README.md), the per-agent INPUTS table.
