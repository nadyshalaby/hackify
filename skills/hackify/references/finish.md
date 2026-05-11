# Finish — Phase 6

The last phase. The goal is to land the work cleanly, archive the work-doc, and leave the repo tidy. Do this **after** Phase 4 (Verify) and Phase 5 (Review) are both green.

---

## Step A — re-run verification one more time

Even if it passed in Phase 4. State drifts (other commits, env changes, hook updates). Re-run:

```
[backend]   bun test && bun run lint && bun run typecheck
[frontend]  bun run test && bun run lint && bun run typecheck
```

(Substitute your project's actual test / lint / typecheck commands.)

All green, fresh output. Paste it into the work-doc Verification section if not already there.

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

- [ ] Tests pass: `bun test`
- [ ] Linter clean: `bun run lint`
- [ ] Typecheck clean: `bun run typecheck`
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

## Step D — archive the work-doc (Options 1 + 2 only)

Move the work-doc from `<project>/docs/work/<slug>.md` to `<project>/docs/work/done/<slug>.md`. Update frontmatter:

```yaml
status: done
shipped: 2026-05-03            # add this field
shipped_via: pr                # 'merge' | 'pr'
pr_url: https://github.com/...  # if PR
```

The Post-mortem section is **mandatory** at this point. 3–8 bullets covering:

- What surprised during implementation
- What you learned about the codebase
- What pattern you'd reuse / avoid next time
- Follow-up work that emerged (link issues, link `/schedule` jobs)
- Any review feedback marked Minor that wasn't addressed (with rationale)

Don't skip this. The Post-mortem is what compounds learning across tasks. It's also where future-you will look 2 weeks from now when something related breaks.

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

# Auto-detect setup
[ -f bun.lock ] && bun install
[ -f package-lock.json ] && npm ci
[ -f Cargo.toml ] && cargo build

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
| Skipping the Post-mortem | Compounding learning lost. Always write it. |
| Worktree removal with uncommitted changes (`--force`) | User's work could vanish. Stop, ask. |
| Picking the option for the user | They pick. Always present 4. |
| Open-ended "what next?" question | Drift. Stick to the 4-options structure. |
