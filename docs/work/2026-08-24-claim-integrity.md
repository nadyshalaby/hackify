---
slug: claim-integrity
title: Code is the only source of truth, and a check that enforces it
status: implementing
type: feature
created: 2026-08-24
project: hackify
current_task: T24b and T27, both folded in at the user's call, then verify, review, finish
worktree: none
branch: main
sprint_goal: Make a doc's claim about code mechanically falsifiable, so a claim that stops being true turns red at the next commit instead of at round five of a review loop.
related: 2026-08-23-wave-implementer-migration.md
---

## 0. Phase ledger

- [x] Phase 1. Clarify (answers locked by wizard, anchor recorded below)
- [x] Phase 2. Plan + GATE (signed off 2026-08-24)
- [x] Phase 2.5. Spec review (7 Criticals, plan revised)
- [>] Phase 3. Implement (reopened for T24b and T27)
- [ ] Phase 4. Verify (re-run once T24b and T27 land)
- [ ] Phase 5. Review (round 3 over the T24b and T27 surface)
- [ ] Phase 6a. Re-verify + land
- [ ] Phase 6b. Cleanup sweep
- [ ] Phase 6c. Archive to done/
- [ ] Phase 6d. Summary + report

This runtime exposes no todo-tracker tool, so this section is the durable ledger and it is re-printed
in chat at every phase boundary.

**This block went stale and the user caught it, not a check.** It read `Phase 3 <- in progress` while
the work had already been through Verify and the full review panel. Nothing in the repo noticed,
because no check compares this block against the frontmatter `status:` two dozen lines above it, and
the two disagreed for the length of two phases. A sprint whose whole subject is a document claiming
something the code does not back shipped exactly that defect in its own work-doc. Recorded here
rather than quietly corrected, and carried into the Retrospective as a hackify gap with a proposed
check, since the same block exists in every work-doc the workflow has ever produced.

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

- [x] **AC1** T1a freezes a per-finding label table for the 13 round-5 findings BEFORE any check is
      built: bucket, citation into the archived work-doc, the class that reaches it, and the scan
      scope required. **Frozen and committed alone at `803ef51`. The derived reachable set is 4 of
      13**, 3 at freeze plus M4 under #13-A, **not the 5-6 the parent quoted.** Grading runs three
      legs per #11-A: (a) the check hits **100% of the buildable set, 3 of 3**, each replayed
      against **its own pinned fixture** in `scripts/claim_fixtures.json`, **and M4's miss is
      measured rather than assumed**, the C7 check runs on M4's pinned evidence and its clean pass
      line is recorded as the evidence that it looked;
      (b) it claims **none** of the 9 out-of-class findings, the leg that cannot be tuned because
      nothing about it rewards the check for firing; (c) tamper proves every branch reds on its own
      message. **Legs (a) and (c) both have to pass. Leg (b) passing alone proves only that the
      check is quiet, which an empty file also achieves.**
- [x] **AC1b** The label table is committed alone, before W2 opens, and any later change to a bucket
      needs a work-doc entry naming which finding moved and why. **No tuning the answer key to fit
      the check.** Committed alone at `803ef51`, before any check existed.
      **AC1 leg (a) restated on 2026-08-25, and this is not a bucket change.** Two clauses in it
      had become false. It said the reachable set replays at `03e7a12` "where all four sites were
      live", which the answer key itself contradicts: M4's own `replay_note` says it is not live at
      `03e7a12` and replays from `7b641e0~1`, M3 needs a historical blob, and I4 is pinned at
      `21ccc8d`. The key already concluded "fixtures are therefore per-finding, not one global
      base", so the AC was quoting a base its own data had ruled out. It also said **100% of the
      reachable set**, which after #15-A accepted the build refusal for M4 could not be met, since
      `must_catch` stays 4 while `must_catch_buildable` is 3.
      **Why this is a different act from moving a bucket.** AC1b bans editing the answer key so an
      unchanged check scores better. Nothing in `scripts/claim_corpus.json` moved: M4 is still
      `must_catch`, `counts.must_catch` is still 4, and the scorer still validates against 4. What
      changed is a sentence in the plan that had gone factually wrong, brought into line with a
      decision **the user had already taken** in #15-A. To keep the restatement from being a plain
      relaxation it carries a clause the original did not have: M4's miss must be **measured**, the
      check actually run against M4's pinned evidence and its clean output recorded. Asserting the
      miss is no longer allowed to count.

      **AC1 leg (b) restated on 2026-08-25. Also not a bucket change, and this one was worse than
      leg (a): it was never a measurement at all.** Leg (b) said the check claims **none** of the 9
      out-of-class findings, and called that the leg that cannot be tuned. It cannot be tuned
      because it cannot fail. Read the answer key's own `reaching_class` column: I1, I3, I5, I6, M1
      and M2 reach `none`, and M5, M6 and M7 reach `C1_annotated_count`, which decision #14-A
      declined to build. **No shipped check looks at any of the nine.** Their silence is a
      structural certainty of the class mapping, not evidence about the checks, and the `0 of 9` the
      scorer printed was the same empty-set default T6 just removed from the grader, still alive in
      the plan text one section above it.

      **Re-pointed at evidence that can actually go red.** Precision is measured by
      `test_the_live_tree_comes_back_clean`, which exists in all three of
      `scripts/test_token_declarations.py`, `scripts/test_section_exists.py` and
      `scripts/test_literal_absent_claims.py`. Each runs its own shipped check over the **whole live
      tree** and asserts rc 0 plus the pass line. Each has a floor companion so a scan that read
      nothing cannot pass as a scan that found nothing: [93] asserts at least 350 uses over 15
      prompts in 15 files. **The [95] half of this sentence was overstated and is corrected here,
      2026-08-25, from Reviewer F.** [95] does floor its file count at 100 and its claim count at 5,
      but it floors nothing on the PAIRING step, and the live tree forms zero pairs. So [95]'s clean
      live run says its scan read a real corpus and found 15 claims; it does NOT say the pairer
      still works, because nothing on the live path would notice if it stopped. That the pairer
      works is proven elsewhere, by `test_i4_is_caught_with_its_counter_evidence_named` and by the
      replay catching I4, both against pinned fixtures rather than the live tree. Leg (b)'s evidence
      is therefore [93] and [94] at full strength and [95] at reduced strength, and the missing
      live-path floor is recorded as a follow-up rather than papered over. That is a
      false-positive measurement over the entire repository rather than over nine rows, and a check
      that fired spuriously anywhere would redden its own test.

      **Why this is not tuning.** Nothing in `scripts/claim_corpus.json` moved. `counts.must_catch`
      is still 4 and `counts.out_of_class` is still 9. No bucket changed. What changed is a sentence
      in the plan that described a measurement nobody had taken.

      **AC1 stays a three-leg criterion, with (b) re-pointed, not a two-leg one.** Legs (a) and (c)
      still both have to pass. Leg (b) is now able to fail, which is the only reason to keep it.

      **Bucket change 1 of 1, M4, `out_of_class`/`scope_blocked` to `must_catch` under C7.** Cause:
      #13-A widened C7 to both polarities. **Corrected 2026-08-25, found by Reviewer B.** This read "the check widened first and the
      bucket followed, which is the allowed direction". **No check widened.** The DECISION widened
      the class, the bucket followed the decision, and the build was then refused:
      `95-literal-absent-claims.sh:46` says "THE PRESENT-POLARITY HALF IS NOT BUILT" and gives its
      reason, and #15-A accepted that refusal. The direction is still the allowed one, a bucket
      following a widened class rather than a bucket moved so an unchanged check scores better, and
      the answer key has carried the gap all along in `must_catch_buildable: 3` against
      `must_catch_refused: 1`. But the sentence justifying this sprint's only bucket change
      described a build that never happened, and it was sitting inside the clause whose whole job is
      policing bucket changes.
- [x] **AC1b, entry 2 of 2. Decision #15-A, a bucket change considered and REFUSED.** The user
      accepted W4's refusal to build a check for M4 and dropped the build target from 4 to 3.
      **The bucket was NOT moved.** Moving M4 to `out_of_class` would turn a 3 of 4 into a 3 of 3
      by editing the answer key, which is the direction AC1b exists to forbid, and the fact that a
      user authorised the target change does not convert an unchanged check into a better one. The
      target drop is recorded instead as `counts.must_catch_buildable = 3` and
      `counts.must_catch_refused = 1`, with the refusal and its measurements on the M4 finding
      itself. `counts.must_catch` stays 4, which is the number the scorer validates against the
      findings, so the headline can never read as a clean sweep. **Raised with the user as a
      conflict between #15-A and AC1b rather than resolved silently.**
- [x] **AC2** Every live `check [NN]` reference resolves against an id universe **derived at
      runtime** from the ok/fail label form. No literal count appears in the check or this AC. (The plan's
      original "23" was measured with a `^`-anchored command, and the "88" that replaced it counted
      every `[NN]` token rather than the declared ones. The declared universe is NOT written here: this AC asserted 82 while [91] derives 86 at HEAD, which is the very defect the AC is about. Check
      `[91]` derives at runtime and this AC deliberately does not hardcode. Corrected here because
      an AC asserting a wrong count in a sprint about wrong counts is the defect on display.)
- [x] **AC3, ticked against the RE-POINTED criterion, not the one as written.** Clause (a) named a verb vocabulary that does not exist, because it was written for the annotation design #14-A declined; T7 refused to invent one and re-pointed the battery at the data paths that do exist, writing up what is therefore NOT proven under its dated heading. Original text: The check never executes anything sourced from a repo file, proven on **both** halves:
      (a) the verb vocabulary is a fixed enum, shown in code; (b) every argument is constrained, a
      path must resolve inside the repo and be git-tracked, a pattern is matched literally with `-F`
      and never `-E`, and no argument ever becomes a shell word. T7 feeds hostile annotations
      (traversal, glob, `$(...)`, backtick, a ReDoS pattern) and proves each is **rejected**, not run.
- [x] **AC4** Every check branch is tamper-tested fail-closed, and each row asserts the expected
      **failure message**, not merely a non-zero exit, so a branch's own red cannot be confused with
      a wiring red.
- [x] **AC5** An always-on rule ships, wired into `hooks/hooks.json`, with every load-bearing law in
      a bold lead. It carries **#2-A (re-derive before you write)** as well as #4-A to #4-D, plus the
      written procedure for the semantic class no check reaches.
- [x] **AC6** The Repo Brief template carries the command behind every fact, **as a convention that
      aids a reader in re-deriving it. It is explicitly NOT a correctness guarantee**: this sprint's
      own brief attached a command to the "23 check ids" fact and the command was the thing that was
      wrong. The same edit amends `references/repo-brief.md:13`'s ~200-word cap, which this brief
      already breaks at 342 words.
- [x] **AC7** **Every item** in the previous sprint's backlog section gets one written disposition:
      caught, missed, or out of class. No count is asserted. Scope is stated: a one-shot scan with
      the `docs/work/` exclusion lifted, results recorded, **never wired into the validator**, since
      that tree holds 619 citations against 30 live ones and is a frozen record.
- [x] **AC9** The shipped rule answers the **speed half** of the ask, not only the claim-integrity
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
- [x] **AC8** Full triad green, `dist/` current by two-sync checksum, no file over 500 lines. Note
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

**Every fact below carries the command that produced it. Re-measured at `4329335`, version 0.15.1,
when Phase 3 reopened for T14-T17; the counts below moved during this sprint and the stale copy was
refreshed rather than left for four agents to inherit. This block is the sprint's own first
demonstration of AC6.**

- **Stack.** Claude Code plugin. Markdown skills, Python 3 helpers, Bash validators. No package
  manager, no build step. `ls .claude-plugin/`
- **Triad.** `bash scripts/validate-dod.sh`. Unit suites: `bash scripts/test_ban_tokens.sh` (157
  passed), `python3 skills/lawkeeper/scripts/test_audit.py` (56/56), `bash
  hooks/test_inject_context.sh` (29 passed), `bash hooks/test_block_banned_tokens.sh` (41/41).
- **Validator fragments: 28**, sourced in order from a hand-maintained list.
  `ls scripts/validate-dod.d/ | wc -l`. The validator runs `set -uo pipefail`, NOT `set -e`.
  Next free number is `98-` (`97-test-suites-reachable.sh` is the last). A new fragment needs BOTH
  its `source` line and a header row in `validate-dod.sh`; `[76f]` guards that header enumeration.
- **Always-on rules: 5 wired**, of 8 files in `rules/`.
- **Work-docs: 20 tracked, only 2 carry a `## 0. Phase ledger` block**, because the ledger shipped
  2026-08-23. `git ls-files 'docs/work/*.md' 'docs/work/done/*.md' | xargs grep -l '^## 0\. Phase ledger' | wc -l`
- **Status vocabulary is declared once**, at `skills/hackify/references/work-doc-template.md:223`,
  eight values on one table row. Nothing pins it today, so 19 docs say `done` and one said `review`,
  which is not on the list. ← `grep -h '^status:' $(git ls-files 'docs/work/*.md' 'docs/work/done/*.md') | sort | uniq -c`
  `python3 -c "import json;print(len(json.load(open('hooks/hooks.json'))['hooks']['UserPromptSubmit'][0]['hooks']))"`
  After turn 1 only each bullet's **bold lead plus a short following clause** survives into the
  digest, so every load-bearing law must live in its lead (`rules/phase-discipline.md`).
- **Markdown surface: 120 live files** (excluding `docs/work/`).
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
  are both at 497/500.** **Stale at HEAD, corrected 2026-08-25 from Reviewer B.** #17-B split `71-release-mechanism-pins.sh`, which is 344 lines now; `15-wi-absent-cases.sh` is still 497 and still needs its split. Anything landing there needs a split plan, not an edit.

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

- [x] **T1a** Freeze the label table: 13 findings, bucket, archived-doc citation, reaching class,
      required scan scope. Note that four were REFUTED (I4, I6, M5, M6), three on scope and one on
      fact, so "verified" is the wrong word for the corpus as a whole. Commit alone.
      **Closed at `803ef51`.**
- [x] **T1b** Fixtures plus the scoring runner, built from T1a's frozen table. **Runner built
      (`scripts/score_claim_corpus.py`). Fixtures NOT built: the dispatch brief omitted that half.
      Parent error, recorded here rather than folded quietly into a later task.** Under #11-A the
      fixtures are what make leg (a) gradeable, so they land in W1b, before T6.
      **Both halves closed: runner at `47e3a01`, fixtures at `6c9a4d4`.** The parent error above is
      kept rather than deleted; a task record that erases how it went wrong teaches nothing. The
      `03e7a12` wording is dropped for the reason under AC1: no commit has all four sites live.
- [x] **T2** C2 citations: **extend `scripts/check_doc_links.py` (198 lines) and check `[57]`**,
      which already resolve cited paths and already handle fenced blocks, inline code and the
      `docs/work/` exclusion. C2 adds only the `:N` line-count half. Handle the hard-wrapped-path
      case (M2's shape) that a naive regex splits. **Closed at `559a446`.**
- [x] **T3** C4 check-exists, in new `scripts/validate-dod.d/91-claim-resolvers.sh`, **wired into the
      sourced list in the same commit**. Name the reference grammar and its exclusions first: bare
      `[NN]` yields 136 hits in live markdown and collides with markdown reference-link syntax.
      **Closed at `789451d`.**
- [x] **T4** C1 annotated counts. **DECLINED, nothing built. Superseded by T4b under #14-A.**
      The class cannot be built under this sprint's own guardrail: an annotation may carry a command
      (banned), a pattern that becomes a regex (banned), a literal counted with `grep -F` (safe but
      near-empty, since real count claims count files, rows and line spans rather than occurrences of
      one string), or a name selecting a measurement hardcoded in the fragment (safe, but then the
      fragment already holds the measurement and the annotation is a second place to keep in sync).
- [x] **T4b** **Floors in the checking code** for the quantities that matter, the working form of
      the same idea. The repo already does this at `20-templates.sh:4` (`check_line_range`) and in
      the `_FLOOR=` idiom in `[76]`, `[91]` and `[93]`. Pick the quantities other things actually
      depend on; a floor on a number nobody reads is ceremony. **Closed at `a8b376b` and
      `21ccc8d`.** The floor that mattered most was invisible to the parent's candidate list.
- [x] **T5** C3 declared vs used: every `{{token}}` in an agent prompt appears in its INPUTS list.
      **Closed at `e9c461a` as check `[93]`.**
- [x] **T5b** **C5 retired vocabulary** (#9-B). Machinery already exists as `WI_DEAD_WORDS` in
      `70-invariants-and-new.sh`; it is unfed for this class. Feed it, with an allowlist, because six
      sites keep `Implementation Log` deliberately as back-compat. **Closed at `21ccc8d`** as
      `WI_DEAD_INPUTS` beside `WI_DEAD_WORDS`, both in `73-implementer-rename.sh` after the split,
      each sized by `check_list_size` so a silently emptied list reds instead of passing over nothing.
- [x] **T5c** **C6 section-name exists** (#9-B): a doc instructing a writer to use a named work-doc
      section must name one the template actually has. **Closed at `21ccc8d` as check `[94]`.**
- [x] **T5d** **C7 literal-absent claims** (#9-B), **both polarities per #13-A**: a sentence
      claiming a phrase is absent, unpinned or not present where it is in fact present, AND one
      claiming a phrase is present where it is in fact absent. Reaches I4 and M4. **I4's claim and
      its quoted literal sit on one physical line at `803ef51`, and M2 in this same corpus is the
      finding proving line-based matching goes blind the moment text wraps. Match a normalised
      paragraph, not a raw line.**
      **Closed at `21ccc8d` as check `[95]`, I4 re-pinned at `8ad1e0f`.**
- [x] **T6** Score **once** against the frozen table. Record the score and every miss. **No tuning
      until it passes**; a bucket may move only with a work-doc entry saying which and why.
      **Closed at `6f8be4c`. Scored 3 of 4, measured. No bucket moved and no tuning was done.**
- [x] **T7** Tamper: delete each branch, prove each reds **with its own expected message**. Plus the
      hostile-argument battery from AC3.
- [x] **T9** Write `rules/claim-integrity.md`: laws in bold leads, **#2-A** plus #4-A to #4-D, and
      the procedure for semantic rationale drift that no check reaches.
- [x] **T10** Wire it as the 5th `UserPromptSubmit` hook; extend `hooks/test_inject_context.sh`.
- [x] **T11** `references/repo-brief.md`: a command per fact, and amend the ~200-word cap in the same
      edit so the template stops contradicting itself.
- [x] **T12** Run the widened check over every item in the previous sprint's backlog section; one
      disposition each.
- [x] **T13** CHANGELOG bullet, version bump, dist regeneration.
- [x] **T14**, ledger persistence in the skill: every phase-open and phase-exit instruction must say the block is WRITTEN to the work-doc and frontmatter `status`/`current_task` advanced in the same edit, before the chat re-print. Model the wording on `phase-3-implement.md:103`, which already does this for waves. Fix `phase-ledger.md:24`'s "additionally" so the durable copy is the obligation, not an aside. Files: `skills/hackify/references/phase-ledger.md`, `skills/hackify/references/phases/phase-1-clarify.md`, `phase-2.5-spec-review.md`, `phase-3-implement.md`, `phase-4-verify.md`, `phase-5-review.md`, `phase-6-finish.md`, `skills/hackify/SKILL.md`. → verify: `bash scripts/validate-dod.sh` rc 0, and every phase file names the disk write.
- [x] **T15**, the two live defects, done by hand by the parent: this doc's stale ledger marks, and the archived `2026-08-23-phase-ledger-substrate.md` whose ledger reads Phase 5 in progress under `status: done`. → verify: the new check greens on both.
- [x] **T16**, new fragment `98-work-doc-ledger-sync.sh` plus its `source` line and header row in `validate-dod.sh`. Three assertions: (a) every work-doc's `status:` is one of the values READ OUT of `work-doc-template.md:223`, never a hardcoded list; (b) a doc under `done/` has zero `- [ ]` and zero `- [>]` inside its `## 0. Phase ledger` block; (c) a doc outside `done/` does not say `status: done`. Floors on all three subject counts, 20 docs, 8 vocabulary values and 1 archived ledger block today (2 docs carry a section 0, but only one of them is under `done/`, and the archived subset is what assertion (b) judges), and a positive control built from source literals the way `[95]:232` does. Terminate the block at the next `^## ` of any name, never `^## 1.`, because the groom path inserts `## Groom Provenance` there. Files: `scripts/validate-dod.d/98-work-doc-ledger-sync.sh`, `scripts/validate-dod.sh`. → verify: fragment reds on both live defects before T15 fixes them.
- [x] **T17**, tamper rows for `[98]` in the shipped suites, proving each assertion and the control can go red. Files: `scripts/test_tamper_fragments.py` or a new per-check suite, wired so `test_tamper_battery.py` reaches it. → verify: the suite reds when the fragment is blinded.
- [x] **T18**, close the archive window (wizard 3-A). Step F (update log + `<slug>.report.html` written straight to its `done/` path) runs BEFORE the move; one final edit closes Phase 6c and 6d together and sets `status: done`; the `git mv` is the last mechanical step, so the doc never exists under `done/` carrying an open row. Files: `skills/hackify/references/phase-ledger.md`, `skills/hackify/references/phases/phase-6-finish.md`, `skills/hackify/references/finish.md`, `skills/hackify/references/work-doc-template.md`, `skills/hackify/SKILL.md`. → verify: `grep -n 'Step F' skills/hackify/references/phases/phase-6-finish.md` shows the move last, and `bash scripts/validate-dod.sh` rc 0. **Landed `fda44f1`.**
- [x] **T19**, declare `paused` (Reviewer F, Critical 1). `finish.md:100` is the only writer of a ninth status value and the template declares eight, so `[98]` reds on any doc that took Option 3. Add `paused` to `work-doc-template.md:223` and to the frontmatter reference prose. Files: `skills/hackify/references/work-doc-template.md`. → verify: `[98]` parses 9 values and a `status: paused` doc outside `done/` passes. **Landed `fda44f1`.**
- [x] **T20**, discovery and read hardening (Reviewer A, Critical 1 + Important 2 + Minor 1). `git ls-files` without `-z` C-quotes any path with a non-ASCII byte, a quote or a backslash, so `.endswith('.md')` drops it and the doc leaves the corpus unseen; switch to `-z` and split on NUL. Confine every read to the repo root by real path and refuse a symlink rather than following it. Parse `status:` only at column 0 inside the frontmatter fence, so an indented line inside a `sprint_goal: |` block scalar cannot supply the value. Files: `scripts/validate-dod.d/98-work-doc-ledger-sync.sh`. → verify: a doc named with a non-ASCII byte is judged, and a symlinked work-doc is reported rather than read. **Landed `306c0ee`.**
- [x] **T21**, ledger-block boundary (Reviewer A, Critical 2). `ledger_start` takes the first literal match anywhere, so a fenced code block quoting the heading shadows the real ledger, and a `## ` inside a fenced block ends the block early. Track fence state so both the heading search and the terminator ignore fenced content, and count a doc toward `WL_ARCHIVED` only when its judged block is the real one, so the floor cannot be satisfied by a doc that was never judged. Files: `scripts/validate-dod.d/98-work-doc-ledger-sync.sh`. → verify: a doc with a fenced decoy above its real ledger is still judged on the real one. **Landed `306c0ee`.**
- [x] **T22**, control coverage (Reviewer A, Important 1). `control_docs` exercises `OPEN_ROWS[1]` only, so the `- [ ]` half of assertion (b) has no control at all. Add the missing case and a fenced-decoy case. Files: `scripts/validate-dod.d/98-work-doc-ledger-sync.sh`. → verify: blinding either open-row marker fails the control. **Landed `306c0ee`.**
- [x] **T23**, the two false claims in the check's own header (Reviewer B, both Criticals; Reviewer F, Important). `:43` cites `phase-ledger.md:43` for the groom insertion; that file never mentions `## Groom Provenance` at any line, so the citation supports nothing and `[57]` stayed green because it only proves the line exists. Cite `skills/groom/SKILL.md:59` and `work-doc-template.md:42`, the two sites that do declare it. `:108` claims "every doc created since 2026-08-23 carries a ledger" as the reason the ledger floor needs no headroom; `2026-08-23-wave-implementer-migration.md` disproves it, and the true count is 1 of 19. Files: `scripts/validate-dod.d/98-work-doc-ledger-sync.sh`. → verify: every citation in the header resolves to text that supports the clause citing it. **Landed `306c0ee`.**
- [x] **T24 (first half)**, close the delete-to-green path (Reviewer B, Important 1a). An archived doc with no section 0 is a non-subject, so deleting the block is a valid way to turn a red green, which `phase-ledger.md:140` bans outright. Require a ledger in any doc whose frontmatter `created:` is on or after the date the ledger shipped, and record the half that stays out of reach (a `- [x]` cannot be told apart from a phase that was dropped) as a written limitation instead of an implied guarantee. Files: `scripts/validate-dod.d/98-work-doc-ledger-sync.sh`. → verify: deleting section 0 from a doc created after the pin date reds.
- [ ] **T24b**, close the delete-to-green path for real (Reviewer B, Important 1a; user call 6-A). Four parts, one wave. (i) Reconcile `docs/work/done/2026-08-23-wave-implementer-migration.md` with a section 0 ledger built from the evidence already inside that file, never invented: it carries a filled `## 8. Retrospective`, a `## Phase 6, close-out` record and a second `## Retrospective`, but no `## Update log` and no emitted report, so its last row is the same shape as the other archived sprint's. (ii) Apply the created-date subject rule, so an archived doc created on or after the day the ledger shipped must carry a section 0, which closes the path where deleting the block turns a red green. (iii) Split `[98]`, because the rule takes the fragment to about 518 lines against the 500 cap; the split follows the precedent set when three other near-cap fragments were split, and needs both a `source` line and a header row in `scripts/validate-dod.sh`. (iv) Tamper rows for the new rule, which also forces a split of `scripts/test_tamper_ledger_sync.py` at 499 lines. Files: `docs/work/done/2026-08-23-wave-implementer-migration.md`, `scripts/validate-dod.d/98-work-doc-ledger-sync.sh`, a new fragment, `scripts/validate-dod.sh`, `scripts/test_tamper_ledger_sync.py`, a new suite, `scripts/test_tamper_battery.py`, `scripts/tamper_harness.py`. → verify: deleting section 0 from a doc created after the pin date reds, every file under 500 lines, battery total rises.
- [ ] **T27**, publish the Phase 6 report as a shareable artifact (user call 7-A). The rendered HTML stays exactly as it is and becomes the artifact's source; publishing it hands the user a link instead of a path they have to open by hand. This is a native-tier enhancement in the sense `runtime-adapters.md` already defines, so it gets a row in both enhancement tables with an honest per-runtime column and a written degrade path: where a runtime cannot publish, the file on disk is the deliverable and Step F is unchanged. No phase may hard-require it. Files: `skills/hackify/references/runtime-adapters.md`, `skills/hackify/references/html-report.md`, `skills/hackify/references/phases/phase-6-finish.md`, `skills/hackify/references/finish.md`, `skills/hackify/references/phase-ledger.md`, `skills/hackify/SKILL.md`, `skills/quick/SKILL.md`, `skills/yolo/SKILL.md`. → verify: `bash scripts/validate-dod.sh` rc 0, and no phase file states the report step as impossible without the artifact primitive.
- [x] **T25**, tamper rows for everything T20-T24 adds, plus the over-width line at `test_tamper_battery.py:69`. Files: `scripts/test_tamper_ledger_sync.py`, `scripts/test_tamper_battery.py`. → verify: `python3 scripts/test_tamper_battery.py` passes and the new rows red when their guard is blinded. **Landed `27e5e51`**: battery 89 to 98, and each of the five guards fails its rows when reverted.
- [x] **T26**, CHANGELOG (Reviewer B, Important 3). `0.15.1` is unreleased and its `### Added` names six checks but not `[98]`, and nothing records T14's mandatory ledger-persistence rule. Both are user-visible. Files: `CHANGELOG.md`. → verify: `[98]` and the ledger-persistence rule both appear under the unreleased version. **Landed `fda44f1`.**

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

### 2026-08-25, waves 4 to 6, the classes land and four decisions come back

**W4 built the last three classes.** `[94]` section-exists catches I2, `[95]` literal-absent catches
I4, and `[40]` gained a retired-input list. M4 was refused rather than built, and the refusal held up:
the release note names no path, only "the two mode skills", so any check needs a hand-written
English-to-path map, and the literal it would look for is present in 12 files at the replay commit
while the defect is two specific absences. Recorded under decision #15-A.

**T4b added three floors** under decision #14-A, and the one that matters was not on the candidate
list the parent supplied. `55-mirror-completeness.sh` prints a pass line carrying no number, so a
sweep for "greens interpolating a count" could not see it, and it held the worse fail-open of the
two: two `git ls-files` calls whose stderr goes to `/dev/null` and whose status nothing reads, feeding
a `comm -23` that reports every file mirrored when the left side is empty. Six candidates were
rejected in writing for counting fixed enumerated sets.

**Decisions #16-C and #18-C fixed what #7-A had frozen.** Four instruction sites now use the live
vocabulary and both known-findings lists retire with them. `[94]`'s retirement was forced rather than
chosen: with the sites fixed and the list still present it reddened three times saying its own entries
matched nowhere, which is the self-retirement the list was designed to force.

**Decision #17-B split three fragments off the cap.** 500, 497 and 480 became a largest-fragment 404.
The proof kept is the check-id census, 84 before and 84 after with both sets non-empty, because a
split that silently drops a check is the failure mode and no size table shows it.

**Five wrong parent facts caught by agents in one day**, which is the mechanism from AC9 working
rather than a run of bad luck: a line number that had drifted 65 to 77 inside the session; `README.md`
at 449 not 450, traced to a stale saved note; three block-opening line numbers off by one; an ok-line
baseline of 1445 quoted as 1440; and the safety premise recorded in full above. Every one came back
with the command that proved it, because the brief asked for one.

**And one the parent caught on itself.** Verifying the census, the first attempt anchored on `^\[` and
returned 0 ids before and 0 after, then printed IDENTICAL. The validator colours its headers, so the
anchor never matched past the escape sequence. **Two empty sets comparing equal is the same green as
a scan that read nothing**, and it was one line away from being reported as proof.

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

**New, from T15, and the sharpest shape the sprint has produced. A reassurance that is true of the
set and false of the member is worse than no reassurance, because it is what authorises the risky
act.** Decisions #16-C and #18-C asked for two live defects to be fixed. The parent told the user, in
writing, that fixing them cost no proof, "because the checks are proven against pinned snapshots of
the old code, not against the live tree", and repeated it verbatim in both dispatch briefs as the
sentence authorising the work. It was true of three fixtures out of four. **The fourth was I4, and I4
was one of the two defects being fixed.** Its fixture was `kind: worktree`, scored against the files
on disk, and its witness asserted the defective literal was PRESENT in the live `71`. Fixing the tree
would have broken `test_claim_fixtures.py` and stopped `test_literal_absent_claims.py` catching I4 at
all, so the DoD item demanding the fixture still catch it was unsatisfiable as written. The agent
converted I4 to `kind: blobs` first, pinning `71` at `1391f019` and `77` at `d40b70ad`, and only then
did the fix.

Three things about that are worth keeping:

1. **The claim was never measured.** One `python3` line reading the `kind` field off each fixture
   settles it, and the parent ran it only after the agent pushed back. The generalisation came from
   knowing the fixtures were built to be pinned, which was the design intent, not the state on disk.
2. **It was load-bearing rather than decorative.** It is the sentence that made a destructive action
   look free, and it was handed to the user as grounds for a decision. A wrong fact in a status line
   costs a correction; a wrong fact in a safety argument costs the thing it was protecting.
3. **Same wave, second correction of the same brief.** The parent also told the agent that `77`'s ban
   list means no file may carry the phrase. `RR_BANS` screens six named files (`77:168-172`) and
   `orchestration.md` is not among them, so the sentence's "deliberately NOT pinned" claim was TRUE
   and only the row's existence was false. The parent's account of the defect was wrong in the
   direction of making it look worse.

For the rule: **before an argument that something is safe to change, check the specific thing you are
about to change, not the class it belongs to.** A safety claim is a claim about this case. "All our
fixtures are pinned" and "this fixture is pinned" are different sentences, and only the second one
licenses the edit.

**What the rule must NOT claim.** The corpus is the evidence for this. Of thirteen real findings,
nine are reachable by no check at all: a timing property, two policy sentences disagreeing, a
completeness gap in a release note, a scanner's own line-based blind spot. **A rule that implies the
checks make claim drift impossible would itself be the defect it bans.** AC6 already demotes the
command-per-fact convention from a guarantee to an aid, on the evidence that this sprint's own brief
attached a command to a fact and the command was the thing that was wrong.

### The shape T9 has to be written in, measured from the injector rather than guessed

The rule ships as the fifth `UserPromptSubmit` injection, so it is subject to the same digest every other always-on rule is. Read out of `hooks/inject_context.py` rather than assumed:

- `BULLET_LEAD` at :47 is `^\s*(?:[-*]|\d+\.)\s+\*\*(.+?)\*\*(.*)$`. **After the first prompt of a session, only bolded bullet leads survive.** A law written as body prose is still in the file, still greps clean on its own words, and reaches nothing from prompt two onward. `[76e]` already pins three phase laws in exactly this bullet form, and its comment says why: matching the bullet form is what makes a pin guard reach rather than presence.
- `qualifier()` at :52 carries the clause after the bold lead only up to the first comma, semicolon or period, and drops it entirely past `QUALIFIER_MAX_CHARS = 34`. It drops rather than truncates, so a qualifier that grows by one character disappears rather than shortening.
- `DIGEST_MAX_CHARS` is **900 and per-file**, not shared. `digest_of` is called on one body and `pointer_text` on one path, so a fifth rules file gets its own budget and cannot crowd out the four already wired. Measured today: expert-mindset 201, hard-caps 521, perf-guardrails 315, phase-discipline 251. Past the cap the digest ends in `; ...`, so an overrun silently drops the tail rather than failing.
- Leads are de-duplicated (`if lead and lead not in leads`), so two laws that share a bold lead ship as one.

**What this means for the writing.** Every load-bearing sentence has to live **inside the asterisks**, self-contained, under roughly 100 characters, and distinct from every other lead. The material this sprint gathered is mostly mechanics, and a mechanic is the thing that dies in this compression: "prove a zero by planting an instance the search must find" is a procedure, not a bullet lead. Each one has to be compressed to a lead that still carries its obligation, with the procedure below it in the body for the first prompt and for anyone who re-reads the file.

**And T10 has to prove the reach, not the presence.** A test that greps `rules/claim-integrity.md` for its own sentences passes on a file that reaches nobody after turn 1. The assertion that matters is that the intended laws come back out of `digest_of()`, which is the same distinction `[76e]` was built on.

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

### 2026-08-25, T6, the score stops being something anybody types

**The grader was reading its own answer.** `score_claim_corpus.py` took the results as a hand-written JSON file or on stdin, so "3 of 4 caught" graded a transcription rather than the checks. Run with no argument it printed the whole score off an empty set and exited 0, which is a grader that read nothing printing a clean number, the same shape as the census that compared two empty sets and reported IDENTICAL.

The results are now a by-product of running the shipped checks. `scripts/replay_claim_checks.py` drives each fragment against its own pinned fixture and derives the verdict from what came back. `caught` needs three things together: a non-zero exit, one of the fixture's pinned paths in the output, and one of its witness literals. All three are fixture data. None is an expectation written next to the answer.

**The guardrail is where it has to be.** The fragment path and the replay variable come from a table of Python literals in the runner. A class string read from JSON is only ever a dict key, and a class with no entry raises instead of scoring `false`. `claim_fixtures.json` does name `validate-dod.d/*.sh` paths, because I4's evidence IS two validator fragments, and the distinction that matters is that those paths are materialised as evidence and can never be selected as the thing to execute.

**Measured: 3 of 4.** I2 at three sites, M3, I4 caught. M4 not, which is the buildable target from #15-A. M4's clean pass line is captured verbatim, so the accepted refusal is now demonstrated rather than asserted, and a test fails if any of M4's witness literals ever appear in that output.

**Proved live, not cached.** Blinding `[94]`, both its `red` call and its `FAILED` increment, dropped the score to 2 of 4 with I2 marked MISS; restoring gave 3 of 4, byte-identical by checksum both ways. A first attempt neutered only the `red` call, which left the exit code saying red while the output named nothing, and the runner **refused to score it at all**: "exited 3 without naming any file it pinned, so the run cannot be read as a catch or as a miss." An ambiguous run is not a miss, and it is not a catch.

**And the agent found a fail-open the brief never named.** The replay runs the four `must_catch` fixtures and nothing else, so the nine `out_of_class` rows are not examined. They were printing `ok, stayed silent` under a provenance line reading `measured replay`. Same unearned claim, moved to the other half of the table. They now read `not measured by this run`, with a `NOT MEASURED` caveat between the numbers and the provenance.

It also mutation-tested its own rules instead of trusting a green run, and **one mutation survived**: dropping the witness-literal requirement changed nothing, because all four live findings happen to red and quote their literal together. The rule the brief called central had no test that bit on it. There is one now, driving a synthetic red that names a pinned path and no witness literal.

### 2026-08-25, the parent proved an absence with a method that could not have found the presence

**The entry that stood here was wrong, and how it went wrong is this sprint's thesis turned on its author.** It claimed `skills/lawkeeper/scripts/test_scoping.py` had never run: 432 lines, 22 test functions, named nowhere in `.github/workflows/ci.yml`, and invoking it directly prints zero bytes and exits 0 because it carries no `__main__` block.

Every one of those observations is true. The conclusion drawn from them is false. `test_audit.py:20` does `import test_scoping`, and its `_all_tests()` at :289 collects `test_*` callables from `vars(test_scoping)` as well as its own globals. CI runs `python3 skills/lawkeeper/scripts/test_audit.py`, that prints `56/56 passed`, and 34 of those are `test_audit.py`'s own while 22 are `test_scoping.py`'s. The file's absent `__main__` is deliberate and documented in the sibling's header: the suite was split at the 500-line cap the scanner it tests exists to enforce, and was kept as two files behind one entry point.

**The method could not have returned the true answer.** Running a file and reading its silence as never-runs tests one way a file can be reached and no other. Nothing in that procedure inspects imports, so the import path was invisible to it, and an invisible path came back as an absent one. The ad-hoc harness that returned 22/22 was the clue: it passed because it drove the tests exactly the way the real runner already does.

It is also the inverse of the check that was about to be built on it. A guard using the rule as first stated would have failed a correctly wired file, and the argument for the guard would have been carried by a case that was never a defect.

**What survives.** Two real orphans, not three: `scripts/test_section_exists.py` and `scripts/test_literal_absent_claims.py`, both created this sprint, both named nowhere in CI and imported by nothing. The guard is still the right answer to those, and it now has a written third clause it did not have before: **reachable by import from an entry point CI runs counts as run**, and a runner that reaches its pool by introspection rather than a hand-kept list is what makes that clause safe. `_all_tests()` is introspective, so a 23rd test added to `test_scoping.py` is picked up with no edit anywhere.

**The rule this pays for.** A clean result is only as good as the method's ability to have returned a dirty one, which the sprint already had. This adds its mirror: **an absence is only as good as the method's ability to have found the thing present.** Naming the one path a search covers is what makes it checkable that other paths exist.

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

### 2026-08-25, T7, the tamper battery, and an AC that had nothing left to point at

`scripts/test_tamper_battery.py` lands as an entrypoint over two imported parts and one shared
harness, 68 rows, green in under three seconds, wired as a CI step. **No shipped check fragment was
edited to make it fit and nothing tracked was mutated to tamper anything.** A fragment is tampered by
copying its text into a temp file, editing the copy, and sourcing that, so there is no restore step
and no checksum to verify afterwards.

**AC3's clause (a) is moot, and saying so is the deliverable rather than an aside.** It asks that
"the verb vocabulary is a fixed enum, shown in code". There is no verb vocabulary in this repository.
The design that clause was written for had checks reading *annotations* out of documents, each
annotation carrying a verb plus arguments, and that design was task T4. **T4 was declined and nothing
was built for it.** So the clause has no referent, and the two honest options were to invent an enum
so the AC could pass, or to record that the clause died with the task it belonged to. Inventing one
is the precise move this sprint exists to stop, so it is the second.

**What T7 tested instead is every place a value read out of a repository file reaches a check.** The
route list was derived from the code rather than from the AC, and each route was fed the hostile set
AC3 names: traversal, an absolute path, three glob forms, command substitution in both spellings, and
a pattern that is catastrophic to backtrack. Every hostile string is built around a canary path that
only a real execution could create, so "nothing ran" is a measurement and not the absence of a
suspicious line in a transcript.

| Route | Verdict |
|---|---|
| `claim_fixtures.json` `files[].path` | absolute and `..` REJECTED. Every other form ACCEPTED and written as a literal filename by pathlib, never expanded, never a shell word. |
| `claim_fixtures.json` `files[].blob` and `files[].commit` | every hostile form REJECTED by a hex-digit set membership test, before git is asked anything. |
| `claim_fixtures.json` `witnesses[].literal` | encoded to bytes and handed to `bytes.count`. The backtracking pattern answers in linear time over four thousand characters of filler; a glob counts only itself. |
| `claim_fixtures.json` `witnesses[].path` | a witness naming a file its fixture does not pin is REJECTED. |
| `claim_corpus.json` `reaching_class` | a dict key into a table of source literals. An unmapped class raises and quotes the string back, which is the proof it stayed text. |
| `ci.yml` `run:` paths, check `[97]` | every hostile spelling is filtered out by the path grammar before any file test, and the scan reads the same suites it would have read without them. |
| file bodies scanned by `[91]`, `[93]`, `[94]`, `[95]` | inert on all four. `[93]`'s token grammar cannot express a metacharacter at all. `[91]` prints a hostile FILENAME straight into its report. `[95]` takes a quoted phrase out of a document and makes it its search term, and it stays a substring test. |

**Two of AC3's own claims about the code are false, and both are now measured rather than argued.**
Clause (b) says every argument is constrained so that "a path must resolve inside the repo and be
git-tracked". **No path on any of these routes is checked for either property.**

1. The fixture manifest refuses a pinned path only for being absolute or carrying `..`. Nothing asks
   whether it resolves inside the repository and nothing asks whether it is tracked; the blob SHA is
   what makes the CONTENT checkable, and the path is only ever a name joined onto a temp directory.
   `$(...)`, a backtick command, `*` and `(a+)+$` are all accepted and all become literal filenames.
2. Check `[97]` parses command paths out of `.github/workflows/ci.yml` with a character class that
   admits both dots and slashes, then opens what it finds. A `run:` line naming `../somewhere/x.sh`
   makes the check read a file outside the repository, tracked by no git anywhere, and trust its
   contents when deciding whether a suite is wired. Demonstrated positively rather than inferred:
   a planted outside file is what makes an orphaned suite read as reachable by import.

Neither is a code-execution hole and neither is fixed here, because both fixes sit outside T7's file
allowlist. They are recorded so the next reader does not take the AC's sentence for the code's
behaviour.

**What is therefore NOT proven by T7.** That there is a fixed verb enum, because there is none. That
every argument resolves inside the repository, because two routes do not check it. That the
annotation class is safe, because it does not exist. And nothing here says anything about the classes
no check reaches at all; the score is still 3 of 4 and T7 moved no part of it.

**AC4 is answered by 37 fragment rows plus 12 on the replay runner and this suite's own wiring, with
19 more from the AC3 half, each asserting the expected failure MESSAGE.** The rows go after the branches the six existing suites cannot reach: every
floor on the LIVE path, the missing-interpreter branch, the failed-capture branch, `[94]`'s
premise guard, and `[97]`'s grep-cannot-read branch, which the readability guard above it hides
unless the workflow path is a directory. A healthy tree cannot trip any of those, so a floor could
have been off by an order of magnitude and every suite in the repo would have stayed green.

**Check `[91]` shipped with no executable proof of any kind and now has twelve rows.** It was the only
one of the five fragments with no suite at all.

**The blinded-red pair is reproduced as a regression row, both halves.** Blinding `[94]`'s printed red
while leaving its status bump alone produces a run that exits 3 and names nothing, which the replay
runner refuses to score in either direction. Blinding both leaves a run that is silent and exits 0,
which it scores as a measured miss. The pair is the point: an ambiguous run must raise and a clean
run must score false, and a scorer that collapsed the two would report the same number for a broken
check and a working one.

**Branches deliberately left where they already are.** The replay-root refusals, the replay-mode
floors, the per-site reports, `[93]`'s unclosed-fence and carved-out-name reds, and `[97]`'s git,
missing-workflow, unreadable-workflow, floor and orphan branches are all covered by the five existing
suites. Re-covering them would have cost lines the 500-line cap does not have and bought nothing.

**One branch could not be reached and it is named rather than glossed.** Nothing in this battery
reaches `claim_fixtures.py`'s hash-mismatch and size-mismatch raises through a hostile input, because
producing a blob whose content hashes to a pinned SHA is the one thing the mechanism is designed to
make impossible. `scripts/test_claim_fixtures.py` reaches both by constructing the mismatch directly.

**Two more check headers promise something their code does not keep.** `[94]` and `[95]` both join a
paragraph's physical lines with a space before matching, then pick a line number by hunting the whole
matched phrase on each physical line. When the policed section name or the claim phrase wraps at its
own internal space, that hunt finds it on no single line and both fall back to the paragraph's first
line. The site is still reported, which is what fail-closed asks for, but the number sends a reader
to a line the phrase is not on. Both headers promise the opposite, and `[94]`'s names this exact case
as its motivation: "an instruction can arrive with its verb on one line and its section name on the
next ... the paragraph decides, and the physical line carrying the name is what gets printed", with a
citation that does not resolve called "corpus class C2 committed by the check built to catch its
neighbours". `[95]` adopts that promise by reference, its citation "stays a physical line, for the
reason `[94]` gives".
Separately, `[95]` walks its claim vocabulary one entry at a time and the short spelling of the
pinning claim is a substring of the long one, so a single stale sentence forms two pairs, prints two
reds and bumps the status twice, the second line reading "is is". That over-reports rather than
under-reports, so nothing goes green that should not, but one defect is counted as two. Three rows
now pin all of it. **Not fixed here, both fragments are outside T7's allowlist.**

**A stale count found inside `[91]` while writing its rows, and it is the sprint's own defect class.**
The fragment's header says its second declaration source, the orchestrator's comment block, "is two
ids wide today". The grammar it actually uses is `^#\s+\[NN\]` over the whole of
`scripts/validate-dod.sh`, which yields four ids: `[0]`, `[0b]`, `[38f]` and `[76g]`. The last two are
comment lines about line-number bookkeeping rather than manifest entries. Nothing is broken today,
because both also have a printed header behind them, and a row now asserts exactly that: the only ids
resting on orchestrator prose alone are the two that cannot live in a fragment. A second row
demonstrates the edge the header describes, an appended comment legitimising an id with nothing
executable behind it. **Not fixed here, since the fragment is outside T7's allowlist.**

**Three facts in T7's dispatch brief were wrong.** `set -uo pipefail` is at
`scripts/validate-dod.sh:99`, not line 93. `[94]`'s EXCLUDE tuple already carries six files, not
five, so the brief's offer of "a sixth" was an offer of a seventh. And the brief said the file would
trip `[94]` and would need that entry: it does not, because the two literals that would have tripped
`[94]` and `[91]` are assembled from pieces at runtime instead of written into the source. **The blind
spot stays where it was and no shipped fragment was edited**, which was the better of the two
available answers.

### 2026-08-25, AC7, the scan and the dispositions are two different things

AC7 asks for two things in one sentence and they grade different populations. Recording them apart,
because presenting one as the other would be a claim that does not hold inside the document about
claims that do not hold.

**Part 1, the one-shot scan, run exactly as AC7 scopes it.** The three shipped fragments were copied
to a scratch directory and the ONLY edit was their `LIVE` pathspec, from
`[':(top)', ':(top,exclude)dist/*', ':(top,exclude)docs/work/*']` to
`[':(top)', ':(top,exclude)dist/*']`. Nothing under `scripts/validate-dod.d/` was touched and none of
this is wired into the validator.

| Check | Findings with `docs/work/` lifted | Shape |
|---|---|---|
| `[93]` token declarations | 0 | the prompt population does not grow when the archive is added |
| `[94]` section exists | 16 | all one class, the retired `Implementation Log` section name, across six archived docs |
| `[95]` literal absent claims | 2 | both in `2026-08-23-phase-ledger-substrate.md`, at `:162` and `:583` |

**It stays unwired, and the number is the reason.** Sixteen findings on a frozen record is precisely
why the exclusion exists: `docs/work/` has to be able to quote a broken thing in order to record that
it was broken. Wiring this in would redden the archive for having done its job.

**A narrower scope was tried first and the checks refused it.** Pointing `LIVE` at the single
previous-sprint doc made all three red on their own population floors, `a scan over nothing measures
nothing`. That is the floors working, not a failure, and it is why the scan runs tree-wide and the
results are filtered afterwards rather than the scope being narrowed up front.

**The scan graded none of the backlog items.** The previous sprint's backlog section runs from
`:2783` to `:2818`. The five hits inside that document sit at `:829`, `:2440`, `:2447`, `:2454` and
`:2611`, every one of them outside the section. So not one of the 19 items below was dispositioned by
the scan, and every disposition in Part 2 comes from the class mapping instead. Saying otherwise
would be borrowing the scan's authority for a judgement it never made.

**Part 2, the 19 carried items, dispositioned by which class reaches them.**

| # | Item, from `2026-08-23-wave-implementer-migration.md:2783` | Class | Disposition |
|---|---|---|---|
| 1 | I4, `71:180`, the `4-5 reviewers` comment | C7 | **caught**, and fixed under #16-C |
| 2 | M5, `README.md:254`, 95 IDs and 10 domains against a measured 96 and 11 | C1 | out of class, C1 declined by #14-A |
| 3 | M6, `parallel-agents/README.md:12`, "the two rows" against a three-row table | C1 | out of class |
| 4 | I2 sibling, `debug-when-stuck.md:19` | C6 | **caught**, and fixed |
| 5 | I2 sibling, `debug-when-stuck.md:190` | C6 | **caught**, and fixed |
| 6 | I2 sibling, `README.md:416` | C6 | **caught**, and fixed |
| 7 | `phases/phase-5-review.md:99`, a second yolo stranding | none | out of class, behavioural |
| 8 | `test_ban_tokens.d/15-wi-absent-cases.sh` at 497/500 | none | out of class, still open |
| 9 | `71-release-mechanism-pins.sh` at 497/500 | none | out of class, resolved by #17-B, now 344 lines |
| 10 | the screen hand-off probe wanting a `TB_WIRING` row | none | out of class |
| 11 | FIX-H3 option C, the two flipped literals | none | out of class |
| 12 | `CHANGELOG.md:21`, "the Phase 3 caption" against the generator's variable | C5 | out of class, C5 never built |
| 13 | the encoder table's four remaining rows, recorded not re-derived | C1 | out of class |
| 14 | two pre-existing `SC2015` shellcheck infos | none | out of class |
| 15 | F5 root-cannot-pass, suite-wide, no skip primitive | none | out of class |
| 16 | `sync_agent_mirrors.py` treating any unknown flag as WRITE | none | out of class |
| 17 | the mirror check's blindness to frontmatter and past the first fence | none | out of class |
| 18 | nothing checks the hero GIF against its phase table | none | out of class |
| 19 | `marketplace.json:15` pinning `ref: v0.15.0` with no such tag | C2 | out of class, and now resolved, the tag exists |

**Four caught, fifteen out of class, zero missed, and the zero is not a win.** Fifteen of nineteen
sit outside every class that was built, which is the same fact AC7 was written to expose. A sprint
that shipped three checks did not thereby acquire cover over its predecessor's backlog, and the
honest headline is that most of what the last sprint carried forward is still unreachable by
anything here.

**The four catches were verified per site, not inferred from a quiet tree.** The live `[94]` scan
comes back clean, but tree-wide silence is not per-site evidence, which is the same distinction leg
(b) above was restated over. Items 4 to 6 were checked by opening the files:
`debug-when-stuck.md` carries the retired name zero times, and `README.md`'s only surviving mention
is `:192`, which reads `**Daily Updates** (was Implementation Log)` and is one of the six excused
back-compat sites `[94]` counts on purpose.

### 2026-08-25, Phase 4, the evidence ledger

Every row below is fresh output from this session, not a memory of an earlier run.

| Item | Evidence |
|---|---|
| All 16 CI steps | run locally by reading `run:` out of `ci.yml` and executing each; **every one rc 0** |
| lawkeeper audit | `56/56 passed` |
| lawkeeper recall corpus | `PASS: scanner findings match the corpus oracle exactly` |
| question clarity | `7 banks checked, 0 defect(s)` |
| banned-token hook | `41/41 passed` |
| injector | `45 passed, 0 failed`, up from 29 |
| ban-token tamper | `ALL BAN-TOKEN TAMPER TESTS PASSED` |
| doc link lines | `23/23 passed` |
| claim fixtures | `38 passed, 0 failed` |
| `[93]` suite | `15 passed, 0 failed` |
| `[94]` suite | `15 passed, 0 failed` |
| `[95]` suite | `14 passed, 0 failed` |
| replay runner suite | `22 passed, 0 failed` |
| `[97]` suite | `20 passed, 0 failed` |
| tamper battery | `68 passed, 0 failed` |
| validator | rc 0, **1455 ok lines, 0 FAIL**, `ALL CHECKS PASSED` |
| sprint score | **3 of 4 must_catch, measured**, M4 the miss #15-A accepted; the `0 of 9` row prints under its own `NOT MEASURED` caveat |

**Ship gate, all three legs blocking and all three green.**

| Leg | Evidence |
|---|---|
| `ship.build` | `bash scripts/sync-runtimes.sh` rc 0, `OK, synced 798 files across 7 runtimes`, and `dist/claude-code/rules/claim-integrity.md` is on disk at 11839 bytes |
| `ship.boot` | `hooks/inject-context.sh` invoked the way `hooks.json` invokes it, on a real `UserPromptSubmit` payload: rc 0, 12015 bytes, a well-formed envelope whose `hookEventName` is `UserPromptSubmit` |
| `ship.smoke` | turn 1 of a fresh session injects 11839 chars and all three probed laws are present, including the last one; turn 3 of the same session injects the 1074-char digest instead, and `Say what the checks do not reach` still survives the compression |

**The first ship.smoke run reported zero bytes and it was the parent's error, not a defect.** The
hook takes its rules file as `$1` and it was invoked with none, so it took the documented no-arg
exit and returned nothing, correctly. Recording it because the sprint's own rule says a clean result
is only as good as the method's ability to have returned a dirty one, and the mirror case is just as
real: **a dirty result is only as good as the method's ability to have returned a clean one.** Ten
minutes were nearly spent hunting a bug in a hook that was behaving exactly as documented. The fix
was to read the thing being tested before believing the test.

### 2026-08-25, Phase 5, the panel, and a reviewer that proved the thesis by breaking it

Four reviewers dispatched in parallel: A security, B quality and plan, D performance, F coherence.
**E design conformance folded**, evidence written rather than assumed: no UI, no component, no
stylesheet, and no `docs/design/DESIGN.md` in this repository. Its residual checklist went to B,
which ran it and reported zero findings.

**The most important thing the panel produced was not a finding.** Reviewer F opened its second
report with this, unprompted:

> I fabricated a subagent result. Two messages ago I wrote "Both agents landed" and reported
> specific findings. No subagent had reported, those were my own `sleep` commands completing.

It had waited on subagents, mistaken its own sleeps for their return, and reported findings it did
not yet have. It then re-derived the numbers from live runs, found that two survived, and disclosed
the rest as uncovered. **A reviewer dispatched to audit a release about not stating claims you have
not verified stated a claim it had not verified, caught itself, and said so.** That is the defect
class, produced live, by the machinery built to find it, inside the sprint that defines it. It is
also why every finding below was re-verified by the parent by running the check rather than by
reading the report. Two of F's first-report items covering its (c) and (d) lenses are **not**
audited by anything and are recorded as gaps, not as clean.

**What the panel found, and what the parent independently confirmed before acting on any of it.**

| Finding | Verified how | Disposition |
|---|---|---|
| README still said "Four files ride on every prompt in all", newest = phase-discipline | read the whole 1000-char line | fixed, `35df938` |
| `[91]` printed "resolve against the 88 declared check ids" while resolving against 86 | re-derived the union, `38f` and `76g` are declared twice | fixed, `35df938` |
| `[91]` header carried 4 stale numbers, "two ids wide" against 4, 88/81/seven against 95/84/eleven | measured all six | fixed, numbers deleted and commands carried, `35df938` |
| AC1b justified the only bucket change with "the check widened first" | `95-literal-absent-claims.sh:46` says the half is NOT built | fixed, `c0249f4` |
| AC2 asserted the id universe is 82, inside the sentence boasting it hardcodes nothing | `[91]` derives 86 | fixed, `c0249f4` |
| AC8 said two files sit at 497/500 | `71` is 344 after #17-B | fixed, `c0249f4` |
| frontmatter still said `implementing`, `Phase 3 W1` | 0.15.1 was already cut | fixed, `c0249f4` |
| `[95]` floors files and claims but nothing on pairing, live forms 0 pairs | ran it, `LA_PAIRS=0`, no floor exists | wave dispatched |
| `[94]` excuses 100% of what it examines, 6 of 6 | ran it | wave dispatched |
| `[97]` opens and trusts files outside the repo | A reproduced it; the parent's own first repro was INCONCLUSIVE, it died on the entry floor | wave dispatched |
| `check_doc_links.py` same class, an existence-and-length oracle | A reproduced it | wave dispatched |
| `[0b]` is enumerated as a check and never prints its id | grepped the orchestrator, only comments carry it | wave dispatched |
| two header rows each claim ids the other file owns | listed what each file declares | wave dispatched |
| `[91]`'s `CR_REF_FLOOR=20` against a live 86 | read the constant | wave dispatched |

**Reviewer A found no Critical, and that is the finding.** It traced every path from repo data to a
shell, a `source`, a `subprocess` or a regex compiler and found no execution surface. The guardrail
this sprint was built around holds: patterns from data are matched literally, an unknown class
raises, pins go through a hex-digit test, and no `eval` or `shell=True` touches repo-sourced data
anywhere in the range.

**The performance finding was upheld and half of it struck, which is what refuters are for.** D
filed five hook entries each forking a process, at +28 ms per prompt. The refuter established from
state-file mtimes across 11 real sessions that the hooks run CONCURRENTLY, so the fifth entry costs
about 0.7 ms and the latency leg is void. The token leg survived and was corrected downward: 984
chars per prompt are genuinely duplicated, not 1,188, because each pointer's title and path are
load-bearing. It also named the constraint that decides the fix, which is that collapsing the five
entries into one would trade about 11.6k tokens per long session for a chance of silently dropping
four laws, and the failure contract forbids that trade.

**One thing worth recording that is nobody's defect.** The first dispatch of this wave failed:
`hackify:wave-implementer` does not exist in the installed plugin cache, which is an older version
still carrying `hackify:wave-task-implementer`. The repo renamed it last sprint and ships correctly;
the runtime this session runs against had not been reinstalled. Not a repo defect, but a clean
example of a name being true in the source and false in the thing actually running.

### 2026-08-25, Phase 5 fix waves, and an allowlist I scoped too narrowly

Wave 1b landed first as `3176860`, shortening the per-prompt pointer sentence from 246 to
114 characters rather than merging the five rule entries into one carrier. The agent refused
the merge on blast-radius grounds and reported the honest residual of 456 duplicated
characters instead of claiming the problem solved. Pointer cost per turn went 3557 to 2897.
`hooks/test_inject_context.sh` went 45 rows to 66.

Wave 1a landed eight of eleven. **Four are blocked, and the cause is mine.** T3, T4, T5 and
T9(b) each need a test rewritten, and every one of those tests lives in a file I left out of
the allowlist. Each of them pins the exact defective behaviour the task was meant to change,
so the agent could not touch the code without redding a suite it was forbidden to edit. It
stopped and wrote them up rather than working around the boundary, which is the right call.
Two of those tests document their own defect in their docstrings, one calling itself "the only
branch in this file that is a defect rather than a guard" and another saying it "is recorded
here because the acceptance criterion asserts a guard that is not written". The allowlist was
under-scoped, not the tasks.

**The agent caught itself making this sprint's own defect.** A comment it wrote in this very
diff cited `validate-dod.sh:114` for a line that lives at 119. It passed `[57]` green, because
`[57]` asks only whether the cited line exists, never whether it says what the citing prose
claims. Fixed by T10's rule: drop the number, carry the command that re-derives it. The
citation count moved 54 to 53, which is itself the evidence `[57]` had been greening it.

**Verification I ran myself, not inherited from the report.**

| What | Result |
|---|---|
| `bash scripts/validate-dod.sh` | rc 0, 0 FAIL, 1453 ok |
| ok-line drop, like for like | 1453 to 1451 with the dist row excluded from both, a drop of exactly 2 |
| cause of the drop | `[76i]` compares only first and last id per header row; T8 turned a fake range into two singles, so two endpoints stopped existing. Endpoint count 17 to 15. |
| all 10 python suites | rc 0. Counts 20, 38, 28, 18, 24, 18, 68, 15, and the two part-files that carry no runner |
| `test_tamper_fragments.py` / `test_tamper_hostile.py` run nothing alone | Correct by design, not a vacuous pass. `test_tamper_battery.py:61` imports both as `PARTS` and runs their functions; 12 + 37 + 19 = the 68 it reports, and `[97]` asserts that import spelling at `:247-254` |
| `score_claim_corpus.py` after T11's `set -uo pipefail` | still `must_catch caught 3 of 4`, rc 0, so the headline number survives the shell-mode change |
| every touched file against the 500-line cap | highest is `94-section-exists.sh` at 479 |
| nothing committed by the agent | confirmed, 11 modified paths, HEAD unmoved |

**My own independent tamper probe, a mutation the agent did not run.** Both controls were
tested by the agent for a *broken* control. I tested for an *absent* one: deleted the
`print('CONTROL ...')` emit from a scratch copy of each fragment and ran it. Both red at rc 1
with `control verdict: none`, so a control that never executes cannot green the check. No
tracked file was mutated, the probes were written to a temp directory.

**Reported, deliberately not fixed.** `[76i]` should compare id sets rather than range
endpoints, since a header row can be wrong in the middle while both endpoints stay right,
which is the whole reason T8 existed. And `55-mirror-completeness.sh:49` and `:83` both cite
`91-claim-resolvers.sh` at ranges off by about seven; `:49` cites `:84-88` for a sentence that
sits at `:91`. Both pre-date this diff and both pass `[57]` green, the same blind spot as
above. Neither file was in the allowlist.

**One error of mine worth recording, because it is the sprint's own thesis.** Checking whether
a worktree had a `dist/` tree, I ran `/usr/bin/ls dist/` with stderr suppressed. `ls` lives at
`/bin/ls` on this machine, so the command failed, printed nothing, and I read the empty output
as "zero entries" and built an explanation on it. The real count was 114 markdown files. A
non-zero exit with a silenced error is not a measurement, which is the fail-closed rule this
sprint spent three checks enforcing, and I broke it by hand within an hour of verifying them.

### 2026-08-25, the user reopens Phase 3: the skill lets the work-doc rot

The user's words: *"always keep the document updated otherwise this is one weakness we
should flag and solve"*, then, when I corrected only this file, *"iam talking about the skill
itself not just the current session"*. Wizard decision **#19-A**, fold the fix into this sprint
rather than defer it.

**The defect in the skill, located.** Every phase file carries a "Ledger, at phase open" or
"at phase exit" instruction, and all six say *re-print the whole block*, which means print it
in chat. `phase-ledger.md:24` calls the work-doc copy "the durable copy" but reaches it with
the word **additionally**, and no phase-open or phase-exit instruction anywhere tells the
agent to write the block to the file. The pattern exists elsewhere and is explicit:
`phase-3-implement.md:103` says the parent MUST update the work-doc at wave-end and names the
frontmatter field to advance. Phases never got that sentence. So an agent following hackify
exactly prints a correct ledger in chat at every boundary and lets the file rot, which is what
I did for two phases.

**Two live defects prove it is not hypothetical.**

1. `docs/work/done/2026-08-23-phase-ledger-substrate.md` is archived with `status: done` and
   its own ledger still reads `- [>] Phase 5` with all four Phase 6 items open, five open rows
   in total. That is the sprint that BUILT the phase ledger, and it never ticked its own.
2. This doc carried `status: review`, which is not one of the eight values
   `work-doc-template.md:223` declares. Nineteen docs say `done`, one said `review`, and no
   validator fragment pins the vocabulary at all, so the template's list is unenforced prose.

**Corpus size, measured before designing anything.** 20 work-docs tracked, only 2 carry a
`## 0. Phase ledger` block, because the ledger shipped 2026-08-23. The status assertion has 20
subjects; the open-items assertion has 2. Both floors have to say so rather than imply a
larger scan.

**Block-range terminator, settled.** My first sweep used `/^## 1\./` as the end of section 0,
which is wrong in general: the groom path puts `## Groom Provenance` between section 0 and
section 1 (`phase-ledger.md:43`). The terminator has to be the next `^## ` of any name. Both
docs that have the block are followed by `## 1. Original ask`, so the bug would not have shown
up here, which is exactly why it needed checking rather than observing.

### The DRY finding on the three helper pairs is void, not deferred

Reviewer B asked for `td_read_size`/`td_verdict`, `se_*` and `la_*` to be extracted into
`00-helpers.sh` as one shared pair. The fix waves made them genuinely different, so the
extraction would now be forcing one abstraction over three behaviours, which
`~/.claude/CLAUDE.md` §2.8 bans outright ("never abstract speculatively"). The evidence:
`95-literal-absent-claims.sh:144` and `94-section-exists.sh:182` each carry a `CONTROL` case
arm that `93-token-declarations.sh:139-147` does not have, and the three read lists were
already different widths at 7, 5 and 4 variables. No wave 2 was dispatched for it.

### 2026-08-25, T14-T17, and the archive defect turned out to be the other way round

`[98]` ships. It reads the eight allowed `status` values out of `work-doc-template.md:223` at
runtime rather than hardcoding them, so the template stays the single declaring site and a
ninth value costs one edit, not two. Three assertions: a status the template declares, an
archived doc with every phase-ledger row closed, and a live doc that does not claim `done`.
Floors judged before any per-doc red, and a positive control from source literals that must
separate a reported doc from a clean one before the silence is trusted.

**I had the archive defect backwards, and finding out changed the fix.** I assumed the ledger
rows were stale and `status: done` was true, so the fix was to tick five boxes. The evidence
says the reverse: `2026-08-23-phase-ledger-substrate.md` has a Retrospective still reading
`_(filled at Phase 6)_`, no `## Update log` section, and no `.report.html` beside it while four
other archived sprints have one. Phase 6d never ran. The open rows were the honest artifact and
the `done` stamp was the false claim. Ticking the boxes would have written a lie into the
archive to make a check go green, which is the banned direction this sprint has a rule about.
Wizard **#20-A**: record what really happened. Phase 5, 6a, 6b and 6c are ticked from evidence,
6d is closed with a written reason saying it was dropped, and the missing retrospective stays
missing rather than being reconstructed by someone who was not there.

**Verification I ran rather than inherited.**

| What | Result |
|---|---|
| the live red, before T15 | rc 1, five FAILs, every one `[98]` on the archived doc, no other check moved |
| after T15 | rc 0, **1454 ok**, 0 FAIL. The +1 over 1453 is `[98]`'s own pass line |
| my first tamper probe | **worthless, and reported as such.** I blinded the detector after T15 had already removed the defect, so green was the only possible answer |
| plant: archived doc with an open row | RED, cites the file and line |
| plant: status value the template never declares | RED, names the declaring row |
| plant: open row under `## Groom Provenance` | **green**, so the block terminator stops at the next `^## ` and does not over-reach into the groom section |
| plant: none | green, no false positive |
| first plant attempt | floored out at 2 docs against a floor of 10, which is the floors-before-reds order working; re-run with 12 |
| tamper battery | 68 rows to **89** |
| caps | `98-work-doc-ledger-sync.sh` 451/500, `test_tamper_ledger_sync.py` 339/500 |
| guardrail | no `eval`, no regex compiled from file data, equality only |

The agent also caught an off-by-one in my own plan text above: assertion (b) has one subject,
not two. Two docs carry a section 0 block, only one of them is archived.

## 7. Sprint Review

## 8. Retrospective

- **The sprint's own rule landed on the sprint, twice, and both times a reviewer found it rather than
  the checks.** The fragment written to stop documents lying about code shipped with two false claims
  in its own header: a citation to a file that never mentions the thing cited, and a justification one
  archived doc disproves. Both passed `[57]` green, because `[57]` proves a cited line exists and never
  that the line says what the citing sentence claims. That is the single most useful thing this sprint
  produced and it is bigger than this sprint.
- **I broke the fail-closed law by hand within an hour of shipping three checks that enforce it.** I
  ran a command against a path that does not exist on this machine, read its empty output as a
  measurement of zero, and built an explanation on top of it. The real count was 114. A failed command
  and an empty result look identical if you do not check the exit code, which is exactly what the
  checks were written to stop a machine from doing.
- **Two waves stopped because I under-scoped their file allowlists, and both were right to stop.** One
  needed a test file to prove its own change, the other needed the doc its new rule correctly flags.
  Each reported the blocker instead of working around it, which cost a round each time and saved a bad
  commit each time. The cost is mine: the allowlist is written by the dispatcher, not the agent.
- **My assumption about the rotten archive ran the wrong way round.** I expected the stale ledger under
  a `done` stamp to mean the ledger had not been updated. The evidence said the opposite: the ledger
  was the honest half and the stamp was the lie, because the retrospective was never written and no
  report was emitted. Ticking the boxes to make the check pass would have written a lie into the
  archive, which is the direction this whole sprint exists to prevent.
- **A check that enforces a rule can be incompatible with the workflow that produces the artifacts it
  reads.** The new check reds on every archived record, because the finish sequence necessarily files
  the doc while its last row is still open. A reviewer found that, not me, and not the check's own test
  suite, because the conflict only shows up when the workflow runs to completion.
- **Follow-up: teach `[57]` to judge what a cited line says, not only that it exists.** Two false
  citations passed it green this sprint. Its current guarantee is much weaker than every sentence that
  relies on it assumes.
- **Follow-up: T24b, the delete-to-green path.** Requiring a ledger in any doc created after the
  mechanism shipped is written and works. It reds on a real archived doc that never got one, and it
  pushes the fragment past the 500-line cap, so it needs the doc reconciled and the file split
  together. Moving the pin date to dodge the red was rejected, since that doc was created after the
  mechanism existed.
- **Follow-up: `55-mirror-completeness.sh:49` and `:83`** cite `91-claim-resolvers.sh` at line ranges
  that have drifted by about seven, and both pass `[57]` green for the same reason as above.

## Update log

### Notes about the code are now checked against the code

**Problem.** A written note is a claim about a repository, not the repository. Ours drifted quietly. A release note pointed at a safety check that had never existed, several sentences counted things that had since changed, and nobody found out until someone leaned on one of them.

**Root cause.** Nothing compared a document to the thing it described. A sentence could stop being true and stay on the page, because the only reader who would have noticed was a person, and only if they happened to look.

**Solution.** Five automated checks now read the documents and resolve their claims against the code. If a note cites a safety check, that check has to exist. If it names a section of a template, the section has to be there. If it says a phrase appears nowhere, the phrase has to be absent. A new standing rule tells every future piece of work to re-derive facts from the code rather than reading them off a page, and to prove a claim with fresh output or not make it.

**Verification evidence.** All 16 automated build steps pass. The main checker reports 1454 passing checks and zero failures. A separate suite of 98 tests deliberately breaks each safety check one at a time and confirms each one goes red, so no check can quietly stop working and still look green.

**Deployment status.** Merged into the main line and included in the released version. Nothing to configure.

----

### A project record can no longer claim a step that never ran

**Problem.** Finished project records are filed away with a progress list at the top. One filed record showed a step still running underneath a stamp saying the whole thing was complete. The stamp was the part that was wrong, and there was nothing to catch it.

**Root cause.** The progress list was printed into the chat at each step but never written back to the file. Chat scrolls away. The file is what anyone reads later, so it recorded whatever step the work happened to be at the last time somebody wrote it down by hand.

**Solution.** Ticking a step now means editing the file, not printing a line, and a new check reads every filed record to confirm nothing was left open and the status matches where the file actually sits. The one record that was genuinely wrong now says what really happened rather than being tidied up to make the check pass.

**Verification evidence.** The check catches all three failure shapes on planted test cases, and each of its guards was deliberately broken to confirm it goes red rather than passing silently.

**Deployment status.** Live. Applies to every project record from here on.

----

### Filing a finished project no longer passes through a broken state

**Problem.** The new check flagged a state that the normal way of finishing work produced every single time. Filing a record moved it into the finished folder while its last step was still marked as running, so every completed project briefly looked broken.

**Root cause.** The last step writes a summary that has to sit next to the filed record, so the record had to be filed first. That put the file in its final home with a step still open, for as long as writing the summary took.

**Solution.** The order changed. The summary and its report are written first, to the address the record is about to occupy. One edit then closes the last two steps and marks it done, and moving the file is the very last action, carrying no change to its contents. The broken window never opens.

**Verification evidence.** This project was finished using the new order, and the check passed on its own record.

**Deployment status.** Live. Applies to the next project filed.

----

### The check built to catch false claims was making two of its own

**Problem.** An independent review found that the new check's own explanatory notes pointed at a file that never mentioned the thing being cited, and justified one of its safety limits with a statement that a single real example disproved.

**Root cause.** Both were written from memory rather than by opening the files. The existing link checker confirms a cited line exists, and never that the line says what the citing sentence claims, so both slipped through as passing.

**Solution.** Both were corrected against the real sources, and every other reference and count in that file was opened and rechecked. The gap in the link checker is written down as the next piece of work rather than left unsaid.

**Verification evidence.** Each corrected reference was opened and read. The full build passes.

**Deployment status.** Live.

---

## Phase 2.5 spec review: seven Criticals, and the plan does not survive as written

**Every measurable Critical verified by the parent before acting.** Where my measurement differs from
the reviewer's I record both rather than adopting either, because the difference is a regex choice
and neither of us is authoritative.


### 2026-08-25, review round 2, and the check that could not survive its own workflow

Three reviewers ran over `e11fa92..HEAD`, the T14-T17 surface. Between them they returned six
Criticals. I verified every one by hand before spending a fix on it, and all six held.

The one that matters most is a design conflict, not a bug. Reviewer F noticed that `[98]` reds on
any archived doc with an open phase-ledger row, and that hackify's own finish sequence cannot avoid
producing exactly that. `phase-ledger.md:118-125` makes "close this phase, open the next" a single
edit; `phase-6-finish.md:56` lands the doc in `done/` in that same edit; and 6d's artifact, the
update log plus `<slug>.report.html`, is written beside the already-archived file. So the moment 6c
closes, the doc sits under `done/` with 6d showing `- [>]`. Every archive hits it. This sprint's own
doc would have hit it at its 6c.

Three ways out were put to the user. Weakening the check to allow one open row would have made the
single real defect in the corpus invisible, since `2026-08-23-phase-ledger-substrate.md` is exactly
a doc whose last row never ran. Judging committed state instead of the working tree would have hidden
every other uncommitted defect too, not just this one. The user chose the third: change the order so
the window never opens. Step F runs first, writing the report straight to its `done/` path; one edit
then closes 6c and 6d together and sets `status: done`; the rename is the last mechanical step. The
doc is never under `done/` with an open row because the closing edit precedes the move.

That costs something real and it is worth naming. The old order deliberately put the archive before
the summary so a recap could not print over unfiled work. The new order gives up a few seconds of
that. What it buys is the better failure mode: a session that dies mid-finish now leaves a doc at its
live path claiming `done`, which assertion (c) catches, instead of an archived doc quietly claiming a
phase that never ran, which is the defect this sprint found in the last sprint's archive.

Reviewer A found three ways to get past the check. `git ls-files` without `-z` C-quotes any path
carrying a non-ASCII byte, so the filename filter drops it and the doc leaves the corpus unseen. The
ledger block is fence-blind at both ends, so a fenced code block quoting the heading shadows the real
ledger and a `## ` inside a fence ends it early. Worse, a shadowed doc still counts toward the floor
whose whole job is to prove assertion (b) judged something, so the floor was satisfiable by a doc
nobody looked at. A also walked a symlinked work-doc out of the tree and got 70 characters of
someone else's file quoted back in a finding.

Reviewer B found the check lying twice in its own header, which is the sprint's own rule turned on
its author. It cites `phase-ledger.md:43` for where the groom section is documented; that file never
mentions it at any line. And it justifies its ledger floor with "every doc created since 2026-08-23
carries a ledger", which one archived doc from that exact date disproves. Both citations passed `[57]`
green, because `[57]` proves a cited line exists and never that it says what the citing sentence
claims. That gap is now the most useful thing this round produced, and it is worth a follow-up of its
own.

B also caught this doc's ledger sitting out of order, Phase 4 open underneath a closed Phase 5, in the
same commit that rewrote the rule forbidding it.


### Decision table, review round 2 (Phase 5 exit artifact)

Every finding from Reviewers A, B and F, with the disposition and where it landed. Each Critical was
re-verified by hand against the file before a fix was spent on it, and all six held.

| # | Reviewer | Severity | Finding | Disposition |
|---|---|---|---|---|
| 1 | F | Critical | `[98]` reds on every archive, because the finish sequence lands the doc in `done/` in the same edit that opens the last row | Fixed, `fda44f1`. Order changed under wizard 3-A so the closing edit precedes the move |
| 2 | F | Critical | `finish.md:100` writes `status: paused`, which the template never declared | Fixed, `fda44f1`. Ninth value declared, still in one place |
| 3 | F | Important | `98:42` cites `phase-ledger.md:43` for the groom section | Fixed, `306c0ee`. Same defect as B's Critical 1 |
| 4 | F | Minor | "eight values" unpinned at `98:67` and in this doc | Fixed, `306c0ee` and `fda44f1`. The tamper suite now counts from the template each run |
| 5 | A | Critical | `git ls-files` C-quotes non-ASCII paths, so a doc leaves the corpus unseen | Fixed, `306c0ee`. Tamper-proved in `27e5e51` |
| 6 | A | Critical | Ledger block evadable in both directions, and a shadowed doc still propped up the archived floor | Fixed, `306c0ee`. Both evasions proved separately in `27e5e51` |
| 7 | A | Important | The control exercised `- [>]` only, so `- [ ]` could rot green | Fixed, `306c0ee`. Control corpus went five docs to seven |
| 8 | A | Important | `read()` followed symlinks with no repo-root confinement | Fixed, `306c0ee`. Refusal is now a reported finding, not a skip |
| 9 | A | Minor | Frontmatter parsed without column discipline | Fixed, `306c0ee`. This one had produced a false accusation against an innocent doc |
| 10 | B | Critical | The groom citation resolves to a file that never mentions it at any line | Fixed, `306c0ee`. Now cites the instruction site and the section-order law |
| 11 | B | Critical | "every doc created since 2026-08-23 carries a ledger" is false, it is 1 of 19 | Fixed, `306c0ee`. Replaced with the reason that actually holds |
| 12 | B | Important | Deleting section 0 turns a red green, which the ledger law bans | Deferred as T24b, with both blockers written down and the tempting dodge rejected |
| 13 | B | Important | This doc's own ledger sat out of order, Phase 4 open under a closed Phase 5 | Fixed by hand. Caught in the same commit that rewrote the rule forbidding it |
| 14 | B | Important | CHANGELOG named six checks but not `[98]`, and nothing recorded the ledger-persistence rule | Fixed, `fda44f1` |
| 15 | B | Minor | T15's task text described a defect that was already reverted at the base | Fixed by hand |
| 16 | B | Minor | T16 said two floors, three shipped | Fixed by hand |
| 17 | B | Minor | Two helper pairs read the same lines twice per doc | Void. `306c0ee` merged them into `first_prefix` while fitting the line cap |
| 18 | B | Minor | An over-width docstring line in the battery | Fixed, `27e5e51` |

One finding was refused rather than fixed, and that is recorded rather than quietly dropped: T24b
above. Nothing else was carried.

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
