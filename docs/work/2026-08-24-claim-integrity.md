---
slug: claim-integrity
title: Code is the only source of truth, and a check that enforces it
status: implementing
type: feature
created: 2026-08-24
project: hackify
current_task: Phase 3 W1, plan revised after spec review
worktree: none
branch: main
sprint_goal: Make a doc's claim about code mechanically falsifiable, so a claim that stops being true turns red at the next commit instead of at round five of a review loop.
related: 2026-08-23-wave-implementer-migration.md
---

## 0. Phase ledger

- [x] Phase 1. Clarify (answers locked by wizard, anchor recorded below)
- [x] Phase 2. Plan + GATE (signed off 2026-08-24)
- [x] Phase 2.5. Spec review (7 Criticals, plan revised)
- [ ] Phase 3. Implement  <- in progress
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
- **#5-A.** A refuted Critical still needs adjudication and user sign-off. **#6-A.** In yolo there is
  no gate and nobody to sign off, so a refuted Critical is fixed anyway.
- **#9-B.** Widen the check to catch the past too: retired vocabulary, section-exists,
  literal-absent. **#10-A.** Full plan, revised with all seven Criticals fixed.

**Decided after W1 reported, on the frozen answer key's own evidence. The parent had quoted 5-6
reachable; the derivation returned 3.**

- **#11-A Grade on all three legs.** Replay at `03e7a12`, the sprint base where all four reachable
  sites were live, plus the out-of-class false-positive suite, plus tamper. Two of the four were
  fixed by the previous sprint itself, so HEAD alone cannot grade them.
- **#12-B Build all four zero-reaching classes.** C1, C2, C4 and C5 reach none of the thirteen. They
  ship anyway, on prevention grounds. **The score will not move when W2 and W3 land. That is
  expected and is written down here so it is not misread as the check failing.**
- **#13-A C7 runs both polarities.** Claiming a phrase is absent where it is present, and claiming
  one is present where it is absent, are the same defect and one scanner covers both. This moves M4
  into the reachable set, which is the AC1b entry recorded below.

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

**Revised after Phase 2.5. The original AC1 was unreachable and AC2, AC3, AC6 and AC7 were unsound.
The superseded text is preserved in the spec-review section below rather than deleted.**

- [ ] **AC1** T1a freezes a per-finding label table for the 13 round-5 findings BEFORE any check is
      built: bucket, citation into the archived work-doc, the class that reaches it, and the scan
      scope required. **Frozen and committed alone at `803ef51`. The derived reachable set is 4 of
      13**, 3 at freeze plus M4 under #13-A, **not the 5-6 the parent quoted.** Grading runs three
      legs per #11-A: (a) the check hits **100% of the reachable set** replayed at `03e7a12`, the
      sprint base where all four sites were live, each verified by reading the file at that commit;
      (b) it claims **none** of the 9 out-of-class findings, the leg that cannot be tuned because
      nothing about it rewards the check for firing; (c) tamper proves every branch reds on its own
      message. **Legs (a) and (c) both have to pass. Leg (b) passing alone proves only that the
      check is quiet, which an empty file also achieves.**
- [ ] **AC1b** The label table is committed alone, before W2 opens, and any later change to a bucket
      needs a work-doc entry naming which finding moved and why. **No tuning the answer key to fit
      the check.** Committed alone at `803ef51`, before any check existed.
      **Bucket change 1 of 1, M4, `out_of_class`/`scope_blocked` to `must_catch` under C7.** Cause:
      #13-A widened C7 to both polarities. **The check widened first and the bucket followed, which
      is the allowed direction.** The banned direction is moving a bucket so an unchanged check
      scores better, and this entry exists so the two can be told apart later.
- [ ] **AC2** Every live `check [NN]` reference resolves against an id universe **derived at
      runtime** from the ok/fail label form. No literal count appears in the check or this AC. (The
      plan's original "23" was measured with a `^`-anchored command; the real universe is 88.)
- [ ] **AC3** The check never executes anything sourced from a repo file, proven on **both** halves:
      (a) the verb vocabulary is a fixed enum, shown in code; (b) every argument is constrained, a
      path must resolve inside the repo and be git-tracked, a pattern is matched literally with `-F`
      and never `-E`, and no argument ever becomes a shell word. T7 feeds hostile annotations
      (traversal, glob, `$(...)`, backtick, a ReDoS pattern) and proves each is **rejected**, not run.
- [ ] **AC4** Every check branch is tamper-tested fail-closed, and each row asserts the expected
      **failure message**, not merely a non-zero exit, so a branch's own red cannot be confused with
      a wiring red.
- [ ] **AC5** An always-on rule ships, wired into `hooks/hooks.json`, with every load-bearing law in
      a bold lead. It carries **#2-A (re-derive before you write)** as well as #4-A to #4-D, plus the
      written procedure for the semantic class no check reaches.
- [ ] **AC6** The Repo Brief template carries the command behind every fact, **as a convention that
      aids a reader in re-deriving it. It is explicitly NOT a correctness guarantee**: this sprint's
      own brief attached a command to the "23 check ids" fact and the command was the thing that was
      wrong. The same edit amends `references/repo-brief.md:13`'s ~200-word cap, which this brief
      already breaks at 342 words.
- [ ] **AC7** **Every item** in the previous sprint's backlog section gets one written disposition:
      caught, missed, or out of class. No count is asserted. Scope is stated: a one-shot scan with
      the `docs/work/` exclusion lifted, results recorded, **never wired into the validator**, since
      that tree holds 619 citations against 30 live ones and is a frozen record.
- [ ] **AC8** Full triad green, `dist/` current by two-sync checksum, no file over 500 lines. Note
      `71-release-mechanism-pins.sh` and `test_ban_tokens.d/15-wi-absent-cases.sh` are both at
      **497/500**.

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

**Revised after Phase 2.5.** T8 folded into whichever task creates a fragment (a fragment on disk
that nothing sources is a `[0]` FAIL, so creating and wiring must land together). T1 split so the
labeller cannot see the check design. T2 extends existing machinery instead of duplicating it. Four
new tasks carry decision #9-B's widened classes.

- [ ] **T1a** Freeze the label table: 13 findings, bucket, archived-doc citation, reaching class,
      required scan scope. Note that four were REFUTED (I4, I6, M5, M6), three on scope and one on
      fact, so "verified" is the wrong word for the corpus as a whole. Commit alone.
- [~] **T1b** Fixtures plus the scoring runner, built from T1a's frozen table. **Runner built
      (`scripts/score_claim_corpus.py`). Fixtures NOT built: the dispatch brief omitted that half.
      Parent error, recorded here rather than folded quietly into a later task.** Under #11-A the
      fixtures are what make leg (a) gradeable at `03e7a12`, so they land in W1b, before T6.
- [ ] **T2** C2 citations: **extend `scripts/check_doc_links.py` (198 lines) and check `[57]`**,
      which already resolve cited paths and already handle fenced blocks, inline code and the
      `docs/work/` exclusion. C2 adds only the `:N` line-count half. Handle the hard-wrapped-path
      case (M2's shape) that a naive regex splits.
- [ ] **T3** C4 check-exists, in new `scripts/validate-dod.d/91-claim-resolvers.sh`, **wired into the
      sourced list in the same commit**. Name the reference grammar and its exclusions first: bare
      `[NN]` yields 136 hits in live markdown and collides with markdown reference-link syntax.
- [ ] **T4** C1 annotated counts, in new `scripts/validate-dod.d/92-claim-annotations.sh`, **wired in
      the same commit**. **Binds the union of staged and on-disk**, with the rc/stderr tie-breaker
      from `70-invariants-and-new.sh:290-311`: rc 1 with anything on stderr is a scan that never ran,
      never a green. Fixed verb vocabulary, constrained arguments per AC3.
- [ ] **T5** C3 declared vs used: every `{{token}}` in an agent prompt appears in its INPUTS list.
- [ ] **T5b** **C5 retired vocabulary** (#9-B). Machinery already exists as `WI_DEAD_WORDS` in
      `70-invariants-and-new.sh`; it is unfed for this class. Feed it, with an allowlist, because six
      sites keep `Implementation Log` deliberately as back-compat.
- [ ] **T5c** **C6 section-name exists** (#9-B): a doc instructing a writer to use a named work-doc
      section must name one the template actually has.
- [ ] **T5d** **C7 literal-absent claims** (#9-B), **both polarities per #13-A**: a sentence
      claiming a phrase is absent, unpinned or not present where it is in fact present, AND one
      claiming a phrase is present where it is in fact absent. Reaches I4 and M4. **I4's claim and
      its quoted literal sit on one physical line at `803ef51`, and M2 in this same corpus is the
      finding proving line-based matching goes blind the moment text wraps. Match a normalised
      paragraph, not a raw line.**
- [ ] **T6** Score **once** against the frozen table. Record the score and every miss. **No tuning
      until it passes**; a bucket may move only with a work-doc entry saying which and why.
- [ ] **T7** Tamper: delete each branch, prove each reds **with its own expected message**. Plus the
      hostile-argument battery from AC3.
- [ ] **T9** Write `rules/claim-integrity.md`: laws in bold leads, **#2-A** plus #4-A to #4-D, and
      the procedure for semantic rationale drift that no check reaches.
- [ ] **T10** Wire it as the 5th `UserPromptSubmit` hook; extend `hooks/test_inject_context.sh`.
- [ ] **T11** `references/repo-brief.md`: a command per fact, and amend the ~200-word cap in the same
      edit so the template stops contradicting itself.
- [ ] **T12** Run the widened check over every item in the previous sprint's backlog section; one
      disposition each.
- [ ] **T13** CHANGELOG bullet, version bump, dist regeneration.

### Execution waves (revised)

```
W1  done   T1a frozen at 803ef51; T1b runner built, fixtures dropped by the dispatch
W1b        T1b fixtures         the missing half; leg (a) cannot be graded without them
W2         T2, T3               citations (extend 57) + check-exists (91, wired on landing)
W3         T4, T5               annotations + declared-vs-used (92, wired on landing)
W4         T5b, T5c, T5d        the widened classes; T5d now runs both polarities (#13-A)
W5         T6, T7               score once at 03e7a12, then tamper incl. hostile arguments
W6         T9, T10              the rule, and its wiring
W7         T11, T12, T13        brief, backlog disposition, release
```

**Expect a flat score through W2 and W3.** Those four classes reach nothing in the corpus and ship
on prevention grounds under #12-B. The first movement in leg (a) comes from W4.

## 6. Daily Updates

## 7. Sprint Review

## 8. Retrospective

---

## Phase 2.5 spec review: seven Criticals, and the plan does not survive as written

**Every measurable Critical verified by the parent before acting.** Where my measurement differs from
the reviewer's I record both rather than adopting either, because the difference is a regex choice
and neither of us is authoritative.

### The sprint indicted itself in its own plan

The Repo Brief claimed **"Check ids in use: 23"** and AC2 consumed that as a closed universe. The
command behind it anchors at `^`, so it only sees ids that begin a line. Measured unanchored:
**88** (reviewer measured 81; different pattern scope). Live `check [NN]` references: **14** distinct
by my regex, **25** by the reviewer's, and 14 of theirs are outside the 23.

**Built as written, T3 would have reddened on `check [75h]`, a reference this project's own agent
prompt cites.** A sprint about false count-claims put a false count-claim in its own plan, attached
the command that produced it, and the command was the thing that was wrong. **That is AC6's
refutation, found the same hour AC6 was written:** attaching a command proves reproducibility, never
correctness.

### The Critical that changes what this sprint is worth

**AC1's 8-of-13 target is unreachable, and the error is mine.** My scratchpad classified 8 of the 13
round-5 findings as "mechanically checkable". That was true in the sense "some script could in
principle catch this" and false in the sense "THIS check design reaches it", and I built the headline
AC on the first while meaning the second.

Walking them honestly against the four planned classes:

| Finding | Reachable by this design? |
|---|---|
| M3 `{{test_file_path}}` undeclared | **yes**, C3 |
| I4 `4-5 reviewers` "NOT pinned" | **maybe**, C4, repo-wide so the diff scope does not block it |
| M4 CHANGELOG counts a site it lacks | **maybe**, if replayed against its introducing diff |
| M5, M6, M7 counts in prose | **no**, unannotated and pre-existing, and C1 is diff-scoped |
| I2 retired section name | **no**, fits none of the four classes |
| I5 CHANGELOG missing half | **no**, plan-consistency |
| I6 three undeclared files | **no**, and it was REFUTED, so a must-catch bucket would demand the check reproduce my own false-clean grep |
| I1, M1, M2 + I3 | out of class by design, correctly |

So the realistic catch is **1 to 3 of 13, not 8**.

### The other five Criticals, all verified

- **T6 is self-contradictory:** "tune until AC1 holds, record misses honestly" leaves no misses. This
  is the self-grading hole I flagged at dispatch, and it is real.
- **T4 never defines "the diff"** and binds no fail-closed contract. Same trap as last sprint's
  Critical, where `--cached` alone would have been a second fail-open and the fix was the union of
  both modes plus an rc/stderr tie-breaker (`70-invariants-and-new.sh:278,290-311`).
- **`[0]` reds from T2 landing until T8, three waves later.** A fragment on disk that nothing sources
  is a FAIL (`scripts/validate-dod.sh:105-113`), so W2, W3 and W4 would all run against a red
  validator, unable to tell their own breakage from the missing source line.
- **AC7 would mass-red a frozen record.** `docs/work/` carries **619** citations (reviewer: 617)
  against 30 live ones, and `check_doc_links.py:33,52` excludes it deliberately as a record "of what
  was true then".
- **AC3 closes the verb surface and leaves the arguments open.** A fixed enum of verbs proves
  nothing about a repo-supplied path (traversal), a repo-supplied pattern handed to `grep -E`
  (ReDoS), or any argument that becomes a shell word. Cites `~/.claude/CLAUDE.md` §3.6, "Validate ALL
  user input at system boundaries" and "Sanitize file paths to prevent directory traversal".

### Importants worth acting on

- **T2 duplicates existing machinery.** `check_doc_links.py` is **198** lines, already resolves every
  cited path, already handles fenced blocks and inline code, and already excludes `docs/work/`. C2
  adds only the `:N` line-count half. Extend it; do not write a bash twin.
- **Name the fragment split up front:** `91-claim-resolvers.sh` (does this pointer resolve) and
  `92-claim-annotations.sh` (does the declared thing match the measured thing). Last sprint
  discovered this at 511 lines.
- **T11 collides with the template's own cap.** `references/repo-brief.md:13` says "Cap it at
  **~200 words**". This sprint's brief, offered as AC6's first demonstration, is **342**. Two rules
  gating one cell incompatibly, which is the I3 shape.
- **AC7 says "fifteen backlog items"; the section has 17 or 19** depending on how the I2 siblings are
  counted. Another unmeasured count-claim, in this sprint.
- **Locked decision #2-A is covered by no AC and no task.** It appears once, in the Q&A. Writing the
  rule last is exactly where the behavioural half of the ask gets lost.
- **T3 has not chosen its grammar.** Bare `[NN]` in live markdown yields 136 hits and collides with
  markdown reference-link syntax.

### Not drift, ruled explicitly

The #3-B and #3-C deferral is **not** goal drift: named in Out-of-Scope, with a reason, no shared
file, follow-up stated. One asymmetry recorded for the user rather than settled here: #3-A is the
cheapest of the three levers and the one that happens to serve the check, so "focus on the speed of
the waves" ships on its thinnest reading.
