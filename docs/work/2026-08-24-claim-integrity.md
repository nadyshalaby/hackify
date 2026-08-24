---
slug: claim-integrity
title: Code is the only source of truth, and a check that enforces it
status: spec-review
type: feature
created: 2026-08-24
project: hackify
current_task: Phase 2.5, spec reviewer dispatched
worktree: none
branch: main
sprint_goal: Make a doc's claim about code mechanically falsifiable, so a claim that stops being true turns red at the next commit instead of at round five of a review loop.
related: 2026-08-23-wave-implementer-migration.md
---

## 0. Phase ledger

- [x] Phase 1. Clarify (answers locked by wizard, anchor recorded below)
- [x] Phase 2. Plan + GATE (signed off 2026-08-24)
- [ ] Phase 2.5. Spec review  <- in progress
- [ ] Phase 3. Implement
- [ ] Phase 4. Verify (Evidence Ledger + triad + ship gate)
- [ ] Phase 5. Review (parallel panel + refuter)
- [ ] Phase 6a. Re-verify + land
- [ ] Phase 6b. Cleanup sweep
- [ ] Phase 6c. Archive to done/
- [ ] Phase 6d. Summary + report

This runtime exposes no todo-tracker tool, so this section is the durable ledger and it is re-printed
in chat at every phase boundary.

## 1. Original Ask (verbatim)

> I want to add one golden rule for hackify, the code should be only the single source of truth and
> that forbids trusting docs and md files claims. it should be self-explanatory so we don't fake the
> conclusions or drift away from the main goal. the skill should focus of the speed of the
> development of the waves and adding instructions that stops it from AI slops, laziness, and
> halucination

## 2. Clarifying Q&A (wizard, verbatim decisions)

- **#1-A Rule + validator check.** Not prose alone. The prose-only instrument was live during the
  previous sprint and the defect it bans recurred sixteen times anyway.
- **#2-A Re-derive before you write.** Reading docs for intent and history stays allowed. Writing a
  claim about code, or citing a doc as evidence for how code behaves, requires re-deriving it from
  the code this session.
- **#3-A, #3-B, #3-C.** Prebuilt verified facts; fewer, wider waves; cut what agents read.
- **#4-A, #4-B, #4-C, #4-D.** Name all four failures explicitly: claiming without proving, reusing a
  stale number, citations that do not check out, fixing one site of a family.
- **#7-A.** The previous sprint's backlog is NOT hand-fixed. It is this sprint's test corpus.
- **#8-A.** Start by prototyping the check, scored against the previous sprint's thirteen verified
  round-5 findings. Rule text is written afterwards, around what the check actually does.

### Primary Goal & Guardrails

**North-Star Goal.** A factual claim about this repo, written anywhere in it, is either mechanically
falsifiable or explicitly marked as unverified. When such a claim stops being true, a check goes red.

**In-Scope.** The check and its tamper tests; the always-on rule written around what the check
actually enforces; the Repo Brief becoming measured rather than asserted (#3-A, because it is what
keeps the rule cheap).

**Out-of-Scope and Non-Goals.** #3-B (wider waves) and #3-C (cutting agent reading) are real and
selected, but they are a separate optimisation with their own risk profile and they do not share a
file with anything here. **Deliberately deferred to a follow-up sprint, named here rather than
dropped.** Also out: retrofitting the ~530 existing count-claims, and any attempt to check semantic
rationale drift, which no script reaches.

**Guardrails and Invariants.** The check never executes a command written in a repo file: it takes a
small fixed vocabulary, not shell. Every hard cap binds. The check must itself be tamper-tested
fail-closed, because a check that greens when broken is worse than no check.

**Success Signals.** Run against the previous sprint's round-5 corpus, the check flags the eight
mechanically checkable findings, stays silent on the four code defects, and does not pretend to catch
the one semantic-drift finding.

## 3. Acceptance Criteria

- [ ] **AC1** Scored against the thirteen verified round-5 findings, the check flags **8/8**
      mechanically checkable ones, and **0** of the 4 code defects and the 1 semantic one. Evidence:
      a scoring harness run, output pasted.
- [ ] **AC2** The check resolves the 30 live line-number citations and the `check [NN]` references
      against the 23 real check ids, and reds when any stops resolving.
- [ ] **AC3** The check never runs a command sourced from a repo file. Evidence: the vocabulary is a
      fixed enum, shown in code.
- [ ] **AC4** The check is tamper-tested fail-closed: breaking each branch reds. Evidence: a
      branch-deletion table, one row per branch.
- [ ] **AC5** An always-on rule ships, wired into `hooks/hooks.json`, with every load-bearing law in a
      bold lead (only leads survive the post-turn digest). Its four named failures are #4-A to #4-D.
- [ ] **AC6** The Repo Brief template carries the command behind every fact it states.
- [ ] **AC7** The previous sprint's fifteen backlog items are run through the check and each gets one
      written disposition: caught, missed, or out of class.
- [ ] **AC8** Full triad green, `dist/` current by checksum, all caps respected. Note `71-` and
      `15-wi-absent-cases.sh` both sit at **497/500**, so nothing may grow them.

## 4. Approach

Build the check before the rule, because the previous sprint proved prose alone does not hold. Start
from the cheap, retrofittable classes (citations, and claims that a check exists), which need no
authoring burden and can run over the whole repo today. Add the annotation-based class
(counts) scoped to the diff only, since ~530 existing count-claims make a repo-wide retrofit
impossible. Score everything against a real corpus of thirteen findings whose verdicts are already
adjudicated, so "does it work" has an answer rather than an opinion. Write the rule last, describing
what the check does, so the doctrine and the enforcement cannot drift apart.

### Repo Brief

**Every fact below carries the command that produced it, measured at `28d53d2`, version 0.15.0. This
block is the sprint's own first demonstration of AC6.**

- **Stack.** Claude Code plugin. Markdown skills, Python 3 helpers, Bash validators. No package
  manager, no build step. `ls .claude-plugin/`
- **Triad.** `bash scripts/validate-dod.sh`. Unit suites: `bash scripts/test_ban_tokens.sh` (157
  passed), `python3 skills/lawkeeper/scripts/test_audit.py` (56/56), `bash
  hooks/test_inject_context.sh` (29 passed), `bash hooks/test_block_banned_tokens.sh` (41/41).
- **Validator fragments: 20**, sourced in order from a hand-maintained list.
  `ls scripts/validate-dod.d/ | wc -l`. The validator runs `set -uo pipefail`, NOT `set -e`.
  Next free numbers are `91-` and up (`90-collisions.sh` is the last).
- **Always-on rules: 4 wired**, of 7 files in `rules/`.
  `python3 -c "import json;print(len(json.load(open('hooks/hooks.json'))['hooks']['UserPromptSubmit'][0]['hooks']))"`
  After turn 1 only each bullet's **bold lead plus a short following clause** survives into the
  digest, so every load-bearing law must live in its lead (`rules/phase-discipline.md`).
- **Markdown surface: 119 live files, 21,134 lines** (excluding `docs/work/`).
  `git ls-files '*.md' | grep -v '^docs/work/' | wc -l`
- **Line-number citations: 30 live**, 5 in markdown and 25 in scripts. Measured, and it corrected my
  assumption: markdown here cites files by NAME, the line numbers live in script comments.
  `git ls-files '*.md' '*.sh' '*.py' | grep -v '^docs/work/' | xargs grep -ohE '[A-Za-z0-9_./-]+\.(md|sh|py|json):[0-9]+' | wc -l`
- **Count-claim candidates: ~530.** `grep -ohE '\b(one|two|...|[0-9]{1,4})\s+(files?|lines?|rows?|checks?|...)\b'`
  This is why C1 is diff-scoped, not retrofitted.
- **Check ids in use: 23** (`[27]` through `[90]`).
  `grep -ohE '^\s*#*\s*\[[0-9]+[a-z]?\]' scripts/validate-dod.d/*.sh | sort -u`
- **Landmines.** (a) Agent mirrors copy ONLY the first three-backtick block; frontmatter and
  post-fence text are invisible to `--check`, which has caused four defects. (b)
  `sync_agent_mirrors.py` treats ANY unrecognised flag as WRITE mode; only `--check` is safe. (c)
  `sync-runtimes.sh --dry-run` lists every file unconditionally and cannot answer whether `dist/` is
  stale; use two syncs and compare checksums. (d) The session `grep` honours `.gitignore`, so
  `grep -r` under `dist/` silently returns nothing; use `/usr/bin/grep`. (e) `block-banned-tokens.sh`
  rejects em dashes. (f) **`71-release-mechanism-pins.sh` and `test_ban_tokens.d/15-wi-absent-cases.sh`
  are both at 497/500.** Anything landing there needs a split plan, not an edit.

### Execution waves

```
W1: T1                    the scoring corpus, everything depends on it
W2: T2, T3                the two retrofittable classes
W3: T4, T5                the annotation classes, same fragment as W2
W4: T6, T7                score, tune, tamper-test fail-closed
W5: T8, T9, T10           wire the check, write the rule, wire the rule
W6: T11, T12, T13         measured brief, backlog disposition, release
```

## 5. Sprint Backlog

- [ ] **T1** Build the scoring corpus: the 13 round-5 findings as fixtures with expected verdicts
      (8 must-catch, 5 must-not-claim), plus a runner that prints a score.
- [ ] **T2** C2, the citation resolver: every `file.ext:N` in live `.md`/`.sh`/`.py` must resolve to
      an existing file with at least N lines.
- [ ] **T3** C4, the check-exists resolver: every `check [NN]` reference names a real check id, and a
      claim that something is pinned or enforced points at executable code, not a comment.
- [ ] **T4** C1, annotated counts: a fixed-vocabulary annotation (count-matching-lines, line-count,
      file-size, literal-present, literal-absent) plus the checker. **Diff-scoped.** No shell.
- [ ] **T5** C3, declared vs used: every `{{token}}` in an agent prompt appears in its INPUTS list.
- [ ] **T6** Score against T1's corpus, tune until AC1 holds, record misses honestly.
- [ ] **T7** Tamper tests: delete each branch, prove each reds. One table row per branch.
- [ ] **T8** Wire the fragment into `scripts/validate-dod.sh`'s sourced list.
- [ ] **T9** Write `rules/claim-integrity.md`: laws in bold leads, the four named failures #4-A to
      #4-D, and the procedure for the semantic class no check reaches.
- [ ] **T10** Wire it as the 5th `UserPromptSubmit` hook; extend `hooks/test_inject_context.sh`.
- [ ] **T11** Repo Brief template carries a command per fact (`references/repo-brief.md`).
- [ ] **T12** Run the check over the previous sprint's 15 backlog items; one disposition each.
- [ ] **T13** CHANGELOG bullet, version bump, dist regeneration.

## 6. Daily Updates

## 7. Sprint Review

## 8. Retrospective
