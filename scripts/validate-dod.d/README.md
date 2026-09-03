# The check-fragment manifest

`scripts/validate-dod.sh` is a thin orchestrator. Every helper function and
every check group lives in a fragment here, `scripts/validate-dod.d/*.sh`, and
the orchestrator sources them in the order the index below gives.

**This file is the manifest. The orchestrator keeps only the index.** The rows
came out of that file's header comment when it stood at 487 lines against the
500-LOC cap check `[80]` enforces, with 267 of those lines being this prose and
two more fragments enough to breach it. Nothing was compressed on the way out:
every row below is the row that was there, word for word, including the ones
that exist as corrections to a reader who was genuinely misled once. Several of
them record why a split was cut at one check rather than its neighbour, and one
records a range that read `[38c]-[38g]` and sent a reader looking for `[38e]` to
a fragment that does not hold it. That is the only record of why the structure
is the shape it is, so it is kept verbatim rather than summarised.

**A one-line row per fragment stays behind in the orchestrator, and it stays
because four checks read it there rather than here.** `[76f]` in
`76-phase-ledger-substrate.sh` requires every sourced fragment to be NAMED in
that header; `[76i]` in the same fragment parses each row's check-id range and
compares both endpoints against the fragment's own `yellow "[..]"`
declarations; `[76j]` in `761-manifest-readme-sync.sh` requires the index and
this file to name the same set, in both directions; and
`scripts/test_ban_tokens.d/40-fragment-coverage.sh` matches
the literal `<fragment>, check [NN],` for the four fragments nothing outside
the validator names. The index there is the lookup. This file is the record.

**And the rule joining them is now enforced rather than stated.** "A row added
to the index needs its paragraph added here" was prose in the orchestrator's
header from the day the record moved out, and the very next fragment to land,
`58-contradiction-miner.sh`, got its row and no paragraph. Nothing in the run
noticed for the life of that gap. `[76j]` is what noticing looks like.

## The fragments, in source order

Verbatim from the orchestrator header, indentation and all.

````
  00-helpers.sh, color printers, the ok counter, the line-oriented absence
                  family, one presence check, the rename-absence scanner, and
                  the loop that sources every other helper fragment beside it.
                  THAT LOOP IS WHAT MADE THIS DIRECTORY MOVEABLE AGAIN. The CI
                  commands outside it sourced this one file by name and handed
                  the shell at most one check fragment, so every symbol an
                  isolation run could reach was frozen here and the two splits
                  below each bought about one helper of room. Sourcing this
                  file now sources the whole set, so where a helper lives is a
                  question of what it is again. The set is defined by a glob in
                  exactly one place, that loop, and a set that resolves short
                  stops the run rather than leaving a shell without its matchers
  01-presence-matchers.sh, the presence matchers, BOTH flattened matchers and
                  the shared membership count (check_role, the flowed presence
                  pair, flowed_flatten and the flowed ban pair, the batched
                  line-oriented form, count_in_list). Split out of 00-helpers.sh
                  at the 500-LOC cap. The flowed families sat in two files while
                  the frozen list decided where a helper lived; they are twins
                  over one flattening, and the loop above is what let them be
                  filed together
  02-file-shape-checks.sh, the whole-file shape assertions (check_jq,
                  check_line_range). The same seam cut a second time, when
                  00-helpers.sh came back to exactly 500 of the cap and a wave
                  needed to add a helper to it. section_body left in the same
                  change and went nowhere, having one definition and zero callers
  10-required-files.sh, checks [1]-[6b], required files, JSON shape, and the
                  two leak screens. [6] bans the author's personal handles and
                  his one home directory out of SHIPPED content. [6b] joined it
                  when the work-doc became a publishing surface: Phase 6
                  publishes the live doc as a page, so a live work-doc is
                  screened for an absolute home path of ANY user, by shape
                  rather than by one literal, while docs/work/done/ is carved
                  out because an archived doc is the frozen record and is never
                  published again
  20-templates.sh, checks [7]-[15], [36] (template contracts incl. agents/)
  27-marketplace-ref-pin.sh, check [27], marketplace channel pins match
                  plugin.json (stable ref, edge ref, versions)
  30-version-and-summary.sh, checks [16]-[20]
  40-quick-skill.sh, checks [21]-[23], [35]
  41-required-reading.sh, check [41], every sub-agent template carries a
                  REQUIRED READING list whose every path is plugin_root-anchored
                  and resolves
  42-reader-declarations.sh, check [42], every file that declares a hackify
                  agent loads it is named by that agent's REQUIRED READING list
  43-verification-grammar.sh, check [43], every template carries exactly one of
                  the three canonical VERIFICATION sentences and it is the one
                  its own REQUIRED READING grammar demands. Split from [41] on a
                  seam rather than at a line count: [41] asks whether the LIST is
                  well formed, this asks whether a sentence in a DIFFERENT
                  section agrees with that list's grammar, a question neither
                  answers alone. Its own header carries the rest
  50-runtimes-and-companions.sh, checks [24]-[26], [28]
  55-mirror-completeness.sh, check [55], sync manifest covers every tracked canonical file
  56-dist-integrity.sh, check [56], every file the sync COPIES into
                  dist/<runtime>/ is byte-identical to the canonical source it
                  came from. Sits beside [55] because the two are halves of one
                  question and neither is the other: [55] asks whether a
                  canonical file is NAMED in the sync manifest, this asks
                  whether the bytes that shipped are the bytes on disk. A
                  fresh clone has no built tree and gets a printed skip
  57-doc-links.sh, check [57], all FIVE documentation-pointer forms resolve,
                  and each one is checked all the way down rather than to the
                  file it names: a markdown link resolved file-relative, a
                  backticked path resolved against any ancestor directory, a
                  line citation whose line is then read for real, a heading
                  anchor whose fragment is then resolved to a heading, and a
                  prose anchor whose named construct or quoted phrase is then
                  found inside the file it cites. This row said "every cited
                  .md link and prose path resolves" for as long as it took the
                  last three to ship, which read as form 1 and form 2 and
                  nothing else, and a reader consulting the map would have
                  thought a citation naming a LINE was unchecked. The forms
                  live in three files behind one entry point,
                  scripts/check_doc_links.py owning 1 and 2, check_doc_cites.py
                  owning 3 and check_doc_anchors.py owning 4 and 5, split when
                  the first stood at 491 of the 500-LOC cap; [57] still runs
                  one command and reads one ok line, and no check ID moved
  58-contradiction-miner.sh, check [58], no routing file asserts not-X where
                  a named authority asserts X, over a hand-written table of
                  routing predicates, and every entry point carrying no
                  predicate is PRINTED rather than passed over in silence.
                  Sits beside [88] because it is the half [88] cannot reach:
                  both of that check's directions are about EXISTENCE, every
                  row resolving to a file and every entry point carrying a
                  row, so a wave falsified two agent descriptions without
                  touching a single token and the whole bar stayed green. A
                  map whose rows all resolve can still misroute a session for
                  the length of that session, because the map is injected once
                  by the SessionStart hook and is the only thing telling a
                  fresh session which entry points exist. THE AUTHORITY IS
                  RE-READ EVERY RUN AND NEVER TRUSTED: each row names the file
                  and the verbatim sentence that makes its predicate law, and
                  a row whose sentence is gone reds as stale rather than going
                  on policing a rule the repo may have abandoned, so the table
                  cannot become a second, quieter source of routing law. THIS
                  ROW EXISTS BECAUSE IT DID NOT. [58] shipped with its index
                  row in the orchestrator and no paragraph here, which is the
                  index-implies-record rule failing on the first fragment
                  added after the record moved out; check [76j] now enforces
                  what that rule only stated
  60-primitives.sh, checks [29]-[32]
  70-invariants-and-new.sh, checks [33]-[34], [37], [38], [38b], [39], the
                  structural invariants (excised files stay excised, skill
                  frontmatter, hook command targets, always-on injection,
                  perf surfaces)
  71-release-mechanism-pins.sh, checks [38c]-[38d] and [38f]-[38g], one block
                  per shipped saving, each pinning the guard rail that keeps
                  the saving from becoming a silent loss of rigor. Split out
                  of 70 at the 500-LOC cap; the check IDs moved with the
                  blocks. TWO RUNS AND NOT ONE, because this file does not
                  declare [38e] and never has: 72 does. Written as one run
                  the row read as [38c]-[38g], which sent a reader looking
                  for [38e] here to a fragment that has no such block
  72-diff-slicing-pins.sh, checks [38e], [38h] and [38j], the v0.11.0
                  diff-slicing and carry-over mechanism, plus the settle-echo
                  contract's own FILE SET ([38h]), which sits beside [38e]
                  because [38e] is the block it guards. Split out of 71 at the
                  same 500-LOC cap, IDs and all; the cut was taken here rather
                  than at [38f] so that every line 71 keeps stays at the
                  number a live citation already names. SINGLE IDS AND NOT A
                  RANGE, for the reason the row above gives pointed the other
                  way: [38f] and [38g] sit in 71, so a run of [38e]-[38h]
                  claimed two blocks this file does not hold. [38j] IS THE
                  THIRD SUBJECT AND WAS ONCE THE FIRST'S BLOCK (7): the Phase
                  6 publish-contract pins sat inside [38e], so the transcript
                  line announced diff slicing over four pins about publishing
                  the work-doc as a page, and this row and the orchestrator's
                  described the fragment correctly while the check described
                  itself wrongly. It got its own id rather than its own
                  fragment because the fragment-total pin in
                  scripts/test_ban_tokens.d/40-fragment-coverage.sh is a hand
                  written equality at 47 and not a floor, so a 48th file
                  reddens the ban-token suite until that number moves in the
                  same change. [38j] now also holds the temp-directory rule
                  that lost its enforcement when the renderer was deleted, and
                  the doctrine half of the project-relative-path rule whose
                  enforcement half is [6b] in 10-required-files.sh
  73-implementer-rename.sh, check [40], the Phase 3 implementer rename pinned
                  from both ends, the live agent type present at every
                  dispatch site and the dead one absent from the whole
                  tracked tree. Split out of 70 at the 500-LOC cap, where it
                  was two thirds of the file on its own
  74-agent-shell-blocks.sh, check [74], every fenced shell block in a
                  dispatchable agent template parses under /bin/bash. Added
                  after a `case` pattern's `)` closed its enclosing `$(` in
                  bash 3.2 and made a whole VERIFICATION block dead code that
                  nothing else in this validator ever opened
  75-ship-bar.sh, check [75], the always-on ship bar (law-scout, ship gate,
                  coherence reviewer, refute + settled-diff exit) wired in every mode
  751-orchestration-tier.sh, check [75i], the orchestration tier, the
                  iteration driver and the completion sentinel wired as
                  DEFAULTS in every mode. Split out of 75 at the 500-LOC cap.
                  Three primitives that shipped in the same release as the
                  ship bar's four and were filed beside them for that reason,
                  which is a date and not a boundary. THE THREE-DIGIT PREFIX
                  IS DELIBERATE: it sorts and sources between 75 and 76, so
                  disk order, source order and check-id order stay one order,
                  which two free two-digit numbers elsewhere in the run could
                  not have bought. What did not move with it is [75h], the
                  agent-mirror block, because scripts/test_tamper_mirror_tails.py
                  names 75-ship-bar.sh and tampers literals inside it. THE HELPER
                  HALF OF THAT PIN IS GONE: that suite sources the whole helper
                  set now, so a destination fragment would reach every matcher.
                  What holds [75h] here is one constant in that suite and the
                  fact that this file has room, not a contract
  752-wizard-contract.sh, checks [75j]-[75k], the wizard contract and the
                  question banks it governs. Split out of 75 at the same cap
                  and for a plainer reason than the row above: every other 75
                  id is about a mechanism wired into a MODE, and these two are
                  about whether a question put to the user can be answered
                  without knowing hackify's internals. Two checks and not one,
                  because [75j] runs the checker over the banks and [75k]
                  asserts the contract they are judged against still states
                  the rule, and either alone goes green over the other failing
  76-phase-ledger-substrate.sh, checks [76]-[76f], [76i], where the phase
                  ledger lives, the per-phase tick lines, the always-on phase
                  laws, this orchestrator's own fragment enumeration ([76f]),
                  and this row's own range endpoints checked against the
                  fragments they describe ([76i]). The row is written as a
                  range plus a single id rather than [76]-[76i], because
                  [76g] and [76h] are no longer here and a closing range
                  endpoint would claim they were
  761-manifest-readme-sync.sh, check [76j], the orchestrator's index and this
                  file agree in both directions, and every name either one
                  carries is a fragment on disk. THE RULE WAS STATED AND NOT
                  ENFORCED, which is how [58] got an index row and no
                  paragraph: the sentence "a row added here needs its
                  paragraph added there" sat in the orchestrator header while
                  nothing read it, and the gap survived every check in the
                  run. [76f] polices index-against-SOURCE-LIST and [76i] the
                  ranges inside a row; neither opens this file. BOTH
                  DIRECTIONS, because each one alone leaves the hole the other
                  covers: an index row with no paragraph is a fragment the map
                  a reader consults does not describe, and a paragraph with no
                  fragment is a record of something that left. Split into its
                  own file rather than added to 76 because 76 is one of the
                  ten fragments the tamper harness runs in isolation, and
                  growing it grows what that harness has to keep working
  77-reviewer-roster.sh, check [77], reviewer-roster drift in COUNT grammar,
                  count bans over six files (two no other check reaches, a
                  wider token set on the four shared with [38g]) plus the
                  adjudication reviewer's report input
  78-dispatch-mandate.sh, check [78], no parent-authored diffs + orchestration
                  that is a tool call rather than a description
  79-standing-member-invariant.sh, check [79], the ROSTER-CLAIM half of the
                  roster guard, every 'standing member' claim must name B,
                  over a file set the check discovers rather than lists.
                  Split out of 77 at the 500-LOC cap
  80-file-size-caps.sh, checks [80] and [80b], file-size across primitives at the
                  bound that applies to each, with a non-failing note at 95% of
                  it, and the two 500-LOC counters (wc -l, the lawkeeper scanner)
                  agreeing at the cap boundary ([80b])
  801-cap-enforcer-agreement.sh, check [80c], this validator and the lawkeeper
                  scanner waive and raise the cap over the SAME files. Split from
                  80 on a seam: 80 asks which files are over their bound, this
                  asks whether the two enforcers agree which bound applied. Reads
                  the sets 80 measured, so it compares against the enforcement
                  that happened, and reds by name if that producer did not run
  81-no-claude-attribution.sh, check [81], no Co-Authored-By trailer,
                  Claude-Session line or generated-with footer in commits or
                  PR bodies
  82-throughput-and-routing.sh, checks [82]-[82g], the throughput and
                  routing doctrine of the 0.18.x sprint, one block per
                  change: the dispatch budget stated as digits in one file
                  only, the four Phase 3 stages with the testing wave last,
                  the per-returning-agent work-doc cadence, quick as the
                  default route with full mode never auto-firing, the
                  settled test_mode enum, and {{concurrent_wave_target}} on
                  both spec-reviewer copies. Five of the six pin the live
                  claim AND ban the wording it replaced, because a pin alone
                  goes green on a file that still carries both. [82g] then
                  pins skills/hackify/references/sibling-track-rules.md,
                  which no check here had ever opened: its 'none' database
                  branch is verified against the tree rather than believed,
                  and the absolute ban on the shared database above it was
                  not softened by that branch
  83-testing-stage-shape.sh, check [83], the testing stage's shape: the
                  `test-authoring` wave's quiet-tree and whole-round-diff
                  assumptions are conditional on {{sibling_tracks}} rather
                  than granted, on BOTH implementer mirror copies, and the
                  partition the stage splits on covers the production files a
                  watched red mutates as well as the test files it writes.
                  Three comments cited this rule as `[82h]` before it existed;
                  they now cite `check [83]`. ONE ID AND NOT A RANGE, for the
                  reason the 98 and 99 rows give: this fragment declares
                  exactly one check and a range endpoint would assert a
                  maximum it does not have
  84-no-pipe-into-grep-q.sh, check [84], no line in scripts/ OR hooks/, and
                  none inside a fenced ```bash block in agents/*.md or
                  skills/hackify/references/parallel-agents/*.md, pipes an
                  `echo` or a `printf` into a short-circuiting reader. THREE
                  SURFACES AND NOT ONE: this row said `scripts/` alone while
                  the fragment had covered hooks/ and the agent prompts for
                  two waves, so a reader consulting the map would have thought
                  the hook that runs on every submitted prompt was unguarded.
                  A reader is short-circuiting when it stops before its input
                  ends: grep's quiet and max-count family in every spelling
                  (`-q`, `-qF`, `-Eq`, `-F -q`, `--quiet`, `--silent`, `-m1`,
                  `--max-count=1`, path-qualified or not) and `head`, which
                  has no draining form at all. It exits early, which closes
                  the pipe while the writer is still filling it; the writer
                  takes SIGPIPE and `set -o pipefail` hands back 141 instead
                  of grep's 0, so a marker that is present reads as missing.
                  Load-dependent and invisible on inspection. The flake counts
                  this row used to quote are a dated one-time measurement that
                  nothing re-establishes, and they now live in the fragment's
                  own header labelled as such rather than here as fact. What
                  IS re-established every run is the matcher itself, against a
                  table of banned spellings it must catch and a table of
                  prescribed safe forms it must not. The check skips a line
                  whose first non-blank character starts a comment, so the
                  comments that document the trap survive it. ONE ID AND NOT A
                  RANGE, for the reason the 83, 98 and 99 rows give: this
                  fragment declares exactly one check and a range endpoint
                  would assert a maximum it does not have
  85-design-spec-conformance.sh, check [85], design-spec catalog conformance
                  (contract + WCAG AA contrast)
  86-skill-command-namespace.sh, check [86], every slash command written in
                  prose is read from both ends: a namespaced `/hackify:<name>`
                  must name a real skills/<name>/SKILL.md or commands/<name>.md,
                  and a skill that exists must never be advertised in the bare
                  un-namespaced spelling. The second half is the load-bearing
                  one: this sprint renamed the codewalk command across 25
                  sites, every one of them bare, so a resolution-only check
                  would have seen no token at all and printed green over the
                  lot. THE ROSTER IS TWO DIRECTORIES, discovered per run rather
                  than listed, because designify and summary ship as command
                  bodies with no skill directory. CHANGELOG.md and docs/work/
                  are excluded as frozen records and the fragment argues both
                  in its own header rather than leaving the exclusion silent.
                  ONE ID AND NOT A RANGE, for the reason the 83, 98 and 99 rows
                  give: this fragment declares exactly one check and a range
                  endpoint would assert a maximum it does not have
  87-agent-roster-rows.sh, check [87], the dispatch roster in parallel-agents/
                  README.md is read from both ends against agents/: every row
                  names a type an agent file DECLARES in its frontmatter and a
                  template that exists, and every registered agent carries
                  exactly one row. The table is what a dispatcher reads instead
                  of opening a template, and a live type swapped for a literal
                  in it shipped a full green bar, so a misrouted panel had
                  nothing standing in front of it. ONE ID AND NOT A RANGE, for
                  the reason the 83, 98 and 99 rows give: this fragment declares
                  exactly one check and a range endpoint would assert a maximum
                  it does not have
  88-plugin-map.sh, check [88], the orientation map rules/plugin-map.md read
                  from both ends against the tree it describes. The map is
                  injected once per session by the SessionStart hook and is
                  the only thing that tells a fresh session which entry points
                  exist, so a stale row misroutes a user for a whole session.
                  RESOLUTION: every `/hackify:<name>` row names a real
                  skills/<name>/SKILL.md or commands/<name>.md, and every
                  `rules/<name>.md` row names a file that exists AND is wired
                  on the UserPromptSubmit chain. COVERAGE: every entry point
                  the tree ships carries exactly one row, discovered per run
                  from skills/, commands/ and hooks.json rather than from a
                  hand-written list. Coverage is the load-bearing half, since
                  it is the direction that rots on EXTENSION: a skill added
                  next month with no row leaves the resolution half nothing to
                  resolve and printing green. The plant control tampers one
                  command row and one rule row and requires all four owed
                  reds, two per direction, so a resolution-only regression
                  cannot pass it. ONE ID AND NOT A RANGE, for the reason the
                  83, 86, 98 and 99 rows give: this fragment declares exactly
                  one check and a range endpoint would assert a maximum it
                  does not have
  89-reviewer-rename.sh, check [89], the 0.18.0 Phase 5 reviewer rename pinned
                  from both ends. All six reviewer agents became one family
                  when the merged all-lens reviewer became the default route
                  and the word "merged" stopped meaning anything, so all six
                  moved onto the `reviewer` stem: reviewer, reviewer-security,
                  reviewer-quality-plan, reviewer-performance,
                  reviewer-coherence and reviewer-design, filenames with them.
                  THE SIX OLD NAMES ARE NOT WRITTEN HERE, on the rule
                  parallel-agents/README.md follows at its own retirement note:
                  [89] bans them from every live file and this one is live, so
                  naming them would red the manifest row describing the check
                  that reds it. An agent type resolves at DISPATCH time,
                  so a half-applied rename ships a full green bar and fails in
                  a user's session, which is the [40] incident one rename
                  later. PRESENT: the backticked live type at all 8 dispatch
                  sites, the 5 panel-lens types in the roster, and the 6
                  definition files on disk. ABSENT: all 6 dead names over the
                  whole tree minus dist/, docs/work/, CHANGELOG.md and this
                  fragment, each row argued at the block. The scan reads
                  UNTRACKED files too, which [40] does not and which this
                  rename needed, and it does NOT read the index, which [40]
                  does and which would red for the whole pre-commit window a
                  rename lives in. Both divergences are measured at the block.
                  ONE ID AND NOT A RANGE, for the reason the 83, 86, 87, 88, 98
                  and 99 rows give: this fragment declares exactly one check
                  and a range endpoint would assert a maximum it does not have
  90-collisions.sh, check [90], sibling-plugin slug collision (soft)
  91-claim-resolvers.sh, check [91], every 'check [NN]' claim in a live file
                  resolves to a check id the validator actually declares, so a
                  doc cannot cite a check that was never written
  92-work-doc-structure.sh, check [92], no work-doc under docs/work/, tracked or not,
                  numbers two sections the same and its numbered sections only go up, so
                  a second '## 6. Daily Updates' or a spliced-in Sprint Backlog cannot
                  sit in the source of truth a sprint resumes from. Keyed on the section
                  NUMBER and never on the heading text, because both duplicates this
                  repo has shipped carried trailing prose and an equality check
                  separates those happily
  93-token-declarations.sh, check [93], every {{token}} used in a sub-agent
                  prompt is declared by that prompt's own INPUTS list, so a
                  dispatch cannot be asked to fill a placeholder nothing names
  94-section-exists.sh, check [94], every instruction naming a work-doc
                  section names one the template's headings actually declare,
                  so a doc cannot send a writer to a section that was retired
  95-literal-absent-claims.sh, check [95], every claim that a quoted phrase is
                  not pinned is checked by looking the phrase up, so a comment
                  cannot call a literal unpinned while another fragment bans it
  96-review-scope-sites.sh, checks [76g]-[76h], the docs/work/ exclusion on
                  the reviewed diff, and the FULL-round gate wording stated
                  identically at every site that states it plus Reviewer B's
                  round marker, both over a file set the check DISCOVERS
                  rather than lists. Split out of 76 at the 500-LOC cap, IDs
                  and all
  97-test-suites-reachable.sh, check [97], every tracked test suite is
                  reachable from .github/workflows/ci.yml, either named by a
                  step directly or imported by a file that is, so a suite
                  cannot sit green-on-demand and absent from every automated
                  run. Same shape as [0] one layer up: [0] catches a fragment
                  nothing sources, this catches a suite nothing runs
  98-work-doc-ledger-sync.sh, check [98], an archived work-doc closes every row
                  of its section 0 phase ledger, and an archived doc created on
                  or after the day section 0 became a work-doc section carries
                  that block at all, so deleting the block is not a way to turn
                  a red green. ONE ID AND NOT A RANGE, because this fragment
                  declares exactly one check and a range endpoint would assert a
                  maximum it does not have
  99-work-doc-status-claims.sh, check [99], every work-doc's frontmatter status, tracked
                  or not, is one the template's own row declares, and a doc outside
                  done/ does not claim it was finished. Split out of 98 at the 500-LOC
                  cap, where the created-date rule above would not fit. THE ASSERTION
                  LETTERS (a) AND (c) MOVED WITH THE BLOCKS while the id did not: [98]
                  is a single check, its CHANGELOG entry binds that id to
                  98-work-doc-ledger-sync.sh by name, and phase-ledger.md cites
                  assertion (c) by letter. That entry is cited by NAME and not by line
                  on purpose: the first version of this comment cited a line, the entry
                  was rewritten one commit later, and the citation went stale while [57]
                  stayed green. [57]'s content tier reads a cited location only where
                  the citing text quotes a phrase behind a verb, or where the location
                  has gone vacant; an unpinned number, which is nearly every citation in
                  this tree, is still judged for existence alone, and [57]'s own
                  coverage line prints the live split. ONE ID AND NOT A RANGE, for 98's
                  reason
````

## How the 71 and 72 rows above went wrong at once

HOW THE 71 AND 72 ROWS ABOVE WENT WRONG AT ONCE, recorded here rather than in
either row because it is a property of the row FORMAT and not of those two
fragments. Both were written as a single range and both had the right
endpoints: 71 read [38c]-[38g] while declaring no [38e], and 72 read
[38e]-[38h] while declaring neither [38f] nor [38g]. [76i] compares a row's
range endpoints against the fragment's lowest and highest declared check, so
it read both rows and agreed with both. What no endpoint comparison can be
asked about is the ids in the MIDDLE of a run, which is where both errors sat,
and a reader looking up [38e] was sent to 71 where it does not exist. Set
membership in both directions, every id a row names is declared by that
fragment and every id that fragment declares is named by that row, is the
rule that reaches them; it is [76i]'s to widen and is not bought here.

## What check [41] deliberately does not enforce

Arguments a maintainer needs once, not rules that fragment re-applies; its header points here.

WHAT A GATED TEMPLATE MAY VARY AND WHAT IT MAY NOT. `phase-5-multi-review-merged.md` runs five
GATED passes and binds each entry to a named pass rather than to METHOD step 1, because loading
fifteen lens files up front would destroy the gating and the low-cost premise that is that
reviewer's reason to exist. Contract-legal, so [41] asserts on neither paragraph 1's WORDING nor
an entry's clause; it pins the four invariants holding across EVERY template instead, and a
control plants a pass-bound entry and requires it to PASS, proving the tolerance every run.

TWO RULES [41] DELIBERATELY DOES NOT ENFORCE, both because enforcing them would rebuild the
author's-vantage blind spot in a new place. A BARE PATH INSIDE THE LIST IS NOT SCREENED AS SUCH:
assertion (d) is the POSITIVE form, so an entry written `rules/foo.md` fails it for want of an
anchored path, while the NEGATIVE form, banning unanchored backticked paths from the list body,
was written and withdrawn. The Phase 2.5 spec reviewer legitimately names the PROJECT's
`CLAUDE.md` unanchored, which the contract prescribes for files no plugin anchor reaches, and
screening on "does the name resolve from the repo root" would RED on that entry today, this repo
having since gained a root `CLAUDE.md` — the author's-vantage error exactly. One live instance. And (h) IS THE ANCHORED HALF OF THE DANGLING RULE AND NOT THE WHOLE
RULE: the contract bans citing any plugin file absent from the list, so an anchored citation is
unambiguously such a file and is enforced, while a BARE one is not, telling a plugin file from
one of the user's needing judgment no matcher has. Measured over the live corpus, the only two
bare citations resolving from this repo root are both `CHANGELOG.md` in a reviewer prompt,
correctly meaning the USER's; reddening on those cries wolf on run one, so the honest partial ships.

## Two checks do not live in a fragment

`[0]`, the wiring guard that requires the fragment directory and the source list
to agree in both directions, and `[0b]`, the floor on the run's own ok-line
total, are written out in `scripts/validate-dod.sh` itself rather than here or
in a fragment. A check that guards the source list cannot be reached through the
source list. The comment above each one in that file gives the full argument.
