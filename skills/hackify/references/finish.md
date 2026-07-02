# Finish — Phase 6

The last phase. The goal is to land the work cleanly, archive the work-doc, and leave the repo tidy. Do this **after** Phase 4 (Verify) and Phase 5 (Review) are both green.

---

## Step A — re-run verification one more time

Even if it passed in Phase 4. State drifts (other commits, env changes, hook updates). Re-run:

```
[backend]   <test runner command> && <linter command> && <typecheck command>
[frontend]  <test runner command> && <linter command> && <typecheck command>
```

(Substitute your project's actual test / lint / typecheck commands.)

All green, fresh output. Paste it into the work-doc Sprint Review section if not already there.

If anything is red, **stop**. Loop back to Phase 3. Do not enter the 4-options choice with a broken build.

---

## Step B — present exactly 4 options

Do not improvise. The user picks ONE. The format is intentionally restrictive — open-ended "what should we do now?" leads to drift.

```
Tests pass. Ready to finish. How do you want to land this?

1. Merge to <base-branch> locally
2. Push and open a Pull Request
3. Keep the branch as-is for now (no cleanup, work pauses)
4. Discard this work entirely (requires typing "discard")
```

`<base-branch>` is detected via `git merge-base HEAD <upstream>` — usually `main` or `master`. If unclear, ask.

---

## Step C — execute the chosen option

### Option 1 — Merge to base branch locally

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

### Option 2 — Push and open a PR

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

### Option 3 — Keep the branch as-is

Do nothing. Don't push, don't tag, don't archive. Update work-doc frontmatter `status: paused` if you want, otherwise leave it. The user resumes later via `/hackify resume <slug>`.

### Option 4 — Discard

Requires the user to type the literal word `discard` (not "yes", not "delete it"). If they type anything else, ask again.

```
git checkout <base-branch>
git branch -D <feature-branch>             # local branch
git worktree remove <worktree-path>        # if worktree was used
git push origin --delete <feature-branch>  # ONLY if branch was already pushed AND user confirms
```

**Never** `git reset --hard` to "clean up". **Never** `rm -rf` directories. The branch deletion is sufficient. If the user accidentally typed "discard" and meant otherwise, the local branch deletion is recoverable for ~30 days via `git reflog`.

---

## Step C.5 — Cleanup sweep (mandatory, before archive)

Runs after Step C completes and before Step D archives the work-doc. Sweeps 8 classes of leftover/abandoned/stale state introduced or surfaced during the sprint. **Every class produces a one-line evidence record** in the work-doc Phase 6 archive — 0 findings counts as a valid record. If any class finds defects, fix inline before archiving; if a defect is too large for this sprint, file a follow-up Retrospective entry and link to it.

The SKILL.md Phase 6 table names the classes; the audit commands and remediation rules per class live here.

### Class (a) — Stale cross-references

Catches references to files / sections / anchors that no longer exist after this sprint's file moves, splits, or deletions.

```
grep -rnE 'old-path|deleted-file' rules/ agents/ skills/ commands/ scripts/ README.md
```

Substitute `old-path` / `deleted-file` with the actual paths this sprint moved or deleted (the work-doc's Architectural touchpoints list is the source). Evidence record example: *"Class (a) stale cross-refs: 0 found via `grep -rnE 'parallel-agents\.md|clarify-questions\.md' rules/ agents/ skills/`"*. If findings appear → fix inline (update the reference to the new path).

### Class (b) — Broken internal anchor links

Catches markdown anchor links (`[text](#anchor)` or `[text](./file.md#anchor)`) inside touched files whose target heading was renamed or removed during the sprint.

```
grep -rnE '\]\(#[a-z0-9-]+\)|\]\([^)]+\.md#[a-z0-9-]+\)' <touched-files>
```

For each hit, confirm the target heading still exists in the destination file. Evidence record example: *"Class (b) broken anchors: 0 broken / 4 valid in 2 files"*. If findings appear → fix inline (update the anchor or restore the heading).

### Class (c) — TODO/FIXME without owners

Catches new `TODO` / `FIXME` markers introduced during the sprint that lack an owner handle or follow-up issue link.

```
git diff main..HEAD -- '*.md' '*.ts' '*.tsx' '*.js' '*.sh' \
  | grep -E '^\+' \
  | grep -iE 'TODO|FIXME' \
  | grep -vE '@[a-z0-9-]+|#[0-9]+'
```

Evidence record example: *"Class (c) ownerless TODO/FIXME: 0 found in diff"*. If findings appear → either add an owner handle / issue link inline, or remove the TODO if it's not actionable. Never leave an anonymous TODO in a hackify-shipped diff.

### Class (d) — Empty directories left after file moves

Catches directories that were emptied by this sprint's file moves but not removed.

```
find rules agents skills commands scripts -type d -empty
```

Evidence record example: *"Class (d) empty dirs: 0 under `rules/ agents/ skills/ commands/ scripts/`"*. If findings appear → `rmdir <path>` inline (or `git rm` if git is tracking the empty dir via `.gitkeep`).

### Class (e) — Dead branches

Catches local + remote branches created during the sprint that won't be merged (abandoned spikes, scratch branches, worktree-only branches that landed via squash on a different branch).

```
git branch --list | grep -v '^\*'
git branch -r --list 'origin/*'
```

Cross-reference each branch against the work-doc's `branch:` frontmatter and any spike-branch mentions in Daily Updates. Evidence record example: *"Class (e) dead branches: 1 found (`spike/old-attempt`); deleting locally"*. If findings appear → `git branch -d <branch>` (or `-D` if intentionally abandoned); for remote, `git push origin --delete <branch>` only if the user confirms.

### Class (f) — Unrelated changes that snuck in

Final scope-creep audit. Cross-checks the full diff against the work-doc's Sprint Backlog file allowlists.

```
git diff main..HEAD --name-only | sort -u
```

Compare the list against the union of every task's declared file allowlist in the Sprint Backlog. Any path in the diff but not in any allowlist → scope creep. Evidence record example: *"Class (f) scope creep: 0 unrelated paths in diff (27 paths, all in Sprint Backlog allowlists)"*. If findings appear → either justify the path inline (it served a load-bearing task discovered mid-sprint and should be added to the Sprint Backlog retroactively), or revert the path-specific changes before archiving.

### Class (g) — Pre-existing errors + dead code in touched files (offer to fix)

The touched-scope quality gate. The goal is the **best version**: files this sprint changed end with nothing a reviewer would flag — no lint error, no type error, no failing test, no dead code — whether the issue was introduced this sprint OR pre-dates it.

**Baseline + detect.** Run the project's lint / typecheck / test and a dead-code scan **scoped to the touched files** (`git diff --name-only <base>..HEAD`). To attribute honestly, diff against the sprint-start state (a `<base>`-checkout run, or `git stash` before re-running) so each issue is labelled *introduced* vs *pre-existing*. Introduced issues are fixed unconditionally (Phase 4 already requires it). Pre-existing issues in touched files are **surfaced and offered**:

- **Full hackify / quick** — present the list (file:line + one-line description) and OFFER to fix via a batched wizard: *"N pre-existing issues in files you touched — fix them now so the change lands clean?"* Apply approved fixes using the project's existing patterns (a fix must read as if the original author wrote it).
- **yolo** — auto-fix all pre-existing issues in the touched files, no prompt.
- **Too large for this sprint** — defer to a numbered Retrospective follow-up (file:line + rationale) ONLY with explicit user sign-off. Never silently leave.

Whole-repo pre-existing issues OUTSIDE the touched files stay out of scope — that is a full-codebase audit (`/hackify:lawkeeper`), not the cleanup sweep. Evidence record example: *"Class (g) touched-scope: 2 pre-existing lint errors in `lib/utils.ts` (fixed, approved); 0 dead code; touched files now clean."*

### Class (h) — Work-doc references to file paths that just changed

Catches the work-doc *itself* (and any sibling work-docs in `docs/work/`) referencing file paths that this sprint moved, renamed, or deleted.

```
grep -rnE 'old-path|moved-file' docs/work/
```

Substitute with the actual paths this sprint changed. Evidence record example: *"Class (h) work-doc path drift: 0 stale paths in `docs/work/` after substitution"*. If findings appear → fix inline in the work-doc (and in any sibling work-doc that referenced a path this sprint changed). The current sprint's work-doc is the most-likely offender because it was written before the file moves landed.

---

## Step D — archive the work-doc (Options 1 + 2 only)

Move the work-doc from `<project>/docs/work/<slug>.md` to `<project>/docs/work/done/<slug>.md`. Update frontmatter:

```yaml
status: done
shipped: 2026-05-03            # add this field
shipped_via: pr                # 'merge' | 'pr'
pr_url: https://github.com/...  # if PR
```

The Retrospective section is **mandatory** at this point. 3–8 bullets covering:

- What surprised during implementation
- What you learned about the codebase
- What pattern you'd reuse / avoid in future tasks
- Follow-up work that emerged (link issues, link `/schedule` jobs)
- Any review feedback marked Minor that wasn't addressed (with rationale)

Don't skip this. The Retrospective is what compounds learning across tasks. It's also where future-you will look 2 weeks from now when something related breaks.

---

## Step D.5 — Codewalk follow-up (since v0.3.2)

If the task touched an **entry point** — a route handler, a CLI command, a queue / Inngest function, a UI action — ask the user whether to refresh or create a `/codewalk` trace for it. Codewalk is the cheapest way to keep the team's mental model of the touched flow in sync with the change you just shipped.

**Detect entry-point touches** from the work-doc's "Files changed" list (or `git diff --stat <base>..HEAD --name-only` if absent). An entry-point file matches any of:

- `*.controller.ts` / `*Controller.ts` / `controllers/*.ts` (NestJS, Express)
- `*.cli.ts` / `cli/*.ts` / `bin/*.ts` (CLI commands)
- `inngest/*.ts` / `*.queue.ts` / `*.job.ts` / `workers/*.ts` (queue/job handlers)
- `app/**/route.ts` / `pages/api/*.ts` (Next.js routes)
- `*RouteHandler.ts` / `*.action.ts` (UI actions, server actions)
- `routes/*.{ts,py,rb,go,rs}` (Express/Flask/Rails/Echo/Axum)

If zero entry-point files were touched, **skip this step silently** — no prompt.

Otherwise, ask the user via the `AskUserQuestion` tool (one question, wizard-style):

> **Header:** Codewalk
>
> **Question:** This task touched `<file>` (and N other entry-point files). Update or create a `/codewalk` trace so the next reader has the current call graph?
>
> Options:
> - **Update existing trace at `.codewalk/<slug>/`** *(Recommended)* — slug already exists; re-running `/codewalk` will merge, preserve manual edits, and surface a diff callout.
> - **Create new codewalk for `<entry>`** — slug does not exist yet; this seeds the team's catalog with this flow.
> - **Skip — no codewalk needed** — the touched entry is internal-only / not worth tracing, or the team uses a different artifact for this.

To detect the slug, derive it from the touched controller's primary route (`<method-lowercase>-<path-sanitized>` per `skills/codewalk/references/data-schema.md` "Slug convention"). If the catalog `.codewalk/_catalog.json` exists, prefer the slug from there.

On "Update" or "Create", invoke `/codewalk <entry-point>` immediately. On "Skip", continue to Step E. Do not loop — this is a single ask per Finish.

---

## Step E — worktree cleanup

If the work was done in a git worktree (frontmatter `worktree:` is set):

```
# from inside the project repo, NOT inside the worktree itself
git worktree remove <worktree-path>

# verify
git worktree list
```

**Worktree cleanup applies to options 1, 2, and 4. NEVER for option 3.**

If worktree removal fails because of uncommitted changes, **stop and ask** — don't `--force` it. Uncommitted state is the user's potentially-valuable work.

---

## Worktree decision (revisited from Phase 1)

For reference — when to use a worktree at task start:

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

**Critical safety check** — confirm `.worktrees/` is gitignored before creating it:

```
git check-ignore -q .worktrees 2>/dev/null
```

If exit non-zero (not ignored), add `.worktrees/` to `.gitignore` and commit BEFORE creating the worktree. Otherwise the worktree pollutes the parent repo's git status.

---

## Worktree path priority (when CLAUDE.md doesn't override)

1. Existing `<project>/.worktrees/` directory (preferred — leading dot keeps it hidden).
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

---

## Summary table — authoring guidance

Phase 6 Step F (and the on-demand `/hackify:summary` slash command) emit a concise 2-column Area/Change markdown table covering every change shipped. The table is the single most-skimmable artifact of a hackify task — the user reads it to verify alignment before the work-doc archive moves to `done/`.

**Step F also emits a styled HTML report** — a self-contained `<slug>.report.html` beside the archived work-doc. It opens with a plain-language **"What changed & why it matters"** summary (B2, for a non-technical reader), then stats, inline-SVG charts, the findings table, action items, and next steps, and **closes with a cumulative Evidence appendix** (the Phase 4 Evidence Ledger — every task/acceptance item with its trimmed proof). The Area/Change table is embedded in it AND printed to chat. Authoring + placeholder-token map: [html-report.md](html-report.md).

### Area-label rules (left column)

- 1–4 words. Concept/theme labels (e.g. `Plugin manifest`, `Validator coverage`, `Slash command`).
- NOT a file path. NOT a DoD bullet ID. NOT a Task ID.
- Same noun-phrase shape across all rows for visual rhythm.
- Group by conceptual theme, not by file: if three files all change to add the same feature, one row, not three.

### Change-cell rules (right column)

- ≤25 words. Present-tense action verbs ("bumps", "adds", "tightens", "splits").
- Use `backticks` for every technical token: filenames, identifiers, version strings, glob patterns, regex.
- Do not editorialize ("nicely tightens", "elegantly removes") — just state the change.
- If a single area has multiple changes, pick the most user-visible and append a brief secondary clause; do not list >3 changes per cell.

### Grouping heuristics

- File-family clustering: changes to `plugin.json` + `marketplace.json` collapse into one `Plugin manifest` row.
- DoD-bullet clustering: changes that all serve one DoD bullet collapse into one row.
- Severity-based ordering: most user-impactful row first; pure-internal/validator rows last.

### Worked example (5-row table)

| Area | Change |
|---|---|
| Plugin manifest | `version` bumped to `0.1.4` across `plugin.json` and `marketplace.json` |
| Quick mode | new `skills/quick/SKILL.md` registers `/hackify:quick`; skips Plan+Gate, Spec review, Multi-reviewer, 4-options finish |
| Summary command | new `commands/summary.md` registers `/hackify:summary`; on-demand Area/Change recap |
| SKILL.md | adds Phase 6 Step F + phrase triggers + `When to invoke` pointer to `/hackify:quick` |
| Validator | checks `[18]`–`[23]` enforce both features cannot regress silently |

End the printed output with exactly one follow-up line:

> Happy to walk through any of these in more detail — happy to elaborate.

Never omit the follow-up; never extend it.
