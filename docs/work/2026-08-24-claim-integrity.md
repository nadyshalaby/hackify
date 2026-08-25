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
  **Partly superseded 2026-08-25 by #16-C and #18-C**, which fixed I2 (three instruction sites naming
  a retired work-doc section), the fourth site of that same family found by W4, and I4 (a validator
  comment describing an `orchestration.md` row that does not exist). The rest of the backlog is still
  carried unfixed under #7-A. **Fixing them costs no proof**: every check is graded against blobs
  pinned by SHA in `scripts/claim_fixtures.json`, and replay ignores the live tree, which is the
  reason the fixtures were built per-finding in W1b rather than as one snapshot.
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
- **#14-A Counts are guarded by floors in the checking code, not by annotations in prose.** Taken
  after the T4 agent declined to build C1 and argued the class cannot be built under this sprint's
  own guardrail. Replaces T4. See the Wave 3 entry for the full argument.
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

**Success Signals.** Run against the previous sprint's round-5 corpus, the checks catch every finding
in the reachable set and stay silent on the rest. **Corrected 2026-08-25.** This paragraph read "the
eight mechanically checkable findings ... the four code defects ... the one semantic-drift finding"
until now, an 8/4/1 split that Phase 2.5 replaced with the frozen answer key's 4 reachable and 9 out
of class, and that nobody updated here. **The goal statement was carrying numbers its own answer key
contradicted, which is precisely the defect this sprint exists to catch, sitting in the sprint's own
goal.** Found while recording decision #15-A. The live figures are not restated here on purpose:
`scripts/claim_corpus.json` holds them and `scripts/score_claim_corpus.py` reds when it drifts from
its own totals, so a number copied into this paragraph could go stale again exactly as that one did.

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
- [ ] **AC1b, entry 2 of 2. Decision #15-A, a bucket change considered and REFUSED.** The user
      accepted W4's refusal to build a check for M4 and dropped the build target from 4 to 3.
      **The bucket was NOT moved.** Moving M4 to `out_of_class` would turn a 3 of 4 into a 3 of 3
      by editing the answer key, which is the direction AC1b exists to forbid, and the fact that a
      user authorised the target change does not convert an unchanged check into a better one. The
      target drop is recorded instead as `counts.must_catch_buildable = 3` and
      `counts.must_catch_refused = 1`, with the refusal and its measurements on the M4 finding
      itself. `counts.must_catch` stays 4, which is the number the scorer validates against the
      findings, so the headline can never read as a clean sweep. **Raised with the user as a
      conflict between #15-A and AC1b rather than resolved silently.**
- [ ] **AC2** Every live `check [NN]` reference resolves against an id universe **derived at
      runtime** from the ok/fail label form. No literal count appears in the check or this AC. (The plan's
      original "23" was measured with a `^`-anchored command, and the "88" that replaced it counted
      every `[NN]` token rather than the declared ones. The declared universe is 82, which check
      `[91]` derives at runtime and this AC deliberately does not hardcode. Corrected here because
      an AC asserting a wrong count in a sprint about wrong counts is the defect on display.)
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
- [ ] **AC9** The shipped rule answers the **speed half** of the ask, not only the claim-integrity
      half. Scoped to **#3-A only**: the anchor above defers #3-B (wider waves) and #3-C (cutting
      agent reading) to a follow-up sprint, and an AC that quietly re-scoped them back in would be
      drift. **This AC was written naming all three and is corrected here**, which is the same class
      of error as the Success Signals above and was found in the same pass. It carries the paired mechanism this sprint demonstrated: the dispatch
      brief hands every wave agent pre-derived file:line facts so none of them pays for orientation,
      **and** carries standing permission, in words, to contradict any of those facts with the
      command that disproves it. Both halves ship or neither does, on the evidence that three of
      this sprint's wrong facts originated in the parent's own briefs. **No speed number is
      asserted**: there is no counterfactual wave, so the rule claims a changed division of agent
      effort, which the wave reports show, and not a measured time saving, which nothing here
      measures.
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
- **Count-claim candidates: several hundred, magnitude only.** Two independent measurements with
  different patterns give **571** and **774** over live md, sh and py with `docs/work/` excluded.
  Neither reproduces the "~530" that stood here, and **the command recorded alongside that figure did
  not measure what its sentence claimed**: it contained `...` inside a `grep -E` alternation, which
  matches any three characters rather than marking an elision, so it counted more than "one, two, a
  number". Corrected rather than deleted, because it is this sprint's third instance of a fact whose
  attached command was the wrong part. **The magnitude is what the plan rested on and the magnitude
  holds**, which is why C1 was never retrofittable. The class itself is now declined under #14-A.
- **Check ids: 82 declared, 88 `[NN]` tokens.** Two different things, and I gave both as "the
  universe" at different times. Declared means a `yellow "[NN]"` header:
  `git ls-files 'scripts/validate-dod.d/*.sh' | xargs /usr/bin/grep -hE '^yellow "\[' | /usr/bin/grep -oE '\[[0-9]+[a-z]?\]' | sort -u | wc -l`
  The 8 extra tokens are `[70]`, a check family, and `[78a]` to `[78f]`, comment-block labels. **The
  earlier "23" came from a `^`-anchored command and was wrong too.** Check `[91]` resolves against the
  declared set, and a resolver built from the token set would let a fabricated `check [78c]` pass.
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
- [x] **T4** C1 annotated counts. **DECLINED, nothing built. Superseded by T4b under #14-A.**
      The class cannot be built under this sprint's own guardrail: an annotation may carry a command
      (banned), a pattern that becomes a regex (banned), a literal counted with `grep -F` (safe but
      near-empty, since real count claims count files, rows and line spans rather than occurrences of
      one string), or a name selecting a measurement hardcoded in the fragment (safe, but then the
      fragment already holds the measurement and the annotation is a second place to keep in sync).
- [ ] **T4b** **Floors in the checking code** for the quantities that matter, the working form of
      the same idea. The repo already does this at `20-templates.sh:4` (`check_line_range`) and in
      the `_FLOOR=` idiom in `[76]`, `[91]` and `[93]`. Pick the quantities other things actually
      depend on; a floor on a number nobody reads is ceremony.
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

### 2026-08-24, Wave 1, the answer key and the runner (T1a, T1b runner half)

`T1a` landed alone as `803ef51`, before any check existed, which is what AC1b asks for. Thirteen
findings, each labelled with the class that reaches it and the bucket it scores in.

**The derived number is 3, not the 5-6 the plan assumed, and the gap was the parent's error.** The
plan's estimate came from asking whether some script could in principle reach each finding. The
labeller asked whether the classes this sprint is actually building reach it. Those are different
questions and the loose answer had been reported as the tight one.

Verified the labeller rather than taking it on trust, since a corpus that grades everything
downstream is worth one round of checking. All three held. Two of the three are no longer live: I2's
filed site and M3's token were both fixed by the previous sprint itself, at `ab5cb74`. Only I4
survives at HEAD, carried out of the last sprint unfixed by a deliberate re-route to Phase 6.

Read each file at the sprint base `03e7a12` and confirmed all three were live there, so the finding
set is gradeable, just not against today's tree. That is what drove decision #11-A.

**What the corpus is actually worth, stated plainly so nobody re-litigates it at T6.** The
must-catch leg is small. The other leg is not: nine findings are things no check may ever flag, and
they include a timing property, two policy sentences disagreeing with each other, and the parent's
own false-clean grep. A check that claims any of those is fabricating, which is the exact behaviour
this sprint exists to stop, and that leg cannot be gamed because nothing rewards the check for
firing. Baseline before any check is wired: 0 of 4 caught, 0 of 9 wrongly claimed.

`T1b`'s runner landed as `47e3a01`. It reads the key and never writes it, cross-checks the counts
block against the per-finding data, and exits 2 when the two disagree. Proven by tampering: editing
`counts.must_catch` to 9 produces `counts.must_catch says 9 but the findings measure 4; the answer
key has drifted from its own totals`, and restoring it returns 0.

**`T1b`'s fixtures half was not built, because the parent's dispatch brief left it out.** Recorded
here rather than folded quietly into a later task. It is dispatched as W1b.

### 2026-08-24, decisions taken on W1's evidence

`744da57` widened C7 to both polarities per #13-A and moved M4 to follow, the sprint's first and so
far only bucket change. The direction is what AC1b is for: the check widened first, by an explicit
decision, and the label followed. Reachable goes 3 to 4.

While pinning M4's replay base, hit the defect class this sprint is about. `agents/wave-implementer.md`
was renamed from `agents/wave-task-implementer.md` at `58c1118`, so asking git for the old path at a
later commit returns an empty blob and a **false zero**, which reads exactly like "the defect is
absent". The wrong base was nearly handed to W1b as a verified fact. Fixture pins are now git blob
SHAs, which are content hashes and cannot drift, and W1b is required to fail loudly on a path that
does not exist at its commit rather than return empty.

### 2026-08-24, Wave 1b, and two more parent errors the agent caught

The fixtures agent was asked to report anything contradicting the facts it was handed. It returned
two, both correct, and verifying them cost less than a fix would have.

**Parent error 5, a line number that was an artifact of the parent's own command.** The brief said
I2's literal was live at lines 5, 34, 57 and 223 of its blob. It is live at 3 sites, not 4. The
phantom came from running `git show ... | sed -n '30,38p' | grep -n`, where `grep -n` numbers
relative to the nine-line slice it was handed, not relative to the file. Offset 5 inside the slice
IS file line 34, which is why the two entries showed identical text and it went unnoticed. A
renumbered offset was read as a file line and handed on as verified. **This is #4-B, reusing a
number without re-deriving it, committed by the agent writing the rule that bans it.**

**Parent error 6, a second fabricated check, and the more serious of the two.** Three dispatch
briefs told agents that `hooks/test_block_banned_tokens.sh` enforces the em dash ban and would fail
them. **It does not, and nothing else does either.** That suite covers lint suppressions, three
semantic bans (`ban.empty-catch`, `ban.bare-error`, `ban.non-null`), hardcoded secrets, scope and
allowlist, net-new grandfathering, and bash heredoc pairing. `hooks/scan_edit.py` carries no dash
rule. Verified by searching every tracked file for a dash rule and finding none.

That is **twice in one sprint** the parent has named a check that does not exist: first
`71-release-mechanism-pins.sh:287` enforcing a `CHANGELOG.md:18` pointer, which is a comment block,
now this. Two independent instances of one failure mode is the strongest evidence this sprint has
produced for C4, the class T3 is building right now, and it is worth more than the corpus score.

**CORRECTED. The paragraph that stood here was false, and parent error 7 below is how.** It claimed
the tracked tree contains zero em or en dashes. It does not. Measured properly: **26 live files carry
48 dashes**, plus 22 archived work-docs carrying 1,890 more. Broken down, 14 of the live files are
lawkeeper test-corpus fixtures (deliberately bad code, out of scope), 9 are front-end assets, 2 are
config comments that genuinely break the rule (`.gitignore:12`, `.claude/hooks/ban-allowlist:1`), and
1 is `CHANGELOG.md`, whose 6 are inside quoted historical headings that themselves contained a dash.

**So the counter-example survives, but much weaker than stated.** The markdown this workflow authors
is very close to clean under zero enforcement, which is still worth something. It is not clean, and
the difference between "zero" and "close to zero" is the whole distinction this sprint is about.

**Not this sprint.** Adding a dash checker is a new rule with a new scanner, not a claim check, and
it is outside the Original Ask. Logged here so it is findable, not built.

**One measurement caveat the agent raised and was right about.** Its five-suite green was taken with
two sibling agents' in-flight work already in the worktree, so it is a real result for its own three
files but not a clean measurement of its diff alone. Re-measure once all three waves are in.

### 2026-08-24, Wave 2 part one, and the two worst parent errors so far

**Parent error 7, and it is the one that matters most.** The paragraph above originally claimed the
tree contains zero em or en dashes. That claim came from `/usr/bin/grep -clP '...' file... 2>/dev/null
|| echo "0 in all three"`. **BSD grep does not support `-P`.** It exits with "invalid option",
`2>/dev/null` swallowed the message, and `|| echo` turned the error into a clean report. **A command
that never ran was read as a green, and the green was committed into the document about not doing
that.**

This is the exact rc-and-stderr discipline recorded at `70-invariants-and-new.sh:290-311`, which the
parent quoted to three separate agents in their dispatch briefs during the same hour it was being
violated here. Every dash check in this sprint before this point was false-clean, including the one
that "verified" the fixtures agent's three files. All have been re-measured with a checker that exits
non-zero when it cannot read a file, and they are genuinely clean.

**The lesson is narrower than "be careful" and worth stating as a rule.** A verification command
whose failure mode is indistinguishable from its success output is not a verification. `|| echo
clean` and `2>/dev/null` on a checking command are the specific shape. This belongs in T9's rule text.

**Parent error 8, caught by the T3 agent.** The brief told it the check-id universe is 88, correcting
the work-doc's 23. **88 is the count of distinct `[NN]` tokens in the fragments, not the set of check
ids that exist.** 80 are declared by a `yellow "[NN]"` header; the other 8 are `[70]`, which names a
check family, and `[78a]` through `[78f]`, which label comment blocks. A resolver built from 88 would
let a fabricated `check [78c]` resolve silently, and the agent's second tamper case proves it. **Both
numbers the parent has offered for this universe, 23 and 88, were wrong in different ways, which is
the strongest possible argument for AC6 being a convention rather than a guarantee.**

**A measurement trap worth recording.** `git grep -E` ignores `\b`; `/usr/bin/grep -E` honours it.
The same pattern returns 0 through one and real hits through the other. The agent nearly reported a
correct parent fact as wrong because of it.

### Two live defects found by T3, neither in the corpus

- **`CHANGELOG.md:482` cites `check [50]`. No check `[50]` has ever existed.**
  `50-runtimes-and-companions.sh` declares `[24]`, `[25]`, `[26]` and `[28]`. Someone wrote the
  fragment's filename number where a check id goes. This is the sprint's own defect class, already
  shipped in release history, found by the check built to catch it.
- **`CHANGELOG.md:69` says `check [70]`,** which names a check family rather than a printed check.
  Correct intent, wrong grammar. Needs a reword before the check's grammar can widen to backticked
  references, which would take in-scope claims from 31 to 74.

Both are left unfixed for now and go to the T12 disposition pass, because fixing them by hand is
precisely what decision #7-A ruled out. `[91]` does not currently catch the first one: the
backticked form is outside its shipped grammar, deliberately, since widening before the reword would
red on correct text.

### 2026-08-24, Wave 2 landed, and a clean measurement

`[91]` shipped as `789451d` and `[57]`'s line half as `559a446`. The fixtures landed as `6c9a4d4`
after a split: the first draft came in at exactly 500 lines, which passes the cap with no headroom
in a repo that already has two files stuck at 497. It is now four modules, longest function 32 lines.

**Clean measurement, taken on `6c9a4d4` with an empty worktree**, since all three agents correctly
flagged that their own greens were taken with siblings' work in the tree:

```
validate-dod.sh            ALL CHECKS PASSED
test_ban_tokens.sh         ALL BAN-TOKEN TAMPER TESTS PASSED
lawkeeper test_audit.py    56/56 passed
test_inject_context.sh     29 passed, 0 failed
test_block_banned_tokens   41/41 passed
test_doc_link_lines.py     23/23 passed      (new)
test_claim_fixtures.py     37 passed, 0 failed (new)
corpus score               0 of 4 caught, 0 of 9 wrongly claimed
```

**The score did not move, exactly as #12-B predicted.** Written down before the wave ran so it could
not be reinterpreted afterwards.

**Both new checks found the sprint's own defect class already live in the repo, which the corpus
score cannot show.** `[91]`'s author found `CHANGELOG.md:482` citing a check `[50]` that has never
existed. `[57]`'s author found `57-doc-links.sh:13` claiming the checker handles fenced code blocks,
which it never did, only inline-code spans. **That second one is a comment asserting behaviour its
own code does not have, found by the agent sent to extend that code.** Neither is in the corpus, and
neither would appear in any score. They are the better argument for this sprint than the score is.

**A third fail-open, same shape as parent error 7.** A shell loop lost `git` from its subshell and
every iteration printed UNRESOLVABLE from a command that never ran, which nearly filed twenty
phantom findings. Re-run in Python: **3**, and all three are literal placeholder text
(`name.md:1`, `some/file.md:42`) inside the checkers' own example comments. Not defects.

**Three instances of one failure mode in one session is a pattern, not bad luck.** All three were
shell one-liners whose failure output is indistinguishable from a clean result: `grep -P` on BSD
grep, a subshell without `git`, an unquoted `$s` in a for loop. **The rule T9 writes must name this
shape specifically**: a checking command that can fail silently is not a check, and `2>/dev/null`
plus `|| echo clean` on a verification is the exact anti-pattern.

### Open follow-ups from wave 2, none hand-fixed

- **`scripts/test_doc_link_lines.py` is not in CI.** `.github/workflows/ci.yml` enumerates suites
  explicitly at lines 77, 89 and 96 and does not name it, so nothing runs it. **A test nothing runs
  is the `[0]`-shaped defect this sprint is about.** Goes into W3.
- **16 single check ids across 14 header rows are never verified against the fragment they are
  attributed to.** `[76i]` covers range endpoints only, by construction. All 16 are correct today.
  Blocked on `76-phase-ledger-substrate.sh` being at exactly 500 lines, so the shared parser cannot
  be extracted without a split first.
- **`CHANGELOG.md:482` and `CHANGELOG.md:69`** both go to the T12 disposition pass, not a hand fix.
  Widening `[91]` to backticked references would take in-scope claims from 31 to 74, but cannot land
  until `:69` is reworded, or it reds on correct intent.
- **Six citation paths in `.sh` files that no check resolves** were reported by `[57]`'s author.
  Parent re-measured and gets 3, all placeholders. The disagreement is a resolution-rule difference
  (suffix-tolerant against exact), not a defect. Recorded, not chased.

### Evidence base for T9, gathered as the sprint ran

T9 writes the rule. Decision #8-A said the rule text comes last, shaped around what the checks
actually do rather than around what sounded good in the plan. This is the material, each item an
observed failure in this sprint or the previous one, not a principle someone liked.

**The four named in #4-A to #4-D, all confirmed live:**

- Claiming without proving. Two instances: a validator said to enforce a `CHANGELOG.md:18` pointer
  that is a comment block, and `hooks/test_block_banned_tokens.sh` said to enforce the dash ban,
  which nothing does.
- Reusing a number without re-deriving it. Three instances, all the same universe: "23 check ids"
  (measured `^`-anchored), then "88" (a token count, not a declared set), against a real 82.
- Citations that do not check out. Found in the wild: `CHANGELOG.md:482` cites `check [50]`, which
  has never existed.
- Fixing one site of a family. `Implementation Log` survives at 3 instruction sites
  (`debug-when-stuck.md:19`, `:190`, `README.md:416`) after the filed site was fixed.

**#2-A, re-derive before you write.** The strongest single case is the `check_doc_links.py` fenced
blocks claim: `57-doc-links.sh:13` asserted the checker handles fenced code blocks. It never did,
only inline-code spans. Anyone who read that comment as evidence would have been wrong about the
code they were extending.

**New, and the most useful thing this sprint has produced. A verification that can fail silently is
not a verification.** Four instances in one session, all the parent's:

1. `/usr/bin/grep -P` is unsupported by BSD grep. It exits with "invalid option", and with
   `2>/dev/null || echo clean` the error prints as a pass. **This one reached a commit.**
2. A `while read` subshell that had lost `git` from its PATH. Every iteration reported a false zero
   and nearly filed twenty phantom findings.
3. An unquoted `$s` in a `for` loop turned seven suite invocations into `rc=127`.
4. Reading a `grep` exit code through `| head`, so the code belonged to `head`. Reported by the CI
   agent against its own work, along with the detail that zsh's array is `pipestatus` and is
   1-indexed, so `${PIPESTATUS[0]}` is silently empty.

The shape is one sentence: **if a command's failure output is indistinguishable from its success
output, running it proved nothing.** The tells are `2>/dev/null` on a checking command, a `||`
fallback that prints a clean result, an exit code read through a pipe, and any zero you cannot show
could have been non-zero.

**New, rationale drift, carried over from the previous sprint's signature defect.** A comment giving
one reason for a setting that has since acquired a second dependency. Live example produced BY this
sprint: `ci.yml`'s `fetch-depth: 0` was documented as needed for the release-tag read, and is now
also needed by the fixture suite, which resolves blobs 20 commits back. A reader trusting the comment
could trim the checkout and break a suite for a reason the comment gave them no way to see.

**New, from T4b. A pre-derived fact has a shelf life, and it is shorter than a session.** The
brief for T4b said the validator sets `set -uo pipefail` at `scripts/validate-dod.sh:65`. The agent
came back with `:77` and was right. Checked against history: it was 65 at the sprint base `2ccb728`,
68 five commits later, 77 now, all inside one session, because concurrent waves kept growing the
file above it. **The fact was true when derived and decayed while it sat in the brief.** That is a
different failure from getting it wrong, and it needs a different answer: the count claims this
sprint bans are stale-by-neglect, while this one went stale under active concurrent editing in
hours. It is the argument for citing a fact by something stable, an anchor or a symbol, rather than
by a line number, wherever the citation has to survive longer than one wave.

**New, from T4b. A search whose method cannot see the defect class returns a clean result that means
nothing.** The candidate list handed to T4b was built by finding validator checks that print a green
interpolating a counted variable. `55-mirror-completeness.sh` was not on it. Its pass line carries no
number at all, which is precisely why the sweep could not see it, and it turned out to hold the worse
fail-open of the two the agent fixed. **The detector was blind to exactly the shape it was hunting:
a check that greens over a set it never read.** The parent repeated the same error minutes later
while verifying the agent's `[40]` claim, reaching for a collapse that dropped the `:(top)` anchor.
That widens the scope from 233 files to 235 rather than emptying it, so the first reproduction came
back not-reproduced from a test of the wrong hypothesis. The real collapse, an exclude-everything
pathspec, gives `rc 1`, empty stdout and empty stderr, which is the exact triple the scan reads as a
clean tree, confirmed against a literal that genuinely exists in the repo.

The one sentence for the rule: **a clean result is only as good as the method's ability to have
returned a dirty one.** Before trusting a zero, show the search finding a planted instance of what it
claims is absent. Both halves of this sprint's tooling already do it, and both times it was added
after a zero had already fooled someone.

**What the rule must NOT claim.** The corpus is the evidence for this. Of thirteen real findings,
nine are reachable by no check at all: a timing property, two policy sentences disagreeing, a
completeness gap in a release note, a scanner's own line-based blind spot. **A rule that implies the
checks make claim drift impossible would itself be the defect it bans.** AC6 already demotes the
command-per-fact convention from a guarantee to an aid, on the evidence that this sprint's own brief
attached a command to a fact and the command was the thing that was wrong.

### Evidence base for the speed half of the ask, which the ACs had dropped

The original ask has four parts and the eight ACs covered three. "the skill should focus of the
speed of the development of the waves" was answered in the wizard as #3-A, #3-B and #3-C, all three
chosen, and then recorded nowhere but a one-line gloss. Caught before T9 was dispatched, which is
the last point where it was still cheap: a rule written from the material above would have shipped
half an answer.

**The lever, #3-A, prebuilt verified facts in the dispatch brief.** Every agent this sprint was
handed the file:line facts it would otherwise have gone looking for. What that bought is visible in
what the agents spent their turns on. T5 reproduced the `{{test_file_path}}` case and redesigned the
check around what it found, instead of re-deriving how the mirror script works. T3 went after the
check-id universe and found the parent's 88 was a token count. The CI agent verified that `[93]` is
declared at `93-token-declarations.sh:92` rather than taking the parent's word for it. None of them
paid for orientation first.

**The cost, and it is not small.** Three of this sprint's wrong facts were *in* those briefs. A
pre-derived fact is a speed lever with a correctness liability attached: the same brief that saves
five agents an hour of orientation is also the fastest way to make all five of them wrong at once.
The worst instance is the Repo Brief's own count claim, where the recorded command contained `...`
inside a `grep -E` alternation, so the command matched any three characters and counted something
other than what the sentence said.

**The mitigation that actually worked, and it is shippable.** The dispatch brief carried, verbatim:
*"If one of my pre-derived facts is wrong, say so plainly and show the command that proves it."*
Agents used it. W1b traced the phantom "line 5" back to the parent's own `sed | grep -n` pipe rather
than reporting the number it was given. T5 refused the framing of its own task. T3 replaced the
universe count. Every one of those corrections came back with a command attached, because the
sentence asked for one. **The pairing is the mechanism: hand the agent facts so it can skip
orientation, and hand it standing permission to contradict them so a wrong fact dies in one wave
instead of propagating through five.** Neither half works alone. Facts without the invitation is
just faster wrongness.

**What is NOT measured, said plainly.** There is no before/after wave-time number here and no
counterfactual wave that ran without a brief. The claim defended above is about what agents spent
their turns on, which is observable in their reports. A speed *number* is not, and inventing one
would break this sprint's own rule.

### 2026-08-24, Wave 3, the first catch and a declined task

**`[93]` is the first check in this sprint that catches a finding from the frozen answer key.** M3
replays from its pinned blob and reds at the right file, line and token. Landed as `e9c461a`.

**My brief was wrong about M3 in a way that changed the design, and the agent caught it.** I
described the token as used in the prompt body while declared in no INPUTS list, which implies it sat
outside that section. **It sits inside it**, at line 55 against an INPUTS anchor at 37, on a
continuation line as an example for a different input. So any window over the INPUTS section, at any
width, answers "the token is in there" and misses the finding. Declaration had to become structural:
the token heads a numbered item on its own line. Both halves are pinned as tests, including one
asserting that a window rule reads the fixture as clean. Reproduced independently before accepting it.

**CI now runs the suites this sprint adds** (`8f26cb4`), which nothing did before. The same wave
extended `ci.yml`'s `fetch-depth: 0` rationale, which documented one reason and had silently
acquired a second: the fixture suite resolves blobs behind HEAD and reds environmentally on a shallow
clone. A reader trusting that comment could have trimmed the checkout and broken a suite, with
neither failure naming the setting. **The sprint produced that defect itself and caught it in the
same wave.**

### T4 declined, and #14-A replaces it

The agent refused to build C1 and gave an argument that survives checking. Under the guardrail that
nothing sourced from a repo file is executed, an annotation can carry exactly four things, and three
are closed. A command is banned. A pattern that becomes a regex is banned. A literal counted with
`grep -F` is safe but nearly empty. A name selecting a measurement hardcoded in the fragment is safe,
**but then the fragment already holds the measurement, and the annotation is only a second place to
keep in sync.**

**I tested the weakest link rather than relaying it.** Of 774 count claims in live markdown, shell and
Python, almost none are of the form "this exact phrase appears N times"; they count files, rows and
line spans. So the safe slice really is near-empty.

**Two supporting arguments, both empirical.** First, the writer who miscounts writes the annotation
from the same wrong idea, and this sprint has three instances: "23 check ids" (`^`-anchored command),
"88" (a token count, not a declared set), and the `~530` count-claim figure at line 174 of this doc,
**whose recorded command contains `...`, which in that position matches any three characters rather
than marking an elision, so the command counts something other than what the sentence says.** Third
strike for AC6 in one sprint: attaching a command proves reproducibility, never correctness.

Second, C1 was to be diff-scoped, so it would fire only when someone edits the line. **A count goes
stale precisely when the line is left alone and the tree moves underneath it**, so a diff-scoped
check watches the one moment the number is most likely to be right.

**#14-A takes the alternative:** floors in the checking code, which is what the repo already does and
what works. Same goal, mechanism that survives the guardrail.

**The agent also caught a stale count of its own** and fixed it by deleting the number rather than
updating it, since the live totals print on every run. That is the right instinct and belongs in T9.

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
