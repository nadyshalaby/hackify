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
# CHECK IDS ARE NOT RENUMBERED. [38c], [38d], [38g], [38f] and [38e] are cited
# from CHANGELOG.md, from the sprint work-docs and from each other. A fragment
# is free to move; a check ID other files cite is not. The blocks also keep
# their original order, so a `diff` of validator output against a pre-split run
# is a pure reordering of nothing at all.
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
REVIEWER_B_AGENT="agents/code-reviewer-quality-plan.md"
REVIEWER_B_TPL="skills/hackify/references/parallel-agents/phase-5-multi-review-b-quality-plan.md"
WORK_DOC_TPL="skills/hackify/references/work-doc-template.md"

# (1) The reviewer gate MOVES a lens to B, it never drops one. Reviewer B must
# take {{folded_lenses}} as an input and actually run the inherited checklist,
# in BOTH copies of the prompt, or gating A/D off deletes their coverage.
for f in "$REVIEWER_B_AGENT" "$REVIEWER_B_TPL"; do
  check_token_present '{{folded_lenses}}' "$f"
  check_token_present 'residual checklist' "$f"
  check_token_present '[folded:' "$f"
done
check_token_present 'Folding moves a lens, it never removes one.' "$P5_REVIEW"
check_token_present '{{folded_lenses}}' "$P5_REVIEW"

# (2) The address-all loop may only CLOSE on a full round over the full range.
# Scoped middle rounds are the saving; letting one of them end the loop would
# hand back a "settled diff" that no full panel ever saw.
check_token_present 'The loop may only end on a FULL round' "$P5_REVIEW"

# (3) {{repo_brief}} is a required input on 14 prompts, so it needs a PRODUCER.
# Phase 2 builds it and the work-doc template holds it; without both, every
# dispatched agent receives an unfilled placeholder and refuses.
check_token_present '### Repo Brief' "$WORK_DOC_TPL"
check_token_present 'Build the Repo Brief' "skills/hackify/SKILL.md"

# (4) Dispatch by registered agent type, do NOT paste the template. Pasting a
# prompt the agent already carries charges the same text twice, which is the
# single largest avoidable cost in a review wave.
check_token_present 'Do not open the template file to paste the prompt' "$P5_REVIEW"

# The companion modes must not describe the pre-0.11.0 world. quick and yolo
# dispatch the same agents; prose that still says "paste the template" or
# "5 parallel reviewers" sends two of three modes down the old path.
check_token_present 'by registered agent type' "skills/yolo/SKILL.md"
check_token_present 'by registered agent type' "skills/quick/SKILL.md"
check_token_present 'repo-brief.md' "skills/yolo/SKILL.md"
check_token_present 'repo-brief.md' "skills/quick/SKILL.md"
check_token_present 'evidence-gated panel' "skills/yolo/SKILL.md"

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

# {{folded_lenses}} is refuse-on-absent, so EVERY dispatch site of Reviewer B
# has to name it, middle rounds and the settle round included. One missing
# site costs a whole round in a live sprint.
check_token_present 'Every dispatch of Reviewer B carries' "$P5_REVIEW"
check_token_present '{{folded_lenses}}' "skills/hackify/references/review-and-verify.md"
check_token_present 'every round' "skills/yolo/SKILL.md"

yellow "[38d] every routing trigger phrase survives in its skill description"
# v0.11.0 trimmed all eight skill descriptions to cut always-on cost. The
# description IS the router: the model picks a skill by matching the user's
# words against these literals, and the eight skills discriminate against each
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
  for phrase in "$@"; do
    case "$desc" in
      *"$phrase"*) ;;
      *) red "  FAIL ${skill} description lost trigger '${phrase}'"; FAILED=$((FAILED + 1)); missing=1 ;;
    esac
  done
  [ "$missing" = "0" ] && green "  ok   ${skill} keeps all $# trigger phrases"
}

trigger_check hackify "use the workflow" "add, build, implement, refactor, redesign, restyle, migrate, debug, polish, audit" "auth, crypto, migration, secret, token, password"
trigger_check quick "quick fix" "small change" "just fix the" "one-line fix" "tiny edit" "small fix" "small bug" "quick patch" "minor tweak" "just rename" "fix typo" "/hackify:quick" "switch to full" "promote to full"
trigger_check yolo "/hackify:yolo" "/yolo" "yolo it" "go yolo" "just do it" "don't ask me" "no questions" "fully autonomous" "auto mode" "go full auto" "Does NOT trigger on" "just fix it"
trigger_check lawkeeper "audit my code against our rules" "does this follow CLAUDE.md" "find all rule violations" "validate the architecture"
trigger_check codewalk "/codewalk" "walk this code" "walk me through" "walk through this" "trace this call stack" "trace this flow" "trace from" "explain this flow" "explain how this works" "what happens when" "onboard me to" "call-stack viewer" "code walkthrough"
trigger_check review-triage "/hackify:review-triage" "respond to the review" "respond to PR feedback" "respond to reviewer comments" "address review findings"
trigger_check groom "/hackify:groom" "let's discuss" "let's think" "what if" "explore the idea" "what do you think" "considering" "thinking about"
trigger_check skillsmith "/hackify:skillsmith" "author a hackify skill" "create a new skill for hackify" "make a hackify-style skill" "new hackify skill"

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
check_token_present '1 reviewer on the plan block' "$LEDGER"
check_token_present '1 reviewer report aggregated' "$LEDGER"
check_token_present 'one reviewer, three lenses' "$CONTRACT"
check_token_present 'Dispatch the 1 reviewer' "skills/yolo/SKILL.md"
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
         "agents/code-reviewer-quality-plan.md" "$PA/phase-5-multi-review-b-quality-plan.md"; do
  check_token_present 'rules/code-quality.md' "$f"
done

# (5) The Phase 5 panel is EVIDENCE-GATED, not a fixed count: B stands, A/D/F fold
# into B when the diff gives their lens nothing to look at, E joins on UI-bearing
# diffs, cap 5. These pins used to assert four reviewers always run, false since
# 17c4a24 and the v0.13.0 C-into-B merge. Pin the GATING RULE, never the arithmetic:
# a fixed count fails on correct text and passes on a reverted panel. And
# orchestration.md's "4-5 reviewers" row is deliberately NOT pinned, it sizes a
# fan-out for the orchestration tier (flat batch vs Workflow tool), an answer
# identical at 1 reviewer and at 5, so it estimates cost rather than stating a
# contract; with B alone standing the true floor is 1, which that range denies.
P5_PHASE_G="skills/hackify/references/phases/phase-5-review.md"
RAV_G="skills/hackify/references/review-and-verify.md"
ORCH_G="skills/hackify/references/orchestration.md"
ESC_G="$PA/phase-5-escalation.md"
QUICK_G="skills/quick/SKILL.md"
check_token_present 'Cap at 5' "$P5_PHASE_G"
check_token_present 'B is the standing member of every wave' "$P5_PHASE_G"
check_token_present 'B is the standing member of every wave' "skills/hackify/SKILL.md"
check_token_present 'The panel is evidence-gated, so its width is a decision you write down, not a constant.' "$RAV_G"
check_token_present 'plus E on UI-bearing diffs' "$ESC_G"
# The five agent frontmatter descriptions carry the same gating clause, and so do the
# two templates whose prose sits outside the fence. A description is NOT in the fenced
# block, so [75h] cannot see it, and it is the line an orchestrator reads to pick who runs.
PANEL_AGENTS="agents/code-reviewer-security.md agents/code-reviewer-quality-plan.md agents/code-reviewer-performance.md agents/design-conformance-reviewer.md agents/code-reviewer-coherence.md $PA/phase-5-multi-review-a-security.md $PA/phase-5-multi-review-f-coherence.md"
for f in $PANEL_AGENTS; do check_token_present 'B is the standing member, A, D and F are evidence-gated' "$f"; done
# Every literal below encodes a panel width nobody dispatches on any more, in either
# phase. Banned everywhere rather than per-file because a hand-kept per-file list is the
# thing that goes stale, and correct text cannot contain any of them. '3 reviewers' /
# '2 reviewers' was a separate 4-file loop, folded in so work-doc-template.md is covered.
P5_FILES="$P5_PHASE_G $RAV_G $ORCH_G $ESC_G $QUICK_G $PANEL_AGENTS skills/hackify/SKILL.md skills/yolo/SKILL.md $LEDGER $CONTRACT $P25_PHASE $WORK_DOC_TPL"
P5_BANS=('A, B, C, D and F' 'A, B, C and F' 'A, B, C and D' 'B, C, D and F' 'as a sixth' 'Cap at 6' 'cap of 6' 'FOUR foreground reviewers' 'FIVE foreground reviewers' 'A, B, D and F always' 'five baseline Phase 5 reviewers' 'five-to-six reviewers' 'five-to-six-parallel' '5-to-6-reviewer' '5-6 reviewers' '5-to-6 parallel reviewers' '3 parallel reviewers' 'Dispatch 2 foreground reviewers' 'Parallel agents scrutinize' 'Cap B at' 'B/C/F' '3 reviewers' '2 reviewers')
# Both sizes below are written a SECOND time by hand, the shape [77] already uses: a bound read back out of a list cannot police that list.
check_list_size "$(printf '%s' "$P5_FILES" | wc -w | tr -d ' ')" 18 "the [70] panel-width file set"
check_list_size "${#P5_BANS[@]}" 23 "the [70] count-grammar ban list"
# One grep per file for the whole list, same verdict lines: see 00-helpers.sh.
for f in $P5_FILES; do check_no_tokens_in "$f" "${P5_BANS[@]}"; done

# No retired agent type may be named in a live instruction, in ANY mode. A dead
# type fails at dispatch, not at validation, and quick kept dispatching
# `hackify:code-reviewer-quality` through three merges because nothing looked
# outside the hackify skill. Hence whole directories: a hand-kept list of files
# to check is precisely the thing that goes stale. Two files name the retired
# types to record the retirement and are excluded by path, which is safe in a
# way that an allowlist of files to check would not be. The [^-] guard catches
# the retired type without catching the live code-reviewer-quality-plan.
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
check_no_token 'Phase 2.5 Reviewer A' "skills/hackify/references/goal-anchor.md"
check_token_present 'The Phase 2.5 spec reviewer (consistency lens)' \
  "skills/hackify/references/goal-anchor.md"

# (6) The merged Reviewer B actually carries C's lens. These four inputs are the
# ones C owned and B never had, so their absence is the signature of a merge that
# renamed a file and dropped a lens. task_file_index in particular is the one C
# refused to proceed without.
for f in "agents/code-reviewer-quality-plan.md" "$PA/phase-5-multi-review-b-quality-plan.md"; do
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
# plan whose waves are file-disjoint and capped. Those two properties are the entire
# reason one agent can safely take a whole wave, and they replace the old batch cap.
for f in "agents/wave-implementer.md" "skills/hackify/references/parallel-agents/phase-3-implementation.md"; do
  check_token_present '{{task_ids}}' "$f"
  check_token_present '{{task_descriptions}}' "$f"
done
for f in "agents/spec-reviewer.md" "$DEPS_TPL"; do
  check_token_present 'one dispatched implementer per wave' "$f"
  check_token_present 'no two tasks share a file' "$f"
done

# (2) A batch STOPS at the first task it cannot finish. Without this a batched
# failure cascades: one bad task takes the rest of the batch down with it, which is
# the whole reason one-agent-per-task felt safe.
for f in "agents/wave-implementer.md" "skills/hackify/references/parallel-agents/phase-3-implementation.md"; do
  check_token_present 'STOP there' "$f"
done

# (3) ONE refuter per round judges every finding now, so the both-lenses rule is the
# only thing still holding a Critical up. The bar was never "two agents", it was two
# independent lines of attack that must both fail; let that weaken to one lens killing
# a Critical and the collapse stops being free and starts deleting real defects. The
# both-lenses pin runs over BOTH mirror sides, because the agent copy is what runs.
check_token_present 'dies only when' "$REFUTE_TPL"
check_token_present 'ONE refuter agent per review round' "$REFUTE_TPL"
for f in "agents/finding-refuter.md" "$REFUTE_TPL"; do
  check_token_present 'BOTH lenses fail' "$f"
done

# (3b) F is gated on a SEAM, not on risk, and B inherits its checklist when it folds.
# F is the only lens that compares a producer against its consumers, so a fold that is
# not carried is how a half-built feature ships with both halves looking fine alone.
check_token_present 'the diff crosses a module boundary' "$P5_PHASE"
check_token_present 'F folds when the diff has no SEAM' "$P5_PHASE"
check_token_present '[folded: F]' "$P5_PHASE"
for f in "agents/code-reviewer-quality-plan.md" "$PA/phase-5-multi-review-b-quality-plan.md"; do
  check_token_present 'F folded (cross-module coherence)' "$f"
done

# (4) The panel does not read Phase 3 dispatch bookkeeping. That block just grew a
# batch list, so a reviewer still reading it pays for the batching twice over.
check_token_present 'Execution waves' "skills/hackify/references/work-doc-template.md"

yellow "[38e] the v0.11.0 diff-slicing and carry-over changes keep their mechanism"
# Same discipline as [38c]. Each of these is a token saving that becomes a
# silent LOSS of review coverage the moment its mechanism drifts out while the
# prose promising it stays. Pin every one to the artifact that carries it.

SCOPE_REF="skills/hackify/references/review-scope.md"
RAV_REF="skills/hackify/references/review-and-verify.md"

# (1) The four sliced reviewers take {{review_scope}}, in BOTH copies of each
# prompt. A reviewer that never learned to scope its diff silently ignores the
# input, which costs tokens but keeps coverage; the real risk is the reverse,
# so the pairing is what is checked. It was five until v0.13.0 folded Reviewer C
# into B, and C's lens gave up slicing in the move because B is never sliced.
for f in "agents/code-reviewer-security.md" \
         "agents/code-reviewer-performance.md" "agents/design-conformance-reviewer.md" \
         "agents/code-reviewer-coherence.md" \
         "$PA/phase-5-multi-review-a-security.md" "$PA/phase-5-multi-review-d-performance.md" \
         "$PA/phase-5-multi-review-e-design.md" "$PA/phase-5-multi-review-f-coherence.md"; do
  check_token_present '{{review_scope}}' "$f"
done

# (2) Reviewer B is NEVER sliced. B applies the semantic tier to every touched
# file and re-judges every law-scout row, so any subset withheld from B is
# coverage deleted outright. Both copies of B's prompt must stay scope-free.
for f in "agents/code-reviewer-quality-plan.md" "$PA/phase-5-multi-review-b-quality-plan.md"; do
  if grep -qF '{{review_scope}}' "$f" 2>/dev/null; then
    red "  FAIL $f takes {{review_scope}}, Reviewer B must never be sliced"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f is not sliced (correct, B reads every touched file)"
  fi
  check_token_present '{{metrics_table}}' "$f"
done

# (3) The scope grammar and the carry-over rules live in ONE file, so the A
# block and the C block cannot drift apart on what `settle ` means.
check_file "$SCOPE_REF"
check_token_present 'settle all' "$SCOPE_REF"
check_token_present 'F never carries over' "$SCOPE_REF"

# (4) Carry-over is keyed on the BLOB HASH, never the path. A path-keyed ledger
# would carry a verdict across a file that changed twice in one sprint, which
# is a clean round over content no reviewer ever read.
check_token_present 'git rev-parse' "$SCOPE_REF"
check_token_present 'git rev-parse HEAD:<path>' "$P5_REVIEW"

# (5) An unclassifiable file defaults to B, so slicing can never leave a path
# uncovered, and a lens with an empty slice is a written-down gate decision.
check_token_present 'goes to B' "$P5_REVIEW"
check_token_present 'B is never sliced' "$P5_REVIEW"

# (6) A FULL round is now "every byte covered by a live verdict", not "the
# panel re-read everything". The settle prefix is what makes a carried-over
# round distinguishable from one the dispatcher never scoped at all.
check_token_present 'settle ' "$P5_REVIEW"
check_token_present 'settle all' "$RAV_REF"

# (6b) BOTH new dispatcher inputs have a PRODUCER, not just a consumer. This is
# the defect class the {{repo_brief}} work hit in 0.11.0: prose requires an
# artifact, every reviewer is told to read it, and nothing anywhere builds it.
# {{review_scope}}'s producer is the work-doc's scope ledger; {{metrics_table}}'s
# is the recipe in the dispatcher protocol. Without them the saving never fires
# (metrics, which degrades to `unavailable`) or the carry-over rule becomes
# uncheckable (scope, which is coverage).
check_token_present '### Scope ledger (Phase 5)' "$WORK_DOC_TPL"
check_token_present 'git rev-parse HEAD:<path>' "$WORK_DOC_TPL"
check_token_present 'Build `{{metrics_table}}` before you dispatch B' "$P5_REVIEW"
check_token_present 'max-lines-per-function' "$P5_REVIEW"
check_token_present 'unavailable' "$P5_REVIEW"

# (7) The Phase 6 report is rendered from JSON, never typed out by hand.
check_file "skills/hackify/scripts/render-report.py"
check_token_present 'Do not hand-write the HTML' "skills/hackify/references/html-report.md"
check_token_present 'render-report.py' "skills/hackify/references/finish.md"

yellow "[38h] the settle-echo contract's FILE SET, so a new site cannot join it unnoticed"
# WHAT THIS CATCHES AND WHAT IT DOES NOT, stated first, because a check whose comment
# overstates its reach is the defect class this sprint spent itself on.
#
# [76h] pins the FULL-round gate sentence BYTE FOR BYTE at the four files that state it,
# so those four cannot drift apart. It is blind to a FIFTH file stating the same rule in
# NEW WORDS, and that blindness is not hypothetical: three sites carried the pre-amendment
# rule in three different phrasings, a grep on the literal found four of the six sites
# that existed, and a person reading the file found the other two.
#
# THIS CLOSES ONE HALF OF THAT GAP AND ONLY ONE HALF. It counts the FILES under skills/
# and agents/ mentioning the settle prefix at all, so a NEW FILE joining the contract
# reddens until someone consciously adds it to the total. It does NOT catch a second,
# differently worded statement inside a file ALREADY in the set. Both sites that broke
# this sprint were of that second kind: review-scope.md and phases/phase-5-review.md were
# already in the set and neither offending sentence carried the marker, so this number
# would not have moved by one. Nothing mechanical catches that case at a cost worth
# paying; a reader catches it, and saying so here is cheaper than a later maintainer
# assuming it was covered.
#
# IT LIVES BESIDE [38e] BECAUSE THAT IS THE BLOCK IT GUARDS. [38e] pins the diff-slicing
# and carry-over mechanism, `settle all` and `F never carries over` included, in these
# same files. This is the same saving's file set, one layer out.
#
# THE MARKER WAS CHOSEN BY MEASUREMENT, not taste. The backticked prefix discovers
# exactly the twelve files in the contract: four sliced reviewer prompts, their four
# agents/ mirrors, and the four docs that state the rule. The obvious alternative, the
# `Scope: ` echo token, is worse at both ends, dragging in
# skills/lawkeeper/assets/report-template.md while missing all three docs that went stale.
#
# THE FILE COUNT FAILS, THE OCCURRENCE COUNT ONLY NOTES, and that asymmetry is the design
# rather than an oversight to tidy into a second hard pin. The file count moves only when
# a file joins or leaves the contract, which always deserves a human decision. The
# occurrence total moves whenever anyone rewords a prompt and happens to say the prefix
# once more, which is noise, and a check that cries wolf gets its expected number bumped
# without thought. Two pins in this repo went vacuous exactly that way earlier in this
# sprint. KNOWN HOLE, left open on purpose and written down: a site deleted INSIDE a file
# that keeps its other mentions passes here, because the file total does not move and the
# occurrence total only notes.
#
# A SECOND HOLE SITS BESIDE IT, and neither half of this check is a backstop for it. The
# echo contract has two halves: the INSTRUCTION half, carrying both marks this check
# counts, in the INPUTS block; and the SKELETON half, the `Scope: ` line in the OUTPUT
# block the echo lands on, carrying NO mark, in all eight files that state it, the four
# sliced prompts and their four agents/ mirrors. Deleting a skeleton line therefore moves
# NEITHER number: the file keeps its two instruction marks so the file count stays 12 and
# never reddens, and the deleted line held no mark so the occurrence total stays 25 and
# does not even note. Nothing in this validator pins that line today, so it would vanish
# green. Closing it wants its own pin on the skeleton line, the both-halves shape [76h]
# already argues for and applies to B's round marker, not a hard total here, and that
# decision has not been taken.
#
# grep -oF and -rlIF, never -c and never -E, and absolute /usr/bin/grep: the three reasons
# argued above [76g] all bite here. -c counts LINES, and phase-5-review.md carries two
# occurrences on one line today, so -c reads this set as 24 rather than 25.
RSE_MARK='`settle `'
RSE_ROOTS="skills agents"
# Hand-written beside the check and independent of the list it polices, per the argument
# above check_list_size in 00-helpers.sh. Today: 12 files, 25 occurrences (eight prompt
# files at 2 each, phase-5-review.md 4, review-scope.md 3, SKILL.md and
# review-and-verify.md 1 each).
RSE_FILES_EXPECTED=12
RSE_OCCUR_TODAY=25
rse_files=$(/usr/bin/grep -rlIF -- "$RSE_MARK" $RSE_ROOTS 2>/dev/null); rse_rcf=$?
rse_occs=$(/usr/bin/grep -roIF -- "$RSE_MARK" $RSE_ROOTS 2>/dev/null); rse_rco=$?
if [ "$rse_rcf" -gt 1 ] || [ "$rse_rco" -gt 1 ]; then
  red "  FAIL [38h] could not scan $RSE_ROOTS for '$RSE_MARK' (grep exited $rse_rcf then $rse_rco), so a count of 0 here would be a count of nothing"
  FAILED=$((FAILED + 1))
else
  rse_nf=0; rse_no=0
  [ -n "$rse_files" ] && rse_nf=$(printf '%s\n' "$rse_files" | wc -l | tr -d ' ')
  [ -n "$rse_occs" ] && rse_no=$(printf '%s\n' "$rse_occs" | wc -l | tr -d ' ')
  check_list_size "$rse_nf" "$RSE_FILES_EXPECTED" "the files under $RSE_ROOTS in the settle-echo contract"
  if [ "$rse_no" -eq "$RSE_OCCUR_TODAY" ]; then
    green "  ok   '$RSE_MARK' sits at $rse_no occurrences, unchanged (advisory, this half never fails)"
  else
    yellow "  note '$RSE_MARK' moved to $rse_no occurrences from the $RSE_OCCUR_TODAY recorded here; advisory by design, update it once you have looked at why"
  fi
  if [ "$rse_nf" -ne "$RSE_FILES_EXPECTED" ]; then
    red "  ---- the $rse_nf discovered file(s) were:"
    printf '%s\n' "$rse_files" | sed 's/^/        /'
  fi
fi
