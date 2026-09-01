# shellcheck shell=bash

# ---------------------------------------------------------------------------
# THROUGHPUT AND ROUTING PINS. Seven blocks, six per doctrine change the
# throughput-and-quick-default sprint landed and one for the sibling-track rules
# the round after it repaired, each guarding that change against its own rot.
#
# THE SEAM IS THE SAME ONE 71 DRAWS, POINTED THE OTHER WAY. 71 guards a shipped
# SAVING against its guard rail drifting out while the prose promising the
# saving stays. This file guards a shipped DECISION against the wording it
# REPLACED creeping back in. Different failure, identical symptom: the prose
# reads fine, nothing reddens, and the workflow quietly runs the retired shape
# again. So six of the seven blocks are two-sided, a pin on the live claim and a
# ban on the dead one, because a pin alone goes green on a file that carries
# both at once. That is not hypothetical here: the sprint that landed these
# changes left a retired "three stages" sentence alive in a file no wave owned,
# and every check in the tree stayed green over it.
#
# WHY A NEW FRAGMENT AND NOT LINES IN 71. 71 sits at 471 lines against the
# 500-LOC cap [80] enforces, so it has room for neither these blocks nor the
# comments that make them readable. The [38f] pin this file's last block mirrors
# stays where it is for the same reason 71's own header gives about check ids: a
# block is free to move, and one already cited from a work-doc is cheaper left
# alone. The two files stay independently reviewable, which is what the task
# that ordered this fragment asked for.
#
# THE NUMBER IN THE FILENAME IS NOT COSMETIC. This was specified as `79b-` and
# could not be: [0] in scripts/validate-dod.sh, and [76f] and [76i] in
# 76-phase-ledger-substrate.sh, all parse a fragment name with `[0-9]+-`, which
# needs digits followed immediately by a hyphen. `79b-` has none, so the source
# line would parse to nothing, [0] would report this file as sitting on disk
# unsourced, and the header row would never be compared. Measured with the
# actual regex before the file was named. A letter suffix is safe in a CHECK id
# and unsafe in a FRAGMENT name, and only the fragment name is read by a matcher.

TR_CONTENTION="skills/hackify/references/contention-dispatch.md"
TR_P3="skills/hackify/references/phases/phase-3-implement.md"
TR_P3_TPL="skills/hackify/references/parallel-agents/phase-3-implementation.md"
TR_HACKIFY="skills/hackify/SKILL.md"
TR_QUICK="skills/quick/SKILL.md"
TR_WORK_DOC_TPL="skills/hackify/references/work-doc-template.md"
TR_SIBLING="skills/hackify/references/sibling-track-rules.md"

# ---------------------------------------------------------------------------
yellow "[82] the dispatch budget is stated as digits in one file and named everywhere else"
# Two numbers size a Phase 3 round, the per-agent task budget and the
# concurrent-wave budget. Both are stated as digits in contention-dispatch.md
# and NOWHERE else, so changing either is one edit rather than a sweep that
# misses a site. A restated digit is worse than a missing one: the sweep that
# misses a file leaves two numbers in the tree, both plausible, and the reader
# who finds the stale one has no way to tell which is current.
#
# BOTH HALVES OR NEITHER. Pinning only the digits lets a copy appear elsewhere;
# banning only the copies lets the canonical statement be deleted and the whole
# rule evaporate with nothing left to violate.
#
# HOW THE BARE-NUMBER TRAP IS AVOIDED, because a first draft of this block dies
# on it. The ten consumer files carry the characters `10` and `20` in bulk and
# legitimately: line citations, version strings, numbered list markers, ordinary
# counts of anything. A ban keyed to the digits alone would red on all of them
# and be deleted by whoever hit it next, which leaves the rule worse guarded
# than no check at all. So every banned token pairs the number with the BUDGET
# NOUN it must carry to be a budget CLAIM at all, in digits and spelled out. All
# eleven were measured against the ten files below first and all eleven return
# zero, so each one reddens on a reintroduction and on nothing that is there today.
#
# THE DIGIT FORMS WERE THE HOLE, AND THEY ARE THE FORM THIS BLOCK EXISTS TO STOP.
# The first nine banned `twenty Sprint Backlog` and not `20 Sprint Backlog`, and
# `10 waves` and not `10 concurrent waves`, which left the spelled-out wording
# guarded and the digits, the way anyone actually writes a budget, open. A reviewer
# inserted "Dispatch at most 20 Sprint Backlog tasks per agent, and run 10
# concurrent waves." into the middle of agents/implementer.md and the whole bar
# stayed green over it. Both forms are banned now, and the two additions still pair
# a number with a budget NOUN, so neither reaches an ordinary count.
TR_BUDGET_BANS=('20 tasks' 'twenty tasks' 'twenty Sprint Backlog' '20 Sprint Backlog')
TR_BUDGET_BANS+=('10 waves' 'ten waves' '10 concurrent waves')
TR_BUDGET_BANS+=('budget: 20' 'budget: 10' 'budget of 20' 'budget of 10')
check_list_size "${#TR_BUDGET_BANS[@]}" 11 "the [82] restated-budget ban list"

# The canonical statement, in digits, in the one file that is allowed to carry it.
check_token_present 'Per-agent task budget: 20 tasks' "$TR_CONTENTION"
check_token_present 'Concurrent-wave budget: 10 waves' "$TR_CONTENTION"

# The consumers, and the screen is now every file outside docs/ that names a
# budget rather than the five somebody listed by hand. THE UNDER-SCOPING WAS THE
# DEFECT: eleven shipped files name a budget and five were screened, so six could
# restate one with nothing red behind them. The list is still written out rather
# than discovered, for the reason 30-inventory-pins.sh gives about bounds derived
# from the thing they police, and check_list_size is what makes a silent deletion
# from it impossible. Re-derive it with:
#   /usr/bin/grep -rlFiI -- 'per-agent task budget' \
#     skills agents rules commands README.md
# minus contention-dispatch.md, which is the canonical site and must carry the
# digits this list bans.
#
# AND THE RECIPE WAS RUN AGAIN, because the wave that wrote "eleven" screened ten:
# work-doc-template.md names the budget, was on nobody's list, and is the file every
# work-doc is copied from. Twelve paths back, minus the canonical one, is eleven.
TR_BUDGET_CONSUMERS=("$TR_P3" "$TR_P3_TPL" "agents/implementer.md")
TR_BUDGET_CONSUMERS+=("skills/hackify/references/parallel-agents/README.md" "$TR_QUICK")
TR_BUDGET_CONSUMERS+=("$TR_HACKIFY" "agents/spec-reviewer.md" "README.md")
TR_BUDGET_CONSUMERS+=("skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md")
TR_BUDGET_CONSUMERS+=("skills/quick/evals/evals.json" "$TR_WORK_DOC_TPL")
check_list_size "${#TR_BUDGET_CONSUMERS[@]}" 11 "the [82] budget-consumer file list"
for tr_f in "${TR_BUDGET_CONSUMERS[@]}"; do
  check_token_present 'per-agent task budget' "$tr_f"
  check_no_flowed_tokens_in "$tr_f" "${TR_BUDGET_BANS[@]}"
done

# BOTH BUDGET NAMES, AND THE SECOND ONE HAD NEVER BEEN CHECKED ANYWHERE. The
# paragraph above this loop used to say every consumer "must NAME both budgets and
# restate neither" while the loop asked only for `per-agent task budget`, so the
# stated intent and the shipped check disagreed and the disagreement was invisible:
# a consumer could drop `concurrent-wave budget` entirely and go quiet rather than
# go wrong, which is the exact failure the by-name pin exists to catch on the other
# budget.
#
# EIGHT OF THE ELEVEN, AND THE THREE ABSENTEES ARE NAMED RATHER THAN ROUNDED AWAY.
# skills/hackify/references/parallel-agents/phase-3-implementation.md,
# agents/implementer.md and work-doc-template.md carry zero occurrences of
# `concurrent-wave budget` today, measured, so pinning it across all eleven would
# ship a red on a healthy tree. Those three owe the reference; until then this list
# is the honest scope, a file that has the name cannot lose it silently, and moving
# a file onto this list is a diff rather than a claim with nothing behind it.
TR_WAVE_BUDGET_CONSUMERS=("$TR_P3" "skills/hackify/references/parallel-agents/README.md")
TR_WAVE_BUDGET_CONSUMERS+=("$TR_QUICK" "$TR_HACKIFY" "agents/spec-reviewer.md")
TR_WAVE_BUDGET_CONSUMERS+=("README.md" "skills/quick/evals/evals.json")
TR_WAVE_BUDGET_CONSUMERS+=("skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md")
check_list_size "${#TR_WAVE_BUDGET_CONSUMERS[@]}" 8 "the [82] concurrent-wave-budget consumer list"
for tr_f in "${TR_WAVE_BUDGET_CONSUMERS[@]}"; do
  check_token_present 'concurrent-wave budget' "$tr_f"
done

# ---------------------------------------------------------------------------
yellow "[82b] Phase 3 runs FOUR stages, and the fourth is the testing wave"
# The testing wave was added as a fourth stage after the assembly wave, and it
# is where every watched red and every named mutation now lives. A file that
# still says three stages is not merely stale, it actively instructs a
# dispatcher to finish the round one stage early with the tests never authored.
#
# FOUR FILES AND NOT THE TREE. These four are the ones a dispatcher and a
# work-doc author actually read to decide the shape of a round. Widening the ban
# to every file that mentions a stage count would reach prose that is describing
# history rather than instructing, and this check has no way to tell those apart.
#
# THE TEMPLATE JOINED LATE, AND THAT IS THE WHOLE POINT OF THE LIST BEING
# HAND-WRITTEN. It was held out of the first version of this block because it
# still carried the defect the block bans, so adding it then would have shipped a
# red. The task that fixed the sentence added the file here in the same change,
# which is the only order that leaves no window where the file is fixed and
# unguarded.
TR_STAGE_FILES=("$TR_CONTENTION" "$TR_P3" "$TR_HACKIFY" "$TR_WORK_DOC_TPL")
check_list_size "${#TR_STAGE_FILES[@]}" 4 "the [82b] stage-count file list"
for tr_f in "${TR_STAGE_FILES[@]}"; do
  check_no_flowed_token 'three stages' "$tr_f"
  check_token_present 'testing wave' "$tr_f"
done
# The count itself, pinned per file at the case each one actually writes.
# check_token_present is case-sensitive, and folding the case here would hide a
# file that stopped stating a count at all behind a neighbour that still does.
check_token_present 'four stages' "$TR_CONTENTION"
check_token_present 'four stages' "$TR_P3"
check_token_present 'Four stages' "$TR_HACKIFY"
check_token_present 'four stages' "$TR_WORK_DOC_TPL"

# THE FOURTH STAGE IS NOT AUTOMATICALLY SOLO, and that half had no pin at all.
# A testing stage splits under the same partition test as every other stage, so
# its waves read sibling-track-rules.md exactly as a module track does; the
# retired shape said the testing wave always ran alone, which sends a split
# testing wave into a shared tree with none of those rules loaded. The ban on
# `solo testing wave` is in [82c]'s batched screen over the same documents.
#
# check_flowed_token_present, NOT check_token_present, and this is the whole
# reason that helper exists. Both sentences are wrapped across two physical lines
# in the file that carries them, so every line-oriented matcher in this validator
# returns zero on a file that says exactly what it is being asked about. Measured
# before this block was written: `/usr/bin/grep -F` for either phrase in
# sibling-track-rules.md returns nothing, and the flattened form finds both.
check_flowed_tokens_present_in "$TR_SIBLING" \
  'a testing stage that runs as one wave' \
  'A testing stage that SPLITS is not on that list'

# ---------------------------------------------------------------------------
yellow "[82c] the work-doc is updated per RETURNING AGENT, not once at round end"
# A round packed to the concurrent-wave budget that dies after its sixth return
# used to leave a work-doc naming nothing, because nothing was written until
# every agent was in. The unit moved to one returning agent. The rot this
# guards is a revert to the batched cadence, which costs nothing visible on a
# round that completes and loses the whole round's progress on one that does
# not.
#
# THE BAN IS THE OPENING OF THE SENTENCE THAT WAS REPLACED. "Before dispatching
# round N+1" was the head of the old Wave-end persistence rule. Keying the ban on
# a general phrase about rounds would reach the many correct sentences these files
# write about round-level gates, which genuinely do still run at round end.
#
# SIX MORE RETIRED WORDINGS JOINED IT, AND THE TICK CADENCE IS WHY. The rule that
# replaced them is that a task ticks as its wave lands and the ledger is written
# before the round commits, never before a tick and never as an un-tick. Every
# banned wording below says the opposite, and each was measured at zero across the
# nine files first, so each reddens on a revert and on nothing there today.
#
# `solo testing wave` is banned with them rather than in check [83], because it is
# the same class of defect and the same nine files: a retired shape whose return
# costs nothing visible. It belongs to the stage-shape rule check [83] pins, and it
# is screened HERE only because one batched screen over one file list is cheaper
# than two, which is the trade check_no_flowed_tokens_in exists to make.
TR_CADENCE_BANS=('before ticking any task' 'BEFORE anything ticks')
TR_CADENCE_BANS+=('before ticking anything' 'before tasks tick')
TR_CADENCE_BANS+=('tasks tick at round end' 'Before dispatching round N+1')
TR_CADENCE_BANS+=('solo testing wave')
check_list_size "${#TR_CADENCE_BANS[@]}" 7 "the [82c] retired-cadence ban list"

# NINE FILES, UP FROM TWO. The cadence rule is read by every agent that ticks a
# task or writes the ledger, not only by the two documents that state it, and a
# retired wording restored in a scout protocol instructs exactly as loudly as one
# restored in the dispatch doc. The two originals stay first in the list.
TR_RETURN_FILES=("$TR_CONTENTION" "$TR_P3" "$TR_HACKIFY")
TR_RETURN_FILES+=("skills/hackify/references/implement-and-test.md" "$TR_P3_TPL")
TR_RETURN_FILES+=("skills/hackify/references/law-scout.md")
TR_RETURN_FILES+=("skills/hackify/references/perf-scout.md")
TR_RETURN_FILES+=("$TR_SIBLING" "$TR_WORK_DOC_TPL")
check_list_size "${#TR_RETURN_FILES[@]}" 9 "the [82c] per-return cadence file list"
for tr_f in "${TR_RETURN_FILES[@]}"; do
  check_no_flowed_tokens_in "$tr_f" "${TR_CADENCE_BANS[@]}"
done
check_token_present 'ONE RETURNING AGENT' "$TR_P3"
check_token_present 'As EACH agent returns' "$TR_P3"
check_token_present 'as that track returns' "$TR_CONTENTION"
check_token_present 'per-return merge' "$TR_CONTENTION"

# THE LIVE CADENCE SENTENCE, PINNED WHERE IT ACTUALLY IS AND NOWHERE ELSE. These
# two literals are the positive half of the ban list above: they say when the
# ledger is written and that a tick is never taken back. Five files carry both,
# measured, and the pin list is those five.
#
# THE FOUR FILES DELIBERATELY LEFT OUT, so the gap is on the record rather than an
# oversight. contention-dispatch.md and phase-3-implement.md state the cadence in
# the per-return wording pinned just above. sibling-track-rules.md and
# work-doc-template.md are screened by the ban list and state no cadence of their
# own. agents/implementer.md was CHECKED and is not here: its tail carries no
# cadence sentence, so pinning these literals on it would red on a healthy tree.
TR_TICK_PINS=("$TR_HACKIFY" "skills/hackify/references/implement-and-test.md")
TR_TICK_PINS+=("$TR_P3_TPL" "skills/hackify/references/law-scout.md")
TR_TICK_PINS+=("skills/hackify/references/perf-scout.md")
check_list_size "${#TR_TICK_PINS[@]}" 5 "the [82c] tick-cadence pin file list"
for tr_f in "${TR_TICK_PINS[@]}"; do
  check_token_present 'before the round commits, never before a tick' "$tr_f"
  check_token_present 'never an un-tick' "$tr_f"
done

# ---------------------------------------------------------------------------
yellow "[82d] quick is the default route and full hackify never auto-fires"
# Routing was inverted: quick takes every substantive prompt and full mode is
# reached only when the user names it. Two things can quietly put the old router
# back, and neither would fail any other check in this repo.
#
# FIRST, an auto-escalation list in quick. A "When NOT to use quick mode"
# section is how the old routing was written, and re-adding one hands the
# decision back to a keyword match on the prompt. Quick is user-locked, so there
# is no such list, and the heading is banned rather than argued with.
#
# SECOND, and this is the one the assembly wave asked for by name, the hackify
# frontmatter `description:` is what the harness reads to decide whether to fire
# the skill at all. It is one very long line, it is edited by hand, and a single
# clause restored to it re-arms auto-firing with no other file changing. Nothing
# was watching it.
#
# SCOPED TO THE DESCRIPTION LINE, NOT THE FILE. The body of SKILL.md discusses
# routing at length and must stay free to. Only the frontmatter line is the
# harness's input, so only the frontmatter line is judged, and the emptiness
# guard below is what stops a reformatted frontmatter turning this into a check
# over an empty string that can no longer fail.
check_no_flowed_token 'When NOT to use quick mode' "$TR_QUICK"
check_no_flowed_token '## When NOT to use' "$TR_QUICK"
check_token_present 'The default route for any substantive prompt' "$TR_QUICK"

TR_DESC_PINS=('THE EXPLICITLY-REQUESTED ROUTE, never the automatic one')
TR_DESC_PINS+=('Do NOT auto-fire on a build verb')
TR_DESC_PINS+=('do NOT auto-fire on the surface an ask touches')
TR_DESC_PINS+=('lands in /hackify:quick, the default route')
check_list_size "${#TR_DESC_PINS[@]}" 4 "the [82d] non-auto-firing description pin list"
TR_DESC_BANS=('auto-fires on' 'Invoke even when the user does not say')
TR_DESC_BANS+=('When in doubt, invoke this skill' 'escalation to full ceremony is free')
check_list_size "${#TR_DESC_BANS[@]}" 4 "the [82d] auto-firing description ban list"

tr_desc=$(awk 'NR <= 10 && /^description:/ {print; exit}' "$TR_HACKIFY")
if [ -z "$tr_desc" ]; then
  red "  FAIL no 'description:' line was found in the first 10 lines of $TR_HACKIFY, so the routing pins below were never applied to anything"
  FAILED=$((FAILED + 1))
else
  for tr_tok in "${TR_DESC_PINS[@]}"; do
    if grep -qF -- "$tr_tok" <<<"$tr_desc"; then
      green "  ok   '$tr_tok' present in $TR_HACKIFY frontmatter description"
    else
      red "  FAIL '$tr_tok' missing from $TR_HACKIFY frontmatter description, so full mode no longer states that it is the explicitly-requested route"
      FAILED=$((FAILED + 1))
    fi
  done
  # /usr/bin/grep by absolute path on the BAN side only, on the rule
  # 00-helpers.sh states above check_no_token: pin the matcher where a shell
  # wrapper would buy a false PASS, and leave it bare where it would only buy a
  # false alarm. The pins above are the false-alarm side.
  for tr_tok in "${TR_DESC_BANS[@]}"; do
    if /usr/bin/grep -qiF -- "$tr_tok" <<<"$tr_desc"; then
      red "  FAIL '$tr_tok' is back in $TR_HACKIFY frontmatter description, which re-arms auto-firing and takes routing away from the user"
      FAILED=$((FAILED + 1))
    else
      green "  ok   '$tr_tok' has 0 occurrences in $TR_HACKIFY frontmatter description"
    fi
  done
fi

# ---------------------------------------------------------------------------
yellow "[82e] the test_mode enum is settled: test-authoring lives, test-first is gone"
# Implementation waves author no tests at all now; the testing stage does,
# under test_mode `test-authoring`. `test-first` was the mode the implementation
# waves used to carry and it is retired from the enum.
#
# THIS IS A COHERENCE DEFECT THAT ALREADY HAPPENED. Two tracks running blind to
# each other left the two halves of one enum disagreeing, and it took a reader
# comparing the files by hand to find it. A dead enum value is uniquely cheap to
# reintroduce, because a dispatcher writing `test_mode: test-first` gets a
# perfectly plausible-looking brief and an implementer that authors tests the
# testing wave will author again.
#
# THE ABSENCE IS ONLY AS GOOD AS THE SCOPE, so the scope is named rather than
# assumed: five roots, every one of them shipped content. docs/ and dist/ are
# deliberately outside it. Archived work-docs record what the old enum said and
# must keep saying so, and dist/ is generated from these same roots, so [56]
# already proves it matches byte for byte.
TR_ENUM_SCOPES=('skills' 'agents' 'rules' 'commands' 'README.md')
check_list_size "${#TR_ENUM_SCOPES[@]}" 5 "the [82e] retired-test-mode scan scope"
for tr_f in "${TR_ENUM_SCOPES[@]}"; do
  check_no_token 'test-first' "$tr_f"
done
check_token_present 'test-authoring' "$TR_P3_TPL"
check_token_present 'test-authoring' "agents/implementer.md"
check_token_present 'test-authoring' "skills/hackify/references/implement-and-test.md"

# ---------------------------------------------------------------------------
yellow "[82f] {{concurrent_wave_target}} is declared on both spec-reviewer copies"
# Same discipline as [38f]'s pin on `{{wave_size_target}}`, and the same two
# files, because the spec reviewer ships twice: agents/spec-reviewer.md is the
# copy Claude Code registers and actually runs, and the parallel-agents template
# is the copy every other runtime dispatches from. The pair has drifted before,
# with the registered copy behind the template and the docs describing the
# template, so a reviewer was running without a step everyone believed it had.
#
# The token is what a dispatcher substitutes to cap how many waves a round runs
# at once. A copy that loses it does not error, it just packs every round to
# whatever the agent guesses, which is the same silent loss of a ceiling that
# [82] guards from the other end.
TR_SPEC_REVIEWERS=("agents/spec-reviewer.md")
TR_SPEC_REVIEWERS+=("skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md")
check_list_size "${#TR_SPEC_REVIEWERS[@]}" 2 "the [82f] spec-reviewer copy list"
for tr_f in "${TR_SPEC_REVIEWERS[@]}"; do
  check_token_present '{{concurrent_wave_target}}' "$tr_f"
done

# ---------------------------------------------------------------------------
yellow "[82g] the sibling-track rules are pinned, and the new 'none' branch did not soften the shared-database ban"
# NOTHING HAS EVER READ THIS FILE. skills/hackify/references/sibling-track-rules.md
# governs every concurrent dispatch Phase 3 makes, and until this block
# `grep -rn sibling-track scripts/validate-dod.d/` returned zero rows across the
# whole validator. That absence is the reason the two defects this round fixed in
# it survived five separate tracks reporting them: five readers found them and no
# check did, and a defect with nothing red behind it just waits for the next
# reader to find it again.
#
# FIVE PINS, ON THE FIVE THINGS THAT ROT SEPARATELY, and this said FOUR while five
# shipped. Each names its target by line, and that number is A READING AID AND
# NOTHING MORE: scripts/check_doc_links.py resolves a `path:line` by asking whether
# the file HAS that line, never whether it still says what the pointer claims, so
# four anchors below were stale and nothing reddened. Re-resolved, not carried over.

# PIN 1, THE DATABASE GATE'S REFUSAL PATTERN, TWO-SIDED. The live `case` at
# skills/hackify/references/sibling-track-rules.md:216-220 refuses an EMPTY or
# still-templated value and lets `none` fall through to the tree search below it.
# The retired form refused on the literal word `none` as well, which made every
# concurrent dispatch in a database-free repo a dispatch to refuse.
#
# WHY BOTH SIDES AND NOT JUST THE PIN. The pin alone goes green on a file
# carrying the live case AND the dead one, which is exactly the trap this
# fragment's own header describes: an editor restoring the old pattern beside the
# new one leaves both on disk, the reader sees a plausible refusal either way,
# and nothing reddens. The ban is what makes the two mutually exclusive.
#
# THE TREE SEARCH IS PINNED SEPARATELY FROM THE CASE, because they fail apart. A
# `case` that stops refusing is a gate that accepts a blank line; a search that is
# deleted is a gate that believes `none` instead of checking it. Deleting the
# search is the cheaper and likelier edit of the two, since it is the half that
# costs a track real work.
TR_SIB_DB_BANS=("''|none|*'{{'*" 'no per-track database reached')
check_list_size "${#TR_SIB_DB_BANS[@]}" 2 "the [82g] retired database-refusal ban list"
check_no_flowed_tokens_in "$TR_SIBLING" "${TR_SIB_DB_BANS[@]}"
check_token_present "''|*'{{'*|*'<the database_name'*)" "$TR_SIBLING"
check_token_present 'FAIL: no database decision reached this track' "$TR_SIBLING"
check_token_present "database_name is 'none' but this project has a database" "$TR_SIBLING"
check_token_present 'VERIFIED against the tree' "$TR_SIBLING"

# PIN 2, THE VERIFICATION DUTY, at
# skills/hackify/references/sibling-track-rules.md:59. Relaxing a gate and
# deleting a gate look identical one edit later, so the sentence that makes `none`
# a value you CHECK rather than a value you accept is pinned on its own. Pin 1
# guards the shell that discharges the duty; this guards the prose that imposes
# it, and an agent reads the prose.
#
# THE SECOND TOKEN IS THE HALF THAT KEEPS THE CHECK FALSIFIABLE. A search whose
# hits may be waved through unread is a search that always comes back clean, so
# the "a path you rule out is a path you OPENED" rule is not decoration on the
# duty, it is the duty. Dropped, the gate still runs and still cannot fail.
check_token_present 'is the one value you verify instead of refusing' "$TR_SIBLING"
check_token_present 'a path you rule out is a path you' "$TR_SIBLING"

# PIN 3, THE ALLOWLIST RECONCILIATION, ON BOTH SIDES. A concurrent track is
# ordered to write `docs/work/<slug>.tracks/<track_id>.md` and is also bound by an
# allowlist that is absolute. Those are two contradictory orders unless the
# dispatcher puts that path in the list, and the fix had to land in both files.
# Each side is cited by the sentence it added rather than by a line number:
#   sibling-track-rules.md's "that path IS in your file allowlist"
#   contention-dispatch.md's "the dispatcher puts that file in the track's allowlist"
#
# BOTH SIDES WERE ONCE CITED BY NUMBER AND BOTH NUMBERS WENT STALE, which is worth
# more than the fix: a paragraph moving down a file takes its citation with it, and
# the track's side had drifted onto a blank line by the time this was rewritten.
# Numbered here means stale again next edit, and the round that edits this block
# edits the file it cites. The tokens below are the enforced anchors.
#
# ONLY A PAIR WORKS HERE. Pinning one side lets the other be deleted, and the
# contradiction is back with a green validator over it, because each surviving
# half reads perfectly well alone. The recorded cost of that contradiction is one
# round where five tracks split two ways on the same rule, two writing the file
# and three refusing, with no error at either end to say which was right.
#
# NO BAN SIDE, DELIBERATELY, and that is a departure from the two-sided shape the
# rest of this fragment uses. The defect here was an ABSENCE, not a retired
# wording that could creep back: neither file previously said anything wrong
# about the allowlist, they simply said nothing. There is no dead token to ban,
# and inventing one would be a check that can never fail.
check_token_present 'that path IS in your file allowlist' "$TR_SIBLING"
check_token_present "the dispatcher puts that file in the track's allowlist" "$TR_CONTENTION"
check_token_present 'a concurrent dispatch whose allowlist' "$TR_CONTENTION"

# PIN 4, THE ABSOLUTE SHARED-DATABASE BAN at
# skills/hackify/references/sibling-track-rules.md:46-51. This one was not asked
# for and belongs anyway. Pins 1 and 2 both guard a RELAXATION, and a relaxation
# guarded while the rule it relaxes is not is how the next editor reads the new
# `none` branch as permission to touch the shared database when a track has no
# database of its own. It is not: `none` asserts the project has NO database, and
# the ban on the shared one is untouched above it.
#
# The section heading is pinned alongside the sentences because deleting a whole
# section is a likelier edit than rewording one line inside it, and a heading is
# the cheapest thing to notice missing.
check_token_present '## Your own database, never the shared one' "$TR_SIBLING"
check_token_present 'Never touch the shared one' "$TR_SIBLING"
check_token_present 'nothing below softens it' "$TR_SIBLING"

# PIN 5, THE SEARCH ITSELF, AND IT IS THE ONE THE FOUR ABOVE ONLY LOOKED LIKE.
# Pins 1 to 4 are MESSAGE STRINGS, and a message string is what the gate PRINTS,
# never what it DOES. A refuter deleted the two assignment lines that carried the
# old index-based search, re-ran the whole bar, and got ALL CHECKS PASSED: every
# database pin above survived the edit, because none of them named a line that
# does any work. Pin 1's own comment called deleting the search "the cheaper and
# likelier edit of the two" and then did not guard against it.
#
# EVERY TOKEN BELOW IS A LINE THAT RUNS. Fifteen, one per part that fails apart:
# the fold that routes `none` INTO the search rather than around it, the two
# skip-list refusals that stop one entry voiding the whole tree, the matcher
# resolved to an absolute path (a bare `grep` is a gitignore-honouring wrapper in
# at least one harness and would skip the likeliest home of a connection string),
# the content pattern set, the file-name pattern set, the two searches themselves,
# the two exit-code reads that stop a search that never ran being read as clean,
# the probe that is planted, the two halves of the control that must find it, the
# real run, and the echo that makes every exclusion auditable. Delete any one and
# this reddens naming it; delete the search wholesale and thirteen of them fire.
#
# THEY ARE SHELL LINES AND THAT IS THE POINT. A pin on executable text is
# deliberately brittle, and reformatting the gate reds here, which is a reader
# looking at the gate. The expensive direction is the one this repo already paid
# for: a gate quietly reduced to the sentences it prints.
TR_SIB_SEARCH_PINS=('if [ "$own_db_lc" != none ]; then')
TR_SIB_SEARCH_PINS+=('excludes the whole tree, which turns this gate into one that cannot fail')
TR_SIB_SEARCH_PINS+=('climbs above the repo root')
TR_SIB_SEARCH_PINS+=('for db_c in /usr/bin/grep /bin/grep; do')
TR_SIB_SEARCH_PINS+=('DATABASE_URL|DATABASE_URI|DB_HOST')
TR_SIB_SEARCH_PINS+=('alembic.ini')
TR_SIB_SEARCH_PINS+=('db_hits=$("$db_grep" -rlIE "$db_pat" --exclude=')
TR_SIB_SEARCH_PINS+=('db_files=$(find . "${db_fx[@]}" -prune -o -type f "${db_fpat[@]}" -print)')
TR_SIB_SEARCH_PINS+=('the content search exited $db_rc, so it screened nothing')
TR_SIB_SEARCH_PINS+=('the file-name walk exited $db_rc, so it screened nothing')
TR_SIB_SEARCH_PINS+=('db_probe=.hackify-db-probe.')
TR_SIB_SEARCH_PINS+=('*"$db_probe/control.env"*)')
TR_SIB_SEARCH_PINS+=('*"$db_probe/migrations/control.sql"*)')
TR_SIB_SEARCH_PINS+=('db_search || exit 1')
TR_SIB_SEARCH_PINS+=('suppressed $db_r')
check_list_size "${#TR_SIB_SEARCH_PINS[@]}" 15 "the [82g] database-search pin list"
check_tokens_present_in "$TR_SIBLING" "${TR_SIB_SEARCH_PINS[@]}"
