# The work-doc as a published page

hackify publishes **the work-doc itself** as a page the user can send to someone. Load this file from Phase 2 step 1, where the first publish happens, and from Phase 6 Step F, where the last one does.

This replaces the rendered HTML report hackify used to build at the end of a sprint. That design kept a second copy of the sprint: a renderer, a template, a payload schema and a test suite whose whole job was to restate what the work-doc already held. The two drifted apart every time somebody edited one and forgot the other. The work-doc is already the single record of the task, so the work-doc is the thing that gets shared. One representation, no sync problem.

## What gets published

The markdown file at `docs/work/<slug>.md`, exactly as it stands on disk. Nothing else.

- **No rendering step.** No HTML template, no JSON payload, no renderer script, no stat computation, no charts. None of that exists any more. Do not rebuild a replacement for it, and do not hand-write markup to stand in for it.
- **No second representation.** The page is the doc. A number on the page is a number the doc already carries. A section on the page is a section the doc already has. If something is worth publishing, write it into the work-doc, and the page gets it for free.
- **No extra file in the shipped tree.** Publishing writes nothing into `docs/work/`. It hands the existing file to the runtime's publish tool and takes a link back.

## When it publishes

Once at the start, once per phase tick, and once at the end.

1. **First publish, Phase 2 step 1.** The moment the work-doc exists and has been saved, right after that first save. This is before step 6 shows the plan for sign-off, so the user reads the plan they are approving on the same link they will keep for the rest of the task.
2. **Republish on every phase-ledger tick.** Same beat as the ledger edit plus re-print that [phase-ledger.md](phase-ledger.md) already mandates: edit the `## 0. Phase ledger` block, save, republish, print. The republish rides an edit that is already happening. It is not a new step, and it does not open a new turn.
3. **Final republish at Phase 6 Step F.** It rides the one closing edit that ticks 6c and 6d and writes `status: done`, and it happens **before** Step D's `git mv`, for the same reason the rest of Step F's work does. The doc is still at its live path, and that closing edit is the last content it ever receives.

**Never publish the archived copy under `docs/work/done/`.** A different path mints a different link, and the moment a second link exists the one the user already has is stale. The move is a rename, not a content change, so there is nothing left to publish after it.

## One link for the life of the task

Republishing the same file keeps the same URL, as long as the republish knows which URL it is aiming at. That is the whole point of the design: the user gets one link at Phase 2 and it stays current as the sprint runs.

**The condition is real, and it is what the rest of this section is about.** Inside one conversation the publish tool holds the link itself, so republishing the same file path lands on the same page with nothing to remember. Across conversations it does not: a republish that cannot hand the existing URL back creates a separate page rather than updating the first one, and the user is left holding a link that stopped moving ([runtime-adapters.md](runtime-adapters.md), "Native-tier enhancements").

- **The first publish writes the URL into the work-doc's `page_url` frontmatter field**, and every republish after it targets that field ([work-doc-template.md](work-doc-template.md), "Frontmatter field reference"). Resume reads frontmatter, so that field is the only thing carrying the link across a lost session. A sprint picked up in a new session with `page_url` still `null` has nothing to aim at, and it mints exactly the second link this file forbids above. Quick mode has no work-doc and no resume, so it holds the URL in the run itself and the link ends with the run.
- **Say the link out loud once**, in chat, when it is first created. The user asked for something they can send someone, so the link belongs in the message, not only in a tool result.
- **After that, say it again only when the user asks for it, or when it changes.** Re-printing an unchanged link at every phase boundary is noise. The page updating in place is the feature, and a link that never moves is the proof that it worked.

## Quick mode

Quick keeps nothing in the project tree, so there is no work-doc to publish. Its page is a scratch markdown file in a temp directory, assembled from the blocks quick already prints:

- the Primary Goal and Guardrails anchor,
- the printed phase-ledger block,
- the lite Evidence Ledger rows,
- and the update log, at the end.

Everything else is the same: publish when that file first exists, republish on every ledger tick, one stable link for the run, and the link said out loud once.

**Give it a fresh private directory per run with `$(mktemp -d)`, and never a fixed name in the shared temp directory.** That directory is world-writable, so a *predictable* path inside it is one another user can pre-fill with a symlink before the run starts, and a writer that followed it would overwrite whatever it points at (CWE-59, CWE-377). `mktemp -d` closes that case twice over: the name it picks is unguessable, so there is nothing to pre-plant, and the directory it creates is mode `0700`, so nobody else can plant inside it afterwards either. The fixed name was the whole of what made the attack worth writing down, and this rule is what removes it.

**What that does not buy.** This is an instruction to the writer, not a check at the moment of writing. Nothing here opens the scratch page's path and refuses to follow a symlink: the renderer that once did that, with a test for each of its two output paths, was deleted along with the rest of the rendering step. So the residual risk is small because the predictable name is gone, not because a run that ignored this rule would be stopped. Follow it as written, because there is nothing behind it to catch a run that does not.

**Nothing quick publishes lands in `docs/work/`.** Quick writes no work-doc at any width, and this does not become the exception.

## Project-relative paths only

The page is a link, and a link goes to whoever the user sends it to. Everything in the doc travels with it, absolute paths included.

**The rule is the whole doc, not a list of sections.** A work-doc collects those paths faster than a rendered report ever did, and the places below are where it slips most often. They are the frequent offenders, and a section missing from them is not exempt.

- **Frontmatter.** `worktree` names a directory, and it sits at the very top of the page. What goes there is settled in [work-doc-template.md](work-doc-template.md), under its `Frontmatter field reference`.
- **Repo Brief.** Every line of it carries the command or the `file:line` that proved it, by its own contract ([repo-brief.md](repo-brief.md)). That makes it the one block guaranteed to be full of paths.
- **Sprint Backlog.** Every task carries a file allowlist, and the easiest thing to paste is the full path the dispatcher handed the agent.
- **Sprint Review.** An Evidence Ledger row quotes the command that ran, and that command was typed against whatever directory the shell was sitting in.
- **Dispatch records.** The inputs a wave agent received: its allowlist, its mandatory reading, the rules files, the work-doc itself.
- **Daily Updates.** A line names the file it changed.

Write every path project-relative, from the first time you write it. `docs/work/<slug>.md`, never the same path with somebody's home directory in front of it.

## Secrets on a page that travels

Personal handles, tokens, credentials and customer data follow the path rule, for the same reason and more sharply: a doc that is also a page is no place for any of them. Keep them out from the first time you write the line.

**Nothing screens the page for you, and it is worth saying which part is missing.** The banned-token hook is a `PreToolUse` hook, so it fires on the tools that write files and never on the publish step (`hooks/hooks.json`). A publish hands an existing file straight to the runtime, so whatever the doc already holds goes out with it, unread. What the write side does and does not cover is stated in `hooks/` and is not restated here, because a copy of it in this file is one that goes stale the next time that scope changes.

**The real mitigation is that a published page is private until somebody shares it.** Exposure is a decision the user makes afterwards, not something the publish does on its own, which is what keeps this a discipline rather than an incident. It is also the reason the discipline has to hold: by the time the user decides to send the link, the page already says whatever the doc said, and there is no step in between where anyone scrubs it.

**This is a writing rule now, and it binds every phase that touches the doc.** It used to be a rendering rule, applied once while the report was built. There is no render step left, so nothing sits between the last edit and the publish to scrub anything. A publish is not the moment to discover the doc is full of one person's file system, because the link exists by then and the page already carries it.

Quick mode's scratch page is assembled from blocks quick already printed, so the rule reaches those blocks too.

## Never load-bearing

Publishing is a **native-tier enhancement** in the sense [runtime-adapters.md](runtime-adapters.md) defines. Per-runtime support and the stated degrade path live in that file's "Native-tier enhancements" tables, and this is the hard rule that goes with them: **no phase may hard-require it.** A phase that cannot run without a link is a portability bug.

- **Publishing is never a precondition for closing ledger item `6d`,** or any other row. That item's exit artifact is the printed update log plus the work-doc on disk. A runtime with no publish tool still finishes the sprint.
- **A runtime with no publish tool says so once, in one line, then carries on.** Something like `No page-publishing tool in this runtime, so the work-doc stays a file on disk, at <path>.` Then give the path and move on.
- **Do not go silent about it.** Silence about a missing tool reads exactly like silence about a skipped step, and that is the failure this repo has watched happen twice.

## The update log is unchanged

The five field headings stay exactly as they are, in this order, never paraphrased: **Problem**, **Root cause**, **Solution**, **Verification evidence**, **Deployment status**. The log still prints to chat, block by block, and is still appended to the work-doc under `## Update log` by the closing edit.

The published page **augments** the chat log. It does not replace it, and it is not a reason to shorten it.

## See also

- [phases/phase-6-finish.md](phases/phase-6-finish.md), Phase 6 Step F, where the final republish runs.
- [finish.md](finish.md), the Step F protocol and the update log's field-by-field guidance.
- [phase-ledger.md](phase-ledger.md), "Closing the ledger", the tick order every republish rides on.
- [runtime-adapters.md](runtime-adapters.md), the per-runtime support table and the degrade path.
