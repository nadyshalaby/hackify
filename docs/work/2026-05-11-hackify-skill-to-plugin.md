---
slug: hackify-skill-to-plugin
title: Convert hackify skill to installable Claude Code plugin
status: implementing
type: refactor
created: 2026-05-11
project: hackify
current_task: W5 (paused — awaiting gh auth refresh)
worktree: /Users/corecave/Code/hackify
branch: main
related: []
---

# Convert hackify skill to installable Claude Code plugin

## Original Ask (verbatim)

> I want to convert the hackify skill to installable plugin for claude to host it on github and claude marketplace to sharing with community and my friends and maintain it

## Clarifying Q&A (locked)

1. **Slash command identity** — `/hackify:hackify`. Plugin `hackify`, skill folder `skills/hackify/`. *(Re-gated 2026-05-11 after Phase 2.5: original wizard option "preserve `/hackify` via `commands/`" turned out to be impossible because plugin commands are also namespaced.)*
2. **Generalization** — Generalize fully. Strip Syanat / graphify / Syanat-workspace paths. Replace with generic `<project>` / `<workspace>` placeholders. Optional `CLAUDE.md` companion files referenced as best-effort, not required.
3. **Distribution** — Self-hosted marketplace in the same repo (`.claude-plugin/marketplace.json` at repo root, `marketplace.name = "hackify-marketplace"`). Users install with `/plugin marketplace add nadyshalaby/hackify` then `/plugin install hackify@hackify-marketplace`. Official Anthropic marketplace submission is **out of scope** for v0.1.0.
4. **Local migration** — Move source from `~/.claude/skills/hackify/` into the new repo. Remove the original local skill. Install the plugin from the local path so day-to-day use comes from the plugin itself.
5. **Repo location** — `/Users/corecave/Code/hackify/`.
6. **Visibility** — Public.
7. **License** — MIT.
8. **README depth** — Polished launch (~300 lines): hero, install, when-to-use, 6-phase diagram, per-phase explainers, FAQ, contributing pointer.
9. **Repo name** — `hackify` (both GitHub repo and local dir).

## Assumptions (confirm at gate or correct in chat — small fixes are find-replace)

- **GitHub username:** `nadyshalaby` (confirmed via `gh auth status`).
- **Author display name:** `Nady Shalaby`.
- **Author email:** `nadyshalaby@gmail.com`.
- **Marketplace name:** `hackify-marketplace` (the `name` field inside `marketplace.json`, distinct from the plugin name — required by Claude Code so the install command can disambiguate).
- **Stack opinions** (Bun / Biome / 2-space / single-quotes) — kept inside `references/code-rules.md` but reframed under a leading "Author's reference stack — substitute your own" paragraph.
- **§0 Skill-First Routing preamble** in the current SKILL.md — workspace `CLAUDE.md` global law, not plugin business. **Strip entirely.**
- **`graphify` mentions** — strip wholesale from `SKILL.md` and reference files. Replace with generic "use Grep / Read / your codebase exploration tool of choice."
- **Frontend-design Syanat brand spec reference** — strip. Keep the rest of `references/frontend-design.md` as general visual-design wisdom.
- **`evals/evals.json`** — ship as-is; add CHANGELOG note that it's intended for use with the `skill-creator` plugin if installed.

## Definition of Done

- [ ] `/Users/corecave/Code/hackify/` is a valid Claude Code plugin source tree containing: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `skills/hackify/SKILL.md`, `skills/hackify/references/*.md` (9 files), `skills/hackify/evals/evals.json`, `README.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore`.
- [ ] `plugin.json` validates: `name=hackify`, `version=0.1.0`, `description`, `author { name, email, url }`, `repository`, `homepage`, `license=MIT`, `keywords`. Verified by `jq -e .` exit 0.
- [ ] `marketplace.json` validates: `name=hackify-marketplace`, `owner { name }`, `plugins[]` array containing one entry referencing the `hackify` plugin. Verified by `jq -e .` exit 0.
- [ ] `skills/hackify/SKILL.md` has **zero** occurrences (case-insensitive grep) of: `Syanat`, `SyanatBackend`, `SyanatFrontend`, `graphify`, `corecave`, `nadyshalaby`, `/Users/corecave/`. Verified by `grep -ic` returning 0 per token.
- [ ] All 9 `skills/hackify/references/*.md` files: same scrub. Verified by `grep -rci` over the directory returning 0 per token.
- [ ] `skills/hackify/evals/evals.json` same scrub. Verified by `grep -ic` over the file.
- [ ] `README.md` exists with all polished-launch sections (hero, install, when-to-use, 6-phase diagram, per-phase explainers, FAQ, contributing). ≥250 lines, ≤450 lines.
- [ ] Initial git commit lands on `main`; tag `v0.1.0` exists locally.
- [ ] Public GitHub repo `github.com/nadyshalaby/hackify` exists with `main` and tag `v0.1.0` pushed. (T12 pauses to prompt for `gh auth login` if token still expired.)
- [ ] Local skill removed: `~/.claude/skills/hackify/` no longer exists.
- [ ] Plugin installed from local marketplace path; you verify `/hackify:hackify` triggers the workflow end-to-end.
- [ ] T14 DoD-validation script runs clean (all `jq`/`grep` checks pass).
- [ ] Work-doc archived to `docs/work/done/2026-05-11-hackify-skill-to-plugin.md` with a Post-mortem section.

## Approach

Scaffold the repo at `/Users/corecave/Code/hackify/` with the standard Claude Code plugin layout (`.claude-plugin/`, `skills/hackify/`, no `commands/` — plugin skills create the slash command directly). Author manifest, marketplace metadata, license, changelog, gitignore inline (small determinate files). Dispatch parallel subagents for the substantive content work: scrub the 9 reference files (≥51 Syanat tokens to remove; `parallel-agents.md` is the biggest target with 13 Syanat + 6 absolute path refs); rewrite `SKILL.md` (strip §0 + workspace refs + graphify + Syanat, reframe stack-opinions paragraph and FE section). After SKILL.md is finalized, author the polished README (reads the finalized SKILL.md to keep phase explainers consistent). Initial commit, GitHub repo creation, push. Cut the local skill loose; install plugin from local marketplace path; you verify `/hackify:hackify` works. T14 DoD-validation script runs all `jq`/`grep -ic` checks in one shot for Phase 4.

### Execution waves

```
Wave 1 (parallel inline — small determinate files; no subagent overhead):
  T1  Scaffold directories + .gitignore
  T2  Author .claude-plugin/plugin.json
  T3  Write LICENSE (MIT)
  T4  Write CHANGELOG.md
  T8  Copy evals/evals.json into skills/hackify/evals/

Wave 2 (parallel agents — substantive content rewrites):
  T5  Copy + heavy scrub of 9 reference files into skills/hackify/references/
  T6  Author generalized skills/hackify/SKILL.md (strip §0 + reframe)

Wave 3 (sequential after Wave 2):
  T9  Author .claude-plugin/marketplace.json (inline; small)
  T10 Author README.md (parallel agent; reads finalized SKILL.md from T6)

Wave 4 (sequential — git):
  T11 git init + initial commit + tag v0.1.0

Wave 5 (sequential — network + local install + your verification):
  T12 gh auth status pre-flight → gh repo create (public) + push main + push tag
  T13 Remove ~/.claude/skills/hackify/, install plugin from local marketplace path,
      you verify /hackify:hackify works end-to-end

Wave 6 (Phase 4 Verify):
  T14 DoD-validation shell script (jq + grep -ic checks)
```

## Tasks

- [ ] **T1** — Scaffold directory tree at `/Users/corecave/Code/hackify/`: `.claude-plugin/`, `skills/hackify/references/`, `skills/hackify/evals/`, `docs/work/done/`. Write `.gitignore` (ignore `node_modules/`, `.DS_Store`, `*.log`, `.idea/`, `.vscode/`).
- [ ] **T2** — Author `.claude-plugin/plugin.json` (name=hackify, version=0.1.0, description, author{name,email,url}, repository, homepage, license=MIT, keywords[]).
- [ ] **T3** — Write `LICENSE` (MIT, copyright 2026 Nady Shalaby).
- [ ] **T4** — Write `CHANGELOG.md` with the v0.1.0 entry. Include a "Maintenance notes" section: every release MUST bump `version` in `plugin.json` or installed users won't auto-update.
- [ ] **T5** — Copy 9 reference files from `~/.claude/skills/hackify/references/` into `skills/hackify/references/`; scrub each for: `Syanat*` (~51 refs total), `graphify` (~4), `/Users/corecave/` (~7 absolute paths), `corecave`/`nadyshalaby` (~7), workspace-specific CLAUDE.md mentions (~15). Largest target: `parallel-agents.md` (13 Syanat + 6 corecave + 5 CLAUDE.md refs). Verify each file with `grep -ic <token>` returning 0.
- [ ] **T6** — Author `skills/hackify/SKILL.md` (generalized rewrite of the 366-line source): strip §0 Skill-First Routing preamble entirely; strip `~/.claude/CLAUDE.md` and `<workspace>/CLAUDE.md` workspace-specific refs (replace with generic "honor `CLAUDE.md` if present"); strip Syanat / graphify mentions; reframe Bun/Biome stack-opinions paragraph as "author's reference stack — substitute your own"; strip Syanat brand-spec reference from FE section; update file map to drop `commands/`; keep all 6 phases intact verbatim.
- [ ] **T8** — Copy `evals/evals.json` verbatim into `skills/hackify/evals/`; run `grep -ic` for `Syanat`, `corecave`, `nadyshalaby` and patch any hits.
- [ ] **T9** — Author `.claude-plugin/marketplace.json`: `name=hackify-marketplace`, `owner{name="Nady Shalaby",email,url}`, `plugins[]` with one entry pointing at the `hackify` plugin (name, description, version, source=this repo).
- [ ] **T10** — Author `README.md` (polished launch). Must read finalized `skills/hackify/SKILL.md` first to keep phase explainers consistent. Sections: hero pitch, install snippet (with the correct `hackify@hackify-marketplace` syntax), when-to-use, 6-phase ASCII diagram, per-phase explainers (≤80 words each), FAQ (≥5 questions), contributing pointer, license link. ≥250 lines, ≤450 lines.
- [ ] **T11** — `git init`; `git add .`; initial commit with conventional-commit message; tag `v0.1.0`.
- [ ] **T12** — `gh auth status` pre-flight; if expired, pause and prompt for `gh auth login`. Then `gh repo create nadyshalaby/hackify --public --source . --remote origin --push`; `git push origin v0.1.0`.
- [ ] **T13** — Remove `~/.claude/skills/hackify/`; instruct you to run `/plugin marketplace add /Users/corecave/Code/hackify` then `/plugin install hackify@hackify-marketplace`; you type `/hackify:hackify` and confirm the workflow triggers.
- [ ] **T14** — Write `scripts/validate-dod.sh` (committed in T11) that runs all `jq -e .` parse checks + all `grep -ic <token> <file>` checks from the DoD and exits non-zero if any fail. Run it; paste output into Verification section.

## Implementation Log

### 2026-05-11 — Phase 2.5 spec self-review (complete)

Dispatched 3 parallel reviewers. Findings folded into plan:
- **Critical (Reviewer B):** `commands/hackify.md` inside a plugin doesn't create bare `/hackify` — plugin commands are namespaced like skills. **Re-gated** with user → chose `/hackify:hackify`. Dropped commands shim from plan.
- **Critical (Reviewer C):** T5 grossly under-scoped (51 Syanat + 7 absolute paths + 15 CLAUDE.md refs across 9 files); `parallel-agents.md` is largest target. Re-scoped in revised Tasks.
- **Important:** install command syntax wrong (`hackify@hackify-marketplace` not `hackify`); marketplace.json needs `owner` field; gh auth pre-flight check missing; DoD-validation has no task → added T14; T10 README must run after T6 SKILL.md is final; T8 evals.json needs same scrub.
- **Minor:** README line bounds tightened; CHANGELOG must call out version-bump discipline.

### 2026-05-11 — Wave 1 (T1–T4, T8) — complete

Scaffolded directory tree, wrote `.gitignore`, `LICENSE` (MIT), `CHANGELOG.md`, `.claude-plugin/plugin.json` inline. Copied `evals/evals.json` from source — discovered 5 Syanat/SyanatBackend/SyanatFrontend refs (not assumed during planning); rewrote inline with generic-but-plausible eval prompts preserving the workflow-shape assertions. `jq` parse: all valid. Token scrub: 0 hits per token after rewrite.

### 2026-05-11 — Wave 2 (T5, T6) — complete

Dispatched 2 parallel foreground agents in one message:
- **T5 agent** scrubbed 9 reference files. Per-file substitution counts (Syanat / graphify / corecave / CLAUDE.md refs): `parallel-agents.md` (13/1/6/5), `frontend-design.md` (9 Syanat), `implement-and-test.md` (6 Syanat), `review-and-verify.md` (3+1), `finish.md` (2+2), `clarify-questions.md` (2+3), `code-rules.md` (2), `debug-when-stuck.md` (1), `work-doc-template.md` (2). All 9 files: 0 hits across all tokens after scrub. Line counts: source 1976 lines → dest 1993 lines (slight expansion from reframing prose).
- **T6 agent** rewrote `SKILL.md`. Source 366 → dest 366 lines. Stripped §0 (not present in source — workspace CLAUDE.md), Syanat workspace lines, graphify commands, workspace CLAUDE.md §-references. Reframed FE section to drop Syanat brand spec. 0 hits across all tokens.

Verification: `grep -rci` for `Syanat|graphify|corecave|nadyshalaby` over `skills/` returned 0 in every case.

### 2026-05-11 — Wave 3 (T9, T10) — complete

Wrote `.claude-plugin/marketplace.json` inline (name=`hackify-marketplace`, owner.name=`Nady Shalaby`, 1 plugin entry). Dispatched README agent in parallel — read finalized SKILL.md before authoring to keep phase explainers consistent. Output: 253 lines, 13 sections including hero, install, when-to-use, 6-phase ASCII diagram + per-phase explainers, work-doc explainer, parallel-agents section, file map, design principles, stack assumptions, 11-question FAQ, contributing, license. Sole `nadyshalaby` refs are the legitimate install snippet and GitHub Contributing URL.

### 2026-05-11 — Wave 4 (T11, T14) — complete

Wrote `scripts/validate-dod.sh` (executable; sole-purpose accumulator for the shipping DoD). One bug discovered on first run (em dash in error message — bash variable parsing) and patched. After patch: ALL CHECKS PASSED. Created initial commit `7f5f84d` (19 files, 3057 insertions) and annotated tag `v0.1.0`.

### 2026-05-11 — Phase 5 multi-reviewer — complete

Dispatched 3 parallel foreground reviewers in one message:
- **Reviewer A (security & correctness):** no critical. 3 important — `source` field shape in marketplace.json, `repository` field shape in plugin.json (both flagged as "works today, may break under future schema tightening" — deferred to follow-up release), and confirmation that `nadyshalaby/hackify` shortcut resolves on `/plugin marketplace add`. 7 minor including .gitignore missing credential patterns.
- **Reviewer B (quality & polish):** 1 critical (gate-location wording drift README↔SKILL.md), 4 important (`as of 2026-05-03` orphan reference, CHANGELOG broken grammar, tagline drift across 4 manifests, compact phrasing inconsistency). 12 minor.
- **Reviewer C (DoD coverage):** 0 critical. 3 important (validator coverage of evals.json per-file; validator missing `nadyshalaby` token; README slim end of band at 253/450). T1–T11 + T14 DONE; T12 + T13 pending (expected, network + manual verification).

Applied patches in one batch (commit `6762896`):
- README gate wording aligned with SKILL.md (Plan → Spec review is the gate)
- Stripped `as of 2026-05-03` orphan reference from SKILL.md
- Fixed CHANGELOG grammar in Maintenance notes section
- Normalized plugin description in marketplace.json to match plugin.json verbatim
- Added credential patterns to .gitignore (`.pem`, `.key`, `.p8`, `.p12`, `id_rsa*`, `id_ed25519*`, `credentials.json`, `secrets.*`, `.netrc`)
- Tightened validate-dod.sh: nadyshalaby token check, explicit evals.json per-file check, comment explaining `-e` omission

After patches: `bash scripts/validate-dod.sh` → ALL CHECKS PASSED. Tag `v0.1.0` force-updated locally to commit `6762896` (safe pre-push). Two commits on `main`: `7f5f84d` (initial) → `6762896` (review patches).

### 2026-05-11 — Wave 5 (T12, T13) — paused

Re-checked `gh auth status` after the commits — token still expired (was expired before plan started; documented as a T12 prerequisite). Surfaced to user with the explicit `gh auth login -h github.com` command. Will resume `gh repo create` + push + tag-push as soon as user confirms re-auth.

T13 (remove local skill + local plugin install + user verification of `/hackify:hackify`) is the final step.

_(further entries appended one per completed task during Phase 3.)_

## Verification

_(filled in during Phase 4 — paste fresh evidence per DoD bullet, including T14 script output.)_

## Post-mortem

_(filled in during Phase 6.)_
