# Finish (Phase 6)

The last phase. The goal is to land the work cleanly, archive the work-doc, and leave the repo tidy. Do this **after** Phase 4 (Verify) and Phase 5 (Review) are both green.

---

## Step A (re-run verification one more time)

Even if it passed in Phase 4. State drifts (other commits, env changes, hook updates). Re-run:

```
[backend]   <test runner command> && <linter command> && <typecheck command>
[frontend]  <test runner command> && <linter command> && <typecheck command>
```

(Substitute your project's actual test / lint / typecheck commands.)

All green, fresh output. Paste it into the work-doc Sprint Review section if not already there.

If anything is red, **stop**. Loop back to Phase 3. Do not enter the 4-options choice with a broken build.

---

## Step B (present exactly 4 options)

Do not improvise. The user picks ONE. The format is intentionally restrictive, open-ended "what should we do now?" leads to drift.

```
Tests pass. Ready to finish. How do you want to land this?

1. Merge to <base-branch> locally
2. Push and open a Pull Request
3. Keep the branch as-is for now (no cleanup, work pauses)
4. Discard this work entirely (requires typing "discard")
```

`<base-branch>` is detected via `git merge-base HEAD <upstream>`, usually `main` or `master`. If unclear, ask.

---

## Step C (execute the chosen option)

### Option 1 (Merge to base branch locally)

```
git checkout <base-branch>
git pull --ff-only          # ensure up-to-date
git merge <feature-branch> --no-ff       # creates merge commit; preserves history
# OR
git merge <feature-branch> --ff-only     # if linear history is the project convention

# Verify cleanly merged
git status

# Push the merge
git push
```

For multi-project workspaces: each project is its own git repo. Run from inside the project (e.g., `cd <project>`).

After merging:

- Confirm `git status` is clean.
- Confirm tests still pass on `<base-branch>` post-merge.

### Option 2 (Push and open a PR)

```
git push -u origin <feature-branch>

gh pr create --title "<concise PR title>" --body "$(cat <<'EOF'
## Summary

- [bullet 1]
- [bullet 2]

## Test plan

- [ ] Tests pass: `<test runner command>`
- [ ] Linter clean: `<linter command>`
- [ ] Typecheck clean: `<typecheck command>`
- [ ] Manual smoke (if applicable): [list]

## Related

- Work-doc: docs/work/<slug>.md
- Closes #<issue> (if applicable)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

PR title: ≤70 chars. PR body: short Summary (1-3 bullets), explicit Test plan checklist, link to the work-doc.

After PR is open: report the URL to the user.

### Option 3 (Keep the branch as-is)

Do nothing. Don't push, don't tag, don't archive. Update work-doc frontmatter `status: paused` if you want, otherwise leave it. The user resumes later via `/hackify resume <slug>`.

### Option 4 (Discard)

Requires the user to type the literal word `discard` (not "yes", not "delete it"). If they type anything else, ask again.

```
git checkout <base-branch>
git branch -D <feature-branch>             # local branch
git worktree remove <worktree-path>        # if worktree was used
git push origin --delete <feature-branch>  # ONLY if branch was already pushed AND user confirms
```

**Never** `git reset --hard` to "clean up". **Never** `rm -rf` directories. The branch deletion is sufficient. If the user accidentally typed "discard" and meant otherwise, the local branch deletion is recoverable for ~30 days via `git reflog`.

---

## Step C.5, Cleanup sweep (mandatory, before archive)

Runs after Step C completes and before Step D archives the work-doc. Sweeps 8 classes of leftover/abandoned/stale state introduced or surfaced during the sprint. **Every class produces a one-line evidence record** in the work-doc Phase 6 archive, 0 findings counts as a valid record. If any class finds defects, fix inline before archiving; if a defect is too large for this sprint, file a follow-up Retrospective entry and link to it.

The SKILL.md Phase 6 table names the classes; the audit commands and remediation rules per class live here.

### Class (a) (Stale cross-references)

Catches references to files / sections / anchors that no longer exist after this sprint's file moves, splits, or deletions.

```
grep -rnE 'old-path|deleted-file' rules/ agents/ skills/ commands/ scripts/ README.md
```

Substitute `old-path` / `deleted-file` with the actual paths this sprint moved or deleted (the work-doc's Architectural touchpoints list is the source). Evidence record example: *"Class (a) stale cross-refs: 0 found via `grep -rnE 'parallel-agents\.md|clarify-questions\.md' rules/ agents/ skills/`"*. If findings appear → fix inline (update the reference to the new path).

### Class (b) (Broken internal anchor links)

Catches markdown anchor links (`[text](#anchor)` or `[text](./file.md#anchor)`) inside touched files whose target heading was renamed or removed during the sprint.

```
grep -rnE '\]\(#[a-z0-9-]+\)|\]\([^)]+\.md#[a-z0-9-]+\)' <touched-files>
```

For each hit, confirm the target heading still exists in the destination file. Evidence record example: *"Class (b) broken anchors: 0 broken / 4 valid in 2 files"*. If findings appear → fix inline (update the anchor or restore the heading).

### Class (c) (TODO/FIXME without owners)

Catches new `TODO` / `FIXME` markers introduced during the sprint that lack an owner handle or follow-up issue link.

```
git diff main..HEAD -- '*.md' '*.ts' '*.tsx' '*.js' '*.sh' \
  | grep -E '^\+' \
  | grep -iE 'TODO|FIXME' \
  | grep -vE '@[a-z0-9-]+|#[0-9]+'
```

Evidence record example: *"Class (c) ownerless TODO/FIXME: 0 found in diff"*. If findings appear → either add an owner handle / issue link inline, or remove the TODO if it's not actionable. Never leave an anonymous TODO in a hackify-shipped diff.

### Class (d) (Empty directories left after file moves)

Catches directories that were emptied by this sprint's file moves but not removed.

```
find rules agents skills commands scripts -type d -empty
```

Evidence record example: *"Class (d) empty dirs: 0 under `rules/ agents/ skills/ commands/ scripts/`"*. If findings appear → `rmdir <path>` inline (or `git rm` if git is tracking the empty dir via `.gitkeep`).

### Class (e) (Dead branches)

Catches local + remote branches created during the sprint that won't be merged (abandoned spikes, scratch branches, worktree-only branches that landed via squash on a different branch).

```
git branch --list | grep -v '^\*'
git branch -r --list 'origin/*'
```

Cross-reference each branch against the work-doc's `branch:` frontmatter and any spike-branch mentions in Daily Updates. Evidence record example: *"Class (e) dead branches: 1 found (`spike/old-attempt`); deleting locally"*. If findings appear → `git branch -d <branch>` (or `-D` if intentionally abandoned); for remote, `git push origin --delete <branch>` only if the user confirms.

### Class (f) (Unrelated changes that snuck in)

Final scope-creep audit. Cross-checks the full diff against the work-doc's Sprint Backlog file allowlists.

```
git diff main..HEAD --name-only -- . ':(exclude)docs/work/*' | sort -u
```

Compare the list against the union of every task's declared file allowlist in the Sprint Backlog. Any path in the diff but not in any allowlist → scope creep. Evidence record example: *"Class (f) scope creep: 0 unrelated paths in diff (27 paths, all in Sprint Backlog allowlists)"*. If findings appear → either justify the path inline (it served a load-bearing task discovered mid-sprint and should be added to the Sprint Backlog retroactively), or revert the path-specific changes before archiving.

### Class (g), Pre-existing errors + dead code in touched files (offer to fix)

The touched-scope quality gate. The goal is the **best version**: files this sprint changed end with nothing a reviewer would flag, no lint error, no type error, no failing test, no dead code, whether the issue was introduced this sprint OR pre-dates it.

**Baseline + detect.** Run the project's lint / typecheck / test, a dead-code scan, and the **law-scout** ([law-scout.md](law-scout.md)) **scoped to the touched files** (`git diff --name-only <base>..HEAD`). The law-scout is what turns "no lint errors" into "no engineering-law breaks": a 600-line file, an empty catch, an ownerless TODO, or a `// removed:` leftover that the project's linter does not configure will only surface here. To attribute honestly, diff against the sprint-start state (a `<base>`-checkout run, or `git stash` before re-running) so each issue is labelled *introduced* vs *pre-existing*. Introduced issues are fixed unconditionally (Phase 4 already requires it). Pre-existing issues in touched files are **surfaced and offered**:

- **Full hackify / quick**, present the list (file:line + one-line description) and OFFER to fix via a batched wizard: *"N pre-existing issues in files you touched, fix them now so the change lands clean?"* Apply approved fixes using the project's existing patterns (a fix must read as if the original author wrote it).
- **yolo**, auto-fix all pre-existing issues in the touched files, no prompt.
- **Too large for this sprint**, defer to a numbered Retrospective follow-up (file:line + rationale) ONLY with explicit user sign-off. Never silently leave.

**Whoever approves it, the parent does not write it.** Cleanup edits are code changes, so they go through dispatched agents under a file allowlist like every other change (the no-parent-authored-diff law in `SKILL.md`). Group the approved fixes into file-disjoint clusters and dispatch one agent per cluster in a single message; the parent runs the detection, holds the wizard, and re-verifies afterwards.

Whole-repo pre-existing issues OUTSIDE the touched files stay out of scope, that is a full-codebase audit (`/hackify:lawkeeper`), not the cleanup sweep. The difference is scope, not engine: the sweep runs the same bundled scanner, pointed only at what this sprint touched. Evidence record example: *"Class (g) touched-scope: 2 pre-existing lint errors in `lib/utils.ts` (fixed, approved); 1 pre-existing `clean.debt-marker` in `lib/utils.ts:88` (fixed); 0 dead code; touched files now clean."*

**Also sweep for leaked runtime state.** The Phase 4 ship gate starts real processes. Confirm none survived: no dev server still holding a port, no container left up, no temporary `.env.local` or fixture file staged into the diff. A leaked process is a class (d) finding and it will break the next boot.

### Class (h) (Work-doc references to file paths that just changed)

Catches the work-doc *itself* (and any sibling work-docs in `docs/work/`) referencing file paths that this sprint moved, renamed, or deleted.

```
grep -rnE 'old-path|moved-file' docs/work/
```

Substitute with the actual paths this sprint changed. Evidence record example: *"Class (h) work-doc path drift: 0 stale paths in `docs/work/` after substitution"*. If findings appear → fix inline in the work-doc (and in any sibling work-doc that referenced a path this sprint changed). The current sprint's work-doc is the most-likely offender because it was written before the file moves landed.

---

## Step D, archive the work-doc (Options 1 + 2 only)

**This is phase-ledger item `6c`, and it runs LAST, after Step F.** Step F's two artifacts, the printed update log and `docs/work/done/<slug>.report.html`, are produced first, while the doc is still at its live path. Then one edit closes the ledger, and only then does the file move. **Do not move the doc before that closing edit**: a doc sitting in `done/` with a row still open is the state check `[98]` reads as a sprint that stopped mid-phase, and under the old order every archive passed through it. Why this order and what it costs: [phase-ledger.md](phase-ledger.md), "Closing the ledger".

Write the Retrospective (below) first. Then make ONE edit to `<project>/docs/work/<slug>.md` that appends the update log under `## Update log`, ticks ledger rows `6c` and `6d` `- [x]` together, and sets the frontmatter:

```yaml
status: done
shipped: 2026-05-03            # add this field
shipped_via: pr                # 'merge' | 'pr'
pr_url: https://github.com/...  # if PR
```

That edit is the last content change the doc ever receives. The move is the last mechanical step:

```
git mv <project>/docs/work/<slug>.md <project>/docs/work/done/<slug>.md
```

A rename changes no content, so the ledger cannot record its own move. Assertion (c) of `[99]` is what catches a session that died in between: a doc carrying `status: done` outside `done/` reds on the next validator run.

The Retrospective section is **mandatory**, and it is written before that closing edit. 3-8 bullets covering:

- What surprised during implementation
- What you learned about the codebase
- What pattern you'd reuse / avoid in future tasks
- Follow-up work that emerged (link issues, link `/schedule` jobs)
- Any review feedback marked Minor that wasn't addressed (with rationale)

Don't skip this. The Retrospective is what compounds learning across tasks. It's also where future-you will look 2 weeks from now when something related breaks.

---

## Step D.5, Codewalk follow-up (since v0.3.2)

If the task touched an **entry point**, a route handler, a CLI command, a queue / Inngest function, a UI action, ask the user whether to refresh or create a `/codewalk` trace for it. Codewalk is the cheapest way to keep the team's mental model of the touched flow in sync with the change you just shipped.

**Detect entry-point touches** from the work-doc's "Files changed" list (or `git diff --stat <base>..HEAD --name-only` if absent). An entry-point file matches any of:

- `*.controller.ts` / `*Controller.ts` / `controllers/*.ts` (NestJS, Express)
- `*.cli.ts` / `cli/*.ts` / `bin/*.ts` (CLI commands)
- `inngest/*.ts` / `*.queue.ts` / `*.job.ts` / `workers/*.ts` (queue/job handlers)
- `app/**/route.ts` / `pages/api/*.ts` (Next.js routes)
- `*RouteHandler.ts` / `*.action.ts` (UI actions, server actions)
- `routes/*.{ts,py,rb,go,rs}` (Express/Flask/Rails/Echo/Axum)

If zero entry-point files were touched, **skip this step silently**, no prompt.

Otherwise, ask the user via the `AskUserQuestion` tool (one question, wizard-style):

> **Header:** Codewalk
>
> **Question:** This task touched `<file>` (and N other entry-point files). Update or create a `/codewalk` trace so the next reader has the current call graph?
>
> Options:
> - **Update existing trace at `.codewalk/<slug>/`** *(Recommended)*, slug already exists; re-running `/codewalk` will merge, preserve manual edits, and surface a diff callout.
> - **Create new codewalk for `<entry>`**, slug does not exist yet; this seeds the team's catalog with this flow.
> - **Skip, no codewalk needed**, the touched entry is internal-only / not worth tracing, or the team uses a different artifact for this.

To detect the slug, derive it from the touched controller's primary route (`<method-lowercase>-<path-sanitized>` per `skills/codewalk/references/data-schema.md` "Slug convention"). If the catalog `.codewalk/_catalog.json` exists, prefer the slug from there.

On "Update" or "Create", invoke `/codewalk <entry-point>` immediately. On "Skip", continue to Step F. Do not loop, this is a single ask per Finish.

This step runs after the cleanup sweep and **before** Step F, and its ledger row sits between `6b` and `6c`.

---

## Step E (worktree cleanup)

If the work was done in a git worktree (frontmatter `worktree:` is set):

```
# from inside the project repo, NOT inside the worktree itself
git worktree remove <worktree-path>

# verify
git worktree list
```

**Worktree cleanup applies to options 1, 2, and 4. NEVER for option 3.**

**It runs after Step D's `git mv`, never before it.** When the sprint used a worktree the live work-doc sits inside it, so a removal that jumps the queue takes away the path the move reads from. Its ledger row sits after `6d` and is ticked by the closing edit, since nothing can tick after the doc's last content change.

If worktree removal fails because of uncommitted changes, **stop and ask**, don't `--force` it. Uncommitted state is the user's potentially-valuable work.

---

## Worktree decision (revisited from Phase 1)

For reference, when to use a worktree at task start:

| Situation | Worktree? |
|---|---|
| Feature work > 30 minutes | Yes |
| Refactor of any size | Yes |
| Cross-cutting changes | Yes |
| Long-running task that may pause | Yes |
| Hotfix < 30 minutes on the right branch | No (in-place) |
| Pure docs / config tweak | No |
| Trivial typo fix | No |

Worktree creation (Phase 1 / Phase 2):

```
# Default location: .worktrees/ at the project root (project-local)
# Add to .gitignore if not already

WORKTREE_PATH="$(git rev-parse --show-toplevel)/.worktrees/<slug>"
BRANCH="<type>/<slug>"

git worktree add "$WORKTREE_PATH" -b "$BRANCH"
cd "$WORKTREE_PATH"

# Auto-detect setup (substitute your project's package manager install command)
<package manager install command>

# Run tests once for clean baseline
<project test command>
```

**Critical safety check**, confirm `.worktrees/` is gitignored before creating it:

```
git check-ignore -q .worktrees 2>/dev/null
```

If exit non-zero (not ignored), add `.worktrees/` to `.gitignore` and commit BEFORE creating the worktree. Otherwise the worktree pollutes the parent repo's git status.

---

## Worktree path priority (when CLAUDE.md doesn't override)

1. Existing `<project>/.worktrees/` directory (preferred, leading dot keeps it hidden).
2. Existing `<project>/worktrees/` directory.
3. CLAUDE.md project-specific override.
4. Ask the user.

---

## End-of-phase summary back to user

Keep it short. One sentence on what shipped, one on what's next (if anything).

> **Done.** PR https://github.com/.../pull/123 is open with `feat(invitations): add expires_at` (3 commits, 87 tests passing). Work-doc archived to `<project>/docs/work/done/2026-05-03-add-invitation-expiry.md`. Want me to /schedule a follow-up agent in 4 weeks to verify the migration ran cleanly across all tenants?

The follow-up `/schedule` offer applies only when there's a real signal (feature flag, staged rollout, monitoring window, "remove once X" TODO). Skip it for ordinary feature merges or bug fixes.

---

## Anti-patterns to catch

| Pattern | Reality |
|---|---|
| Merging without re-running verification | Stale evidence. Re-run. |
| `git push --force` to main | Destructive. Never without explicit user instruction. |
| `git reset --hard` to "clean up" | Risk of lost work. Don't. |
| Skipping the Retrospective | Compounding learning lost. Always write it. |
| Worktree removal with uncommitted changes (`--force`) | User's work could vanish. Stop, ask. |
| Picking the option for the user | They pick. Always present 4. |
| Open-ended "what next?" question | Drift. Stick to the 4-options structure. |
| Moving the work-doc to `done/` before the closing edit ticks its ledger | Backwards. The closing edit comes first, the `git mv` last, so the doc never sits in `done/` with an open row. |
| Ticking a phase-ledger item with no exit artifact | Untrusted tick. The item stays open until its exit artifact exists (`phase-ledger.md`). |

---

## Step F (Update log + HTML report)

Phase 6 Step F (and the on-demand `/hackify:summary` slash command) print an **update log**: one short block per thing that changed, written the way you would explain it to a colleague who was not in the room. This is the artifact the user actually reads, so it is the one place in the whole workflow where the writing matters more than the precision. It runs **before** the archive move: Step D closes the ledger and moves the file only once this step's artifacts exist. The one exception is a mid-flight `/hackify:summary`, which prints to chat and archives nothing.

**Step F also emits a styled HTML report**, a self-contained `<slug>.report.html` written straight to `docs/work/done/<slug>.report.html`, the path it will sit at once Step D's move lands. It opens with the same plain-language update log, then stats, inline-SVG charts, the findings table, action items and next steps, and closes with the cumulative Evidence appendix (the Phase 4 Evidence Ledger). **You do not write that HTML by hand**, you emit a JSON payload and `skills/hackify/scripts/render-report.py` renders the page, charts and all. Payload shape and the command: [html-report.md](html-report.md).

**And where the runtime can publish a page, publish the report too and give the user the link.** A path is something they have to open by hand and cannot send to anyone; a link is the thing they asked for. The renderer writes the publishable copy in the same run, `--artifact-out "$(mktemp -d)/<slug>.report.body.html"`, because a publisher supplies its own document shell and expects page content only. A fresh private directory each run, never a fixed name in the shared temp directory: a predictable path there is one another user can pre-fill with a symlink, and a writer that followed it would overwrite whatever it points at. The renderer refuses to write through a symlink at either output path, and an unguessable directory means it never comes up. Hand that temp file to the runtime's publish tool, then say the link in the chat message rather than leaving it in a tool result. On a runtime with no publish tool, skip it and name the path: the file on disk is the deliverable everywhere, and this is the only half of Step F that every runtime runs. **It is never a precondition for closing the ledger.** 6d's exit artifact is the printed log plus the rendered file, never a link, so a sprint finishes on a runtime that cannot publish anything. Per-runtime support and the degrade path: [runtime-adapters.md](runtime-adapters.md), "Native-tier enhancements".

### The shape (one block per update, `----` between them)

```
**Problem**
<the problem, in the user's terms>

**Root cause**
<the actual cause, plainly>

**Solution**
<the fix, in one or two sentences>

**Verification evidence**
<real evidence: what was run and what came back>

**Deployment status**
<Shipped / Not shipped, and where it is>

----
```

Repeat for every update, separated by a line containing exactly `----`. No table, no heading above the first block, no preamble.

**Budget: one block per user-visible change, and ≤120 words per block.** A sprint that
changed one thing prints one block. The five fields are each one or two sentences, not
a paragraph. This log is read by a person deciding whether the work is done, and the
length that serves them is short, so the cap is a writing instruction, not a token
trick: every field still has to earn its line with something real.

### The five fields

| Field | What goes in it | What kills it |
|---|---|---|
| **Problem** | The symptom as the user would have experienced it. "Invite links kept working after they should have expired." | Naming a function instead of a symptom. |
| **Root cause** | The real cause in one plain sentence. "Nothing ever checked the expiry date, so every link stayed valid forever." | "A missing guard clause in the validator." Same sentence in costume. |
| **Solution** | The change in outcome terms. "Added the expiry check, so links stop working the moment they pass their date." | Listing files touched. Nobody reads that here. |
| **Verification evidence** | Real evidence, trimmed. "Ran the tests: 87 passed. Also made an invite, set it back 8 days, and saw the expired message." | "Verified." or "Tests pass." with nothing behind it. |
| **Deployment status** | Where it actually is. "Shipped, it's on your `main` branch." or "Not shipped, waiting on your review." | Vagueness. The user needs to know whether they can use it. |

### Voice (this is the whole point of the format)

- **Talk like a person, not a release note.** Contractions are fine. Short sentences. If a smart friend who is not an engineer could follow it, the tone is right.
- **No jargon unless the user used it first.** If a technical word is the only honest one, use it once and add a short plain clause explaining it.
- **Never mention the workflow's own machinery.** No phase numbers, no task IDs, no reviewer letters, no scout names, no mention of the work-doc. The user asked for working software, not a tour of the process.
- **Say it and stop.** No "in conclusion", no restating the block you just wrote, no praise for your own work.
- **One block per thing the user would recognize as a change.** Group by what they would notice, not by file. Three files serving one fix is one block. Typical task: 1-5 blocks; a large one: up to 12.
- **Be honest in Deployment status.** If something is half-done or deliberately left out, say so here rather than burying it.

### Worked example (two updates)

```
**Problem**
Invite links kept working forever. Someone could dig up a link from months ago and still get in.

**Root cause**
We stored an expiry date on every invite, but nothing ever looked at it. The check was simply never written.

**Solution**
Added the missing check. An invite now stops working the moment it passes its date, and the person sees a clear "this link has expired" message instead of a confusing error.

**Verification evidence**
Wrote a test that creates an invite, moves the clock forward 8 days, and tries it. It failed before the fix and passes now. Full suite: 87 passed, 0 failed. I also clicked through it by hand.

**Deployment status**
Shipped, it's on your `main` branch.

----

**Problem**
The invites page got slow once an account had a few hundred invites, taking several seconds to load.

**Root cause**
The page asked the database one question per invite instead of one question for all of them. With 300 invites that's 300 round trips.

**Solution**
Changed it to fetch them all at once. The page now loads in about the same time whether you have 5 invites or 5,000.

**Verification evidence**
Timed it with 500 invites: 4.2 seconds before, 0.3 seconds after.

**Deployment status**
Shipped, same branch.
```

End the printed output with exactly one follow-up line:

> Happy to go deeper on any of these, just say which one.

Never omit the follow-up; never extend it.
