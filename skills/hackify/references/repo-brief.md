# The repo brief (build it once, hand it to every agent)

A dispatched agent starts cold. Left to itself it re-derives the same facts the wave before it already derived: what the stack is, how tests run, where things live, which layering rules apply. On a five-wave sprint that is five rediscoveries of one repo, and the reviewer panel does it again with several agents at once.

**The parent already knows all of it** by the end of Phase 1. Write it down once, pass it as `{{repo_brief}}` to every implementer and every reviewer, and tell them not to re-derive it.

## When to build it

At the **end of Phase 2**, alongside the work-doc. It is a work-doc block, not a separate file, so it survives pause/resume like everything else. Refresh it only when the sprint itself changes one of its facts (a new package, a changed test command).

## What goes in it

Cap it at **~350 words**. It is a briefing, not documentation; anything longer is a second thing for the agent to read. The cap moved up from 200 to pay for the right-hand column below, and that column is the only thing the extra budget buys. More prose is still the wrong answer.

**Every line carries the command that produced it.** A brief is a pile of claims about a repo, and a claim the reader cannot check is one they have to take on faith. Hand a dozen agents an unverified fact and a dozen agents inherit the same error at once, quietly, because none of them has a cheap way to notice. Naming the command turns each line from something to believe into something anyone can settle in one run.

| Line | Content | Example shape, the fact then what proved it |
|---|---|---|
| Stack | language, runtime, framework, package manager | `TypeScript / Node 22 / NestJS / bun` ← `jq -r .packageManager package.json` |
| Commands | the exact test, lint and typecheck commands, verbatim | `bun test` ← ran this session, 41 pass / 0 fail |
| Layout | where each layer lives, one line | `routes in *.controller.ts, logic in *.service.ts` ← `git ls-files 'src/**/*.controller.ts' \| head -3` |
| Layering rule | the one boundary that matters here | `controllers delegate only, services own their data access` ← `CLAUDE.md:24` |
| Rules source | which rule file governs, and who wins on conflict | `project CLAUDE.md at root, stricter wins over user-global` ← `ls CLAUDE.md ~/.claude/CLAUDE.md` |
| Test convention | where tests live and what they are named | `*.spec.ts beside the source file` ← `git ls-files '*.spec.ts' \| head -3` |
| Landmines | facts an agent would get wrong on its own | `the ORM lazy-loads relations by default` ← `src/db/orm.config.ts:18` |

A `file:line` citation counts as a command. It is a fact the reader settles by opening one file at one line, which is the same bargain a command makes.

**A line with nothing to the right of the arrow is not a fact, it is a guess.** Verify it or drop it. Never write a brief line you could not reproduce on demand, because the whole point of the block is that N agents stop re-deriving, and that saving is only safe when the thing they are trusting is checkable.

## What stays out

- **Anything the agent's own file allowlist already tells it.** The brief is repo-wide, not task-specific.
- **Anything it can see in the diff.** The brief explains the ground, not the change.
- **Opinions, history, rationale.** No "we used to do X". A brief is facts an agent would otherwise spend reads discovering.
- **Anything you have not verified this session.** A wrong brief is worse than no brief, because every agent inherits the error at once. If you did not run the test command, do not name it. This is the same rule as the arrow above, stated from the other end: no command, no line.

## The contract on the receiving end

Every prompt that takes `{{repo_brief}}` says the same thing: *treat it as given, do NOT re-derive it, spend your reads on the diff instead*. An agent that re-derives the brief anyway has burned the saving; an agent that finds the brief **wrong** says so in its report rather than silently working around it.

**"Do not re-derive" bans exploration, not verification, and the difference is the whole reason the arrow column exists.** Re-deriving is going back out to rediscover the stack, hunt for the test command, map the layout from scratch. That is the cost the brief exists to delete, and it stays banned. Re-running one named command to settle one line is not that: it is seconds, it is bounded, and it is the only thing standing between a stale brief and a wave that inherits its error. So when an agent is about to write code that depends on a brief line being right, re-running that line's command is correct behaviour, not a violation.

## See also

- [phases/phase-3-implement.md](phases/phase-3-implement.md), the wave dispatch that first uses it.
- [phases/phase-5-review.md](phases/phase-5-review.md), the reviewer panel that reuses the same block unchanged.
- [parallel-agents/README.md](parallel-agents/README.md), the per-agent INPUTS table.
