# shellcheck shell=bash

# RELEASE-MECHANISM PINS, split out of 70-invariants-and-new.sh in the sprint
# that file reached exactly 500 LOC and could not take another line.
#
# THE SEAM IS RESPONSIBILITY, NOT SIZE. 70 keeps the STRUCTURAL invariants: a
# deleted file stays deleted, a skill file and its frontmatter exist, every hook
# command target resolves on disk, the always-on rules are injected, the
# performance surfaces are registered. Those all ask "does the plumbing exist".
# This file asks a different question. Every block below guards ONE shipped
# saving against its guard rail drifting out while the prose promising the
# saving stays, which is how a token saving turns into a silent loss of rigor.
# Each block says so in its own words; they cross-reference each other by check
# ID ("same discipline as [38c]"), which is why those IDs travelled with them.
#
# CHECK IDS ARE NOT RENUMBERED. [38c], [38d], [38g] and [38f] are cited from
# CHANGELOG.md, from the sprint work-docs and from each other. A fragment is
# free to move; a check ID other files cite is not. [38e] and [38h] moved on
# again, to 72-diff-slicing-pins.sh, when THIS file in turn reached the cap, and
# they took their own IDs with them for exactly the same reason.
#
# INJECT_PY IS REDEFINED HERE, NOT INHERITED. [38b] sets it and [38b] stayed in
# 70, so today's source order would carry the value across. Leaning on that
# would make this file depend on the ORDER of two lines in validate-dod.sh, and
# reordering that list is exactly what the next split does. One assignment costs
# less than an undeclared cross-fragment dependency that nothing pins.
INJECT_PY="hooks/inject_context.py"

yellow "[38c] the v0.11.0 token-reduction changes keep their mechanism"
# Four behaviours landed in v0.11.0 to cut fan-out cost. Each one is a
# saving that turns into a silent LOSS of coverage if its mechanism drifts
# out while the prose that promises it stays. Prose nothing checks is prose
# that drifts back, so each is pinned here to the artifact that carries it.
P5_REVIEW="skills/hackify/references/phases/phase-5-review.md"
REVIEWER_B_AGENT="agents/reviewer-quality-plan.md"
REVIEWER_B_TPL="skills/hackify/references/parallel-agents/phase-5-multi-review-b-quality-plan.md"
WORK_DOC_TPL="skills/hackify/references/work-doc-template.md"

# (1) THE EVIDENCE GATE IS RETIRED, and E is the one lens still conditional.
# What this used to pin was folding: B took {{folded_lenses}} and ran the folded
# lens's residual checklist, so gating A/D/F off moved their coverage instead of
# deleting it. 0.16.0 removed the gate, so folding has no remaining user and the
# whole mechanism went with it (CLAUDE.md 4.2, an always-`none` input is dead
# code). E survives as a conditional lens and is OMITTED rather than folded,
# which is the one distinction a later editor is most likely to collapse back
# into "E folds into B" while the panel stays correct everywhere else. Both
# halves are pinned: the rule, and the reason it is omission and not folding.
# The exclusivity half, that E is the ONLY conditional lens, is pinned by [79]
# instead, which enforces it as an invariant over a set it discovers rather than
# over one named file. Pinned here is the half [79] cannot ask: that E's absence
# is an OMISSION and not a fold, which is the distinction folding's removal makes
# load-bearing and the one a later editor is most likely to collapse.
check_token_present 'omitted, never folded' "$P5_REVIEW"
# The retired mechanism must not walk back into either copy of B's prompt.
for f in "$REVIEWER_B_AGENT" "$REVIEWER_B_TPL"; do
  check_no_token '{{folded_lenses}}' "$f"
  check_no_token '[folded:' "$f"
done

# (2) THE ROUND CAP'S HONESTY CLAUSE, which replaced the FULL-round exit in
# 0.16.0. The cap itself is pinned by [76h], worded identically at all four
# sites. What is pinned HERE is the paragraph stating what the cap GIVES UP:
# a clean panel result describes the diff the panel read, not the post-fix
# diff, so the last fixes ship unreviewed by the panel. That is a real cost the
# cap accepts rather than removes, and a later editor tidying the rule down to
# its happy half would delete the only place it is admitted. The rule survives
# such an edit; the honesty does not, which is why it needs its own pin.
check_token_present 'What the cap gives up, stated plainly.' "$P5_REVIEW"

# (3) {{repo_brief}} is a required input on every dispatched prompt, so it needs
# a PRODUCER. NO COUNT IS WRITTEN HERE, deliberately, the same way
# 57-doc-links.sh refuses to write one: this line read "14 prompts" while the
# tree held 12, and an unpinned number in a comment is exactly the rotting claim
# the claim-integrity work exists to catch. Re-derive the population with
#   ls agents/*.md skills/hackify/references/parallel-agents/*.md \
#     | xargs grep -ln '{{repo_brief}}' | wc -l
# Phase 2 builds it and the work-doc template holds it; without both, every
# dispatched agent receives an unfilled placeholder and refuses.
check_token_present '### Repo Brief' "$WORK_DOC_TPL"
check_token_present 'Build the Repo Brief' "skills/hackify/SKILL.md"

# (4) Dispatch by registered agent type, do NOT paste the template. Pasting a
# prompt the agent already carries charges the same text twice, which is the
# single largest avoidable cost in a review wave.
check_token_present 'Do not open the template file to paste the prompt' "$P5_REVIEW"

# The companion mode must not describe the pre-0.11.0 world. quick dispatches the
# same agents full hackify does; prose that still says "paste the template" or
# "5 parallel reviewers" sends a live mode down the old path, and a mode tuned for
# speed is the one that drifts there first, because every sentence it drops is a
# sentence it saves.
check_token_present 'by registered agent type' "skills/quick/SKILL.md"
check_token_present 'repo-brief.md' "skills/quick/SKILL.md"

# The pointer must carry the law, not merely point at it. This harness
# summarises long conversations, and a summary can drop the turn that held the
# full injection; a bare "scroll up" pointer would leave the caps unstated.
check_token_present 'digest_of' "$INJECT_PY"
check_token_present 'Core, still binding in full' "$INJECT_PY"
# "40 lines" and "500 lines" are the same phrase without their subject, so the
# digest carries the qualifying clause; and a file it cannot digest at all
# falls back to the full body rather than shipping a bare reference.
check_token_present 'def qualifier' "$INJECT_PY"
check_token_present 'if not digest_of(body):' "$INJECT_PY"

yellow "[38d] every routing trigger phrase survives in its skill description"
# v0.11.0 trimmed all eight skill descriptions to cut always-on cost. The
# description IS the router: the model picks a skill by matching the user's
# words against these literals, and the seven skills discriminate against each
# other on them. Trimming prose is safe; trimming a trigger silently re-routes
# real user phrases to the wrong skill, and nothing else in CI would notice.
# Every phrase below was verified present when the trim landed. Removing one
# is a routing change, so it has to be a deliberate edit here, not a casualty
# of the next round of compression.
trigger_check() {
  local skill="$1"; shift
  local file="skills/${skill}/SKILL.md"
  local desc
  # Read the description field only, folded scalars included, so a trigger that
  # survives in the skill BODY cannot mask one deleted from the routing surface.
  # Stop at the closing --- as well as at the next frontmatter key. Without the
  # --- guard, a description that is the LAST key prints to EOF and the check
  # would read the whole skill BODY, where a trigger deleted from the routing
  # surface can still appear and mask its own removal.
  desc=$(awk 'NR>1 && /^---[ \t]*$/{exit} /^description:/{f=1; print; next} f && /^[a-z-]+:[ \t]/{exit} f{print}' "$file" 2>/dev/null)
  local missing=0
  local body_skill
  for phrase in "$@"; do
    case "$desc" in
      *"$phrase"*) ;;
      *) red "  FAIL ${skill} description lost trigger '${phrase}'"; FAILED=$((FAILED + 1)); missing=1 ;;
    esac
  done
  # RECORD, do not assert. The body half below consumes exactly the list this
  # call was given, so the two checks can never drift onto two different lists.
  # Nothing here changes what this function reads; it still sees the description
  # and nothing else.
  for body_skill in "${TRIGGER_BODY_SKILLS[@]}"; do
    [ "$body_skill" = "$skill" ] || continue
    for phrase in "$@"; do
      TRIGGER_BODY_ROW_SKILL+=("$skill")
      TRIGGER_BODY_ROW_PHRASE+=("$phrase")
    done
  done
  [ "$missing" = "0" ] && green "  ok   ${skill} keeps all $# trigger phrases"
}

# THE OTHER DIRECTION. trigger_check reads the frontmatter alone, on purpose, and
# that leaves the reverse hole open: a phrase pinned on the routing surface can go
# missing from a skill BODY whose own lead-in tells the reader it lists every
# trigger. groom shipped in exactly that state, six bullets under a sentence
# promising the complete set while eight phrases were pinned, so a user typing
# "considering" matched the router and read a body that never mentioned it.
#
# Only a skill whose body actually claims to list its triggers belongs in the
# array. groom is the only one today: over the `## When to invoke` section,
# `grep -c '^- `' returns 9 for groom and 0 for the other six skills, so naming
# any of the others would red this check against a list that does not exist.
#
# READ THE LIST, NOT THE WHOLE BODY. The first version of trigger_body_check
# substring-matched everything after the closing frontmatter ---, and that is a
# pin that cannot fire on the phrase most likely to move. groom's own precedence
# sentence quotes `let's discuss` as its worked example, so the phrase sits in
# the prose whether or not the bullet is in the list: deleting the bullet left
# this check printing green over the exact loss it was written to catch, and the
# red it was accepted on was true of the other seven phrases only. The read is
# now the `- `phrase`` bullets of the `## When to invoke` section, the same shape
# the paragraph above measured that list with, so prose elsewhere in the file can
# no longer stand in for a bullet that is gone. The frontmatter half is
# untouched: the two halves still read two different surfaces and still fail
# independently.
#
# THE LIST IS A SUPERSET OF THE PIN SET, and the ok line says so rather than
# leaving a reader to wonder which bullet went missing. groom lists nine bullets
# against eight pinned phrases. The unpinned one is the bare skill name, and it
# stays unpinned on purpose: the word runs through every page of the file, so a
# pin on it would pass no matter what the list said, which is the same defect
# this comment opens with.
TRIGGER_BODY_SKILLS=(groom)
check_list_size "${#TRIGGER_BODY_SKILLS[@]}" 1 "the [38d] body-mirror skill set"
# Two parallel arrays rather than one delimited array: a trigger phrase is free
# text and every separator character is a character some future phrase may hold.
# Same index, same recorded pair, nothing to split and nothing to escape.
TRIGGER_BODY_ROW_SKILL=()
TRIGGER_BODY_ROW_PHRASE=()

trigger_body_check() {
  local skill="$1"
  local file="skills/${skill}/SKILL.md"
  local body listed
  # The bullet LIST under `## When to invoke`, never the whole body. Rationale
  # above the function, with the phrase that proved the whole-body read vacuous.
  body=$(awk '/^## When to invoke/{f=1;next} f&&/^## /{exit} f&&/^- `/' "$file" 2>/dev/null)
  listed=$(printf '%s\n' "$body" | grep -c '^- `')
  local missing=0
  local found=0
  local phrase
  local i=0
  local n=${#TRIGGER_BODY_ROW_PHRASE[@]}
  # Counted loop, not `for x in "${arr[@]}"`: the run sets -u, and an empty array
  # expanded that way aborts the whole validator instead of failing this check.
  while [ "$i" -lt "$n" ]; do
    if [ "${TRIGGER_BODY_ROW_SKILL[$i]}" = "$skill" ]; then
      phrase="${TRIGGER_BODY_ROW_PHRASE[$i]}"
      found=$((found + 1))
      case "$body" in
        *"$phrase"*) ;;
        *) red "  FAIL ${skill} body lost trigger '${phrase}'"; FAILED=$((FAILED + 1)); missing=1 ;;
      esac
    fi
    i=$((i + 1))
  done
  # A skill named in the array whose phrases were never recorded asserts nothing
  # at all, which reads green and guards nothing. That is a failure, not a pass.
  if [ "$found" = "0" ]; then
    red "  FAIL ${skill} is in TRIGGER_BODY_SKILLS but no trigger_check call recorded its phrases, so its body was never checked"
    FAILED=$((FAILED + 1))
  elif [ "$missing" = "0" ]; then
    green "  ok   ${skill} body list carries all ${found} pinned trigger phrases (${listed} bullets listed, a superset: a phrase the rest of the file repeats anyway, such as the bare skill name, is left unpinned because a pin on it could never fail)"
  fi
}

# The seven autopilot phrases at the tail of the hackify list are the retired
# mode's triggers, and they are pinned HERE because this is the only place that
# makes the re-routing real. 0.17.0 folded the third build mode into full hackify
# and decided its trigger words should re-point rather than go dead, so a user who
# still types "yolo" or "go full auto" reaches the gated workflow instead of
# nothing at all. Drop one of these from the description and that phrase silently
# stops routing anywhere, which is the failure this whole block exists to catch.
trigger_check hackify "use the workflow" "add, build, implement, refactor, redesign, restyle, migrate, debug, polish, audit" "auth, crypto, migration, secret, token, password" "yolo" "just do it" "don't ask me" "no questions" "fully autonomous" "auto mode" "go full auto"
trigger_check quick "quick fix" "small change" "just fix the" "one-line fix" "tiny edit" "small fix" "small bug" "quick patch" "minor tweak" "just rename" "fix typo" "/hackify:quick" "switch to full" "promote to full"
trigger_check lawkeeper "audit my code against our rules" "does this follow CLAUDE.md" "find all rule violations" "validate the architecture"
trigger_check codewalk "/hackify:codewalk" "walk this code" "walk me through" "walk through this" "trace this call stack" "trace this flow" "trace from" "explain this flow" "explain how this works" "what happens when" "onboard me to" "call-stack viewer" "code walkthrough"
trigger_check review-triage "/hackify:review-triage" "respond to the review" "respond to PR feedback" "respond to reviewer comments" "address review findings"
trigger_check groom "/hackify:groom" "let's discuss" "let's think" "what if" "explore the idea" "what do you think" "considering" "thinking about"
trigger_check skillsmith "/hackify:skillsmith" "author a hackify skill" "create a new skill for hackify" "make a hackify-style skill" "new hackify skill"

# Runs last because it consumes what the calls above recorded.
for trigger_body_skill in "${TRIGGER_BODY_SKILLS[@]}"; do
  trigger_body_check "$trigger_body_skill"
done

yellow "[38g] the v0.13.0 agent-merge changes keep their mechanism"
# Same discipline as [38c], [38e] and [38f], with one difference worth stating:
# every earlier pin guards a saving that a drifting guard rail turns into lost
# rigor. This one also guards a COUNT, because the merge shipped with six live
# files still saying Phase 2.5 runs three reviewers and no check noticed. A stale
# count is not cosmetic here, it is the number an orchestrator dispatches on.
PA="skills/hackify/references/parallel-agents"
LEDGER="skills/hackify/references/phase-ledger.md"
CONTRACT="$PA/template-contract.md"
P25_PHASE="skills/hackify/references/phases/phase-2.5-spec-review.md"

# (1) Phase 2.5 dispatches ONE reviewer, in every file that states a count.
check_token_present '1 reviewer scrutinizes work-doc' "skills/hackify/SKILL.md"
check_token_present '1 reviewer, patch the doc' "$LEDGER"
check_token_present '1 reviewer report aggregated' "$LEDGER"
check_token_present 'one reviewer, three lenses' "$CONTRACT"
check_token_present 'Dispatch exactly 1 reviewer' "$P25_PHASE"

# (2) The letter C is retired, not reassigned. Reusing it would silently point a
# work-doc or a transcript at a lens that no longer exists, and Phase 5 has its
# own Reviewer C, so the collision would read as plausible instead of wrong.
check_token_present 'The letter C is retired, not reassigned' "$P25_PHASE"
check_no_token 'spec-reviewer-dependencies' "agents"
check_no_token 'spec-reviewer-consistency' "agents"
check_no_token 'spec-reviewer-rules' "agents"

# (3) The merged A carries BOTH lenses, and leads with the plan Phase 3 consumes.
for f in "agents/spec-reviewer.md" "$PA/phase-2.5-spec-reviewer.md"; do
  check_token_present '{{wave_size_target}}' "$f"
done

# (4) Both Reviewer Bs load the deep doctrine they audit against. This is the pin
# that matters most: both agent copies had ALREADY drifted behind their templates
# and lost this step, and because the registered agent copy is what runs on Claude
# Code, both reviewers were auditing without it while the docs said otherwise. A
# missing load step costs nothing visible, it just returns a thinner report.
for f in "agents/spec-reviewer.md" "$PA/phase-2.5-spec-reviewer.md" \
         "agents/reviewer-quality-plan.md" "$PA/phase-5-multi-review-b-quality-plan.md"; do
  check_token_present 'rules/code-quality.md' "$f"
done

# (5) The Phase 5 panel is EVIDENCE-GATED, not a fixed count: B stands, A/D/F fold
# into B when the diff gives their lens nothing to look at, E joins on UI-bearing
# diffs, cap 5. These pins used to assert four reviewers always run, false since
# 17c4a24 and the v0.13.0 C-into-B merge. Pin the GATING RULE, never the arithmetic:
# a fixed count fails on correct text and passes on a reverted panel. The range
# spellings are caught by ban lists rather than pins: RR_BANS in [77] carries
# '4-5 reviewers', P5_BANS below carries '5-6 reviewers' over a set that includes
# ORCH_G, and orchestration.md states no count to pin in the first place. With B
# alone standing the true floor is 1, so any range denies it.
P5_PHASE_G="skills/hackify/references/phases/phase-5-review.md"
RAV_G="skills/hackify/references/review-and-verify.md"
ORCH_G="skills/hackify/references/orchestration.md"
ESC_G="$PA/phase-5-escalation.md"
QUICK_G="skills/quick/SKILL.md"
check_token_present 'Cap at 5' "$P5_PHASE_G"
# THE PANEL ROSTER, one wording, at the three files that state it in prose. The
# gated version of this pin named B the standing member and A/D/F evidence-gated;
# both halves of that claim retired together in 0.16.0. These pins are also what
# replaced the retired {{folded_lenses}} input: an input whose only possible value
# was `none` is dead code, but the failure it guarded against, a lens silently
# absent from a dispatch, did not retire with the gate. It changed shape, from a
# fold nobody carried to a lens nobody sent. [79] enforces the same
# rule as an invariant over a set it discovers, which catches a NEW file making a
# roster claim; these three are pinned by name because they are the ones a reader
# is sent to, and a paraphrase in any of them is a second rule to reconcile.
check_token_present 'A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one' "$P5_PHASE_G"
check_token_present 'A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one' "skills/hackify/SKILL.md"
check_token_present 'A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one' "$RAV_G"
check_token_present 'plus E on UI-bearing diffs' "$ESC_G"
# The five agent frontmatter descriptions carry the same gating clause, and so do the
# two templates whose prose sits outside the fence. A description is NOT in the fenced
# block, so [75h] cannot see it, and it is the line an orchestrator reads to pick who runs.
PANEL_AGENTS="agents/reviewer-security.md agents/reviewer-quality-plan.md agents/reviewer-performance.md agents/reviewer-design.md agents/reviewer-coherence.md $PA/phase-5-multi-review-a-security.md $PA/phase-5-multi-review-f-coherence.md"
for f in $PANEL_AGENTS; do check_token_present 'A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one' "$f"; done
# Every literal below encodes a panel width nobody dispatches on any more, in either
# phase. Banned everywhere rather than per-file because a hand-kept per-file list is the
# thing that goes stale, and correct text cannot contain any of them. '3 reviewers' /
# '2 reviewers' was a separate 4-file loop, folded in so work-doc-template.md is covered.
P5_FILES="$P5_PHASE_G $RAV_G $ORCH_G $ESC_G $QUICK_G $PANEL_AGENTS skills/hackify/SKILL.md $LEDGER $CONTRACT $P25_PHASE $WORK_DOC_TPL"
# TWO ENTRIES LEFT THIS LIST IN 0.16.0, and both left for the same reason: they
# became TRUE. 'A, B, D and F always' and 'FOUR foreground reviewers' each named a
# panel width nobody dispatched on while the gate stood, and each names the actual
# roster now that it is gone. A ban on correct text is a trap for the next writer,
# who reads a red on a sentence that says exactly what the docs say.
P5_BANS=('A, B, C, D and F' 'A, B, C and F' 'A, B, C and D' 'B, C, D and F' 'as a sixth' 'Cap at 6' 'cap of 6' 'FIVE foreground reviewers' 'five baseline Phase 5 reviewers' 'five-to-six reviewers' 'five-to-six-parallel' '5-to-6-reviewer' '5-6 reviewers' '5-to-6 parallel reviewers' '3 parallel reviewers' 'Dispatch 2 foreground reviewers' 'Parallel agents scrutinize' 'Cap B at' 'B/C/F' '3 reviewers' '2 reviewers')
# Both sizes below are written a SECOND time by hand, the shape [77] already uses: a bound read back out of a list cannot police that list.
check_list_size "$(printf '%s' "$P5_FILES" | wc -w | tr -d ' ')" 17 "the [70] panel-width file set"
check_list_size "${#P5_BANS[@]}" 21 "the [70] count-grammar ban list"
# FLATTENED, because 18 of these 21 tokens carry a space and every file below is
# wrapped markdown, where a banned phrase straddling a line break passes a
# line-oriented screen. One grep per file for the whole list: see 00-helpers.sh.
for f in $P5_FILES; do check_no_flowed_tokens_in "$f" "${P5_BANS[@]}"; done

# No retired agent type may be named in a live instruction, in ANY mode. A dead
# type fails at dispatch, not at validation, and quick kept dispatching
# `hackify:code-reviewer-quality` through three merges because nothing looked
# outside the hackify skill. Hence whole directories: a hand-kept list of files
# to check is precisely the thing that goes stale. Two files name the retired
# types to record the retirement and are excluded by path, which is safe in a
# way that an allowlist of files to check would not be. The [^-] guard catches
# the retired type without catching the live reviewer-quality-plan.
RETIRED_TYPES='hackify:code-reviewer-quality([^-]|$)|hackify:code-reviewer-plan-consistency'
RETIRED_TYPES="$RETIRED_TYPES"'|hackify:codebase-researcher|hackify:debug-evidence-gatherer'
RETIRED_TYPES="$RETIRED_TYPES"'|hackify:spec-reviewer-(rules|dependencies|consistency)'
RETIREMENT_NOTES="$PA/README.md|$PA/phase-2.5-spec-reviewer.md"
DEAD_TYPE_HITS=$(grep -rnE -- "$RETIRED_TYPES" skills/ commands/ agents/ 2>/dev/null \
  | grep -vE "^($RETIREMENT_NOTES):" || true)
if [ -z "$DEAD_TYPE_HITS" ]; then
  green "  ok   no retired agent type is named outside the two files that record the retirement"
else
  red "  FAIL retired agent type named in a live instruction:"
  printf '%s\n' "$DEAD_TYPE_HITS" | sed 's/^/         - /'
  FAILED=$((FAILED + 1))
fi

# Phase 2.5's letters are retired, not reassigned, and goal-anchor.md still
# addressed "Reviewer A" after the three spec reviewers became one. It is the
# file both surviving reviewers load for their verdict wording, so a stale
# name here is read by the agent that enforces the anchor.
check_no_flowed_token 'Phase 2.5 Reviewer A' "skills/hackify/references/goal-anchor.md"
check_token_present 'The Phase 2.5 spec reviewer (consistency lens)' \
  "skills/hackify/references/goal-anchor.md"

# (6) The merged Reviewer B actually carries C's lens. These four inputs are the
# ones C owned and B never had, so their absence is the signature of a merge that
# renamed a file and dropped a lens. task_file_index in particular is the one C
# refused to proceed without.
for f in "agents/reviewer-quality-plan.md" "$PA/phase-5-multi-review-b-quality-plan.md"; do
  check_token_present '{{task_file_index}}' "$f"
  check_token_present '{{changelog_path}}' "$f"
  check_token_present 'Primary Goal & Guardrails' "$f"
  check_token_present 'scope-creep' "$f"
done
# (7) The merged investigator carries BOTH modes. A prompt that lost its mode
# tags is a prompt applying debug steps to a research question, which is the
# specific failure a mode-switched agent risks and the reason each METHOD step
# carries its tag in the text rather than in a note somewhere else.
for f in "agents/codebase-investigator.md" "$PA/investigation.md"; do
  check_token_present '{{mode}}' "$f"
  check_token_present '[research]' "$f"
  check_token_present '[debug]' "$f"
  check_token_present 'FALSIFY' "$f"
  check_token_present 'Patterns to mirror' "$f"
done

# (8) No retired agent name survives anywhere in agents/. On Claude Code that
# directory IS the registry, so a leftover name is a dispatchable ghost, and a
# leftover mention inside a description reads as a live sibling that is not there.
for dead in code-reviewer-plan-consistency codebase-researcher debug-evidence-gatherer; do
  check_no_token "$dead" "agents"
done

yellow "[38f] the v0.12.0 fan-out changes keep their mechanism"
# Same discipline as [38c] and [38e]. Each of these trades an agent for tokens, and
# each becomes a LOSS of rigor the moment its guard rail drifts out while the prose
# promising the saving stays. Pin the guard rail, not the saving.

P5_PHASE="skills/hackify/references/phases/phase-5-review.md"
REFUTE_TPL="skills/hackify/references/parallel-agents/phase-5-refute.md"
DEPS_TPL="skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md"

# (1) The implementer takes a WHOLE WAVE, so both mirror sides must keep taking a
# task LIST rather than a single task. Lose that and per-wave dispatch regresses to
# one agent per task, handing back every token it saved. The spec reviewer has now
# stopped emitting batches for it to dispatch off, so what it owes Phase 3 is a wave
# plan whose waves are file-disjoint and capped, and those two replace the batch cap.
#
# DISJOINTNESS BUYS ATTRIBUTION NOW, not collision safety, and the pin staying put
# through the change is what makes the two easy to confuse. Collision safety was the
# original reason, and it dissolved on contact rather than being traded away, as
# recorded in CHANGELOG.md's "with one agent per wave there is no second writer to collide with".
# That is quoted rather than numbered because the changelog is appended to at the TOP,
# so a line into it drifts on every release, and a pin that reds every release is one
# somebody eventually repoints without reading it. The paragraph below reaches the
# same place from the opposite failure, a number that goes stale in silence. What
# survives is that every touched file maps to exactly one task, which is how the
# parent reads a PARTIAL diff back as a set of task IDs. The `(a) Your DECLARATION,
# checked against your own allowlist.` block of phase-3-implementation.md leans on
# that directly, since a wave that stopped early writes a strict subset of the union
# on purpose, and ticking a task the agent never finished is the one thing a work-doc
# must never do.
#
# CITED BY BLOCK HEAD, NOT BY LINE, and that is the fix rather than the style. This
# read line 238 of `phase-3-implementation.md` until 0.16.0, and by then the block
# had moved to 252 and then to 260 as edits landed above it. That retired number is
# spelled as prose rather than as a `file:line` token on purpose: [57] parses the
# token form wherever it appears, comments included, so writing the history the old
# way would plant a live pointer that resolves against whatever now sits on that
# line and reads as verified. Nothing reddened at the time, and the reason
# has since NARROWED rather than gone away, which is worth writing down because the
# old wording here read as a permanent gap. [57] opens the cited location now, refuses
# one that is blank or a bare marker or a shebang, and where the citing sentence quotes
# the line behind a verb it matches that quote against what is really there. What no
# form of it can do is judge an UNPINNED citation, one that names a line and quotes
# nothing from it, which is what this comment used to carry: such a citation resolves
# against any number under the file's length and says so on the coverage line rather
# than reddening. So the advice is unchanged and its reason is smaller. A citation that
# survives every edit while pointing at the wrong paragraph is worse than a dangling
# one: it reads as verified, and a pin nobody quotes is the shape that gets there. The
# block head is a string the file either carries or does not, so it goes stale loudly.
for f in "agents/implementer.md" "skills/hackify/references/parallel-agents/phase-3-implementation.md"; do
  check_token_present '{{task_ids}}' "$f"
  check_token_present '{{task_descriptions}}' "$f"
done
for f in "agents/spec-reviewer.md" "$DEPS_TPL"; do
  check_token_present 'one dispatched implementer per wave' "$f"
  check_token_present 'no two tasks share a file' "$f"
done

# (2) A WAVE STOPS at the first task its single agent cannot finish, and decision
# #11-A is all three halves of that rather than the stop alone: everything already
# on disk stays, and the report names which task IDs landed and which did not. Lose
# the stop and one bad task drags the rest of the wave down behind it. Lose the
# other two and the parent cannot tell what survived, so it re-dispatches the whole
# wave instead of the handful actually missing. The reporting half is pinned over
# both mirror sides by [40] in 73-implementer-rename.sh.
for f in "agents/implementer.md" "skills/hackify/references/parallel-agents/phase-3-implementation.md"; do
  check_token_present 'STOP there' "$f"
done

# (3) ONE refuter per round judges every finding now, so the both-lenses rule is the
# first gate a Critical clears, not the last: an adjudication escalation and the user's
# sign-off hold it up behind that. The bar was never "two agents", it was two independent
# lines of attack that must both fail; let one lens kill a Critical and the collapse stops
# being free and starts deleting real defects. The first two pins read the template alone;
# 'BOTH lenses fail' runs over BOTH mirror sides, because the agent copy is what runs.
check_token_present 'dies only when' "$REFUTE_TPL"
check_token_present 'ONE refuter agent per review round' "$REFUTE_TPL"
for f in "agents/finding-refuter.md" "$REFUTE_TPL"; do
  check_token_present 'BOTH lenses fail' "$f"
done

# (3b) F RUNS UNCONDITIONALLY, and that is what this block pins now. It used to pin
# the seam gate and B's inherited F checklist: F folded when the diff stayed inside
# one module, and B carried the residual so nothing was dropped. 0.16.0 removed the
# gate for the reason the fold was always uncomfortable, that a diff you were sure
# stayed inside one module is exactly the diff whose seam nobody looked for. F is
# the only lens comparing a producer against its consumers, so both halves of that
# argument, then and now, are about the same failure: a half-built feature shipping
# because each half looked fine alone.
check_token_present 'On the panel unconditionally' "$PA/phase-5-multi-review-f-coherence.md"
check_token_present 'A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one' "$P5_PHASE"

# (4) The panel does not read Phase 3 dispatch bookkeeping. That block just grew a
# batch list, so a reviewer still reading it pays for the batching twice over.
check_token_present 'Execution waves' "skills/hackify/references/work-doc-template.md"
