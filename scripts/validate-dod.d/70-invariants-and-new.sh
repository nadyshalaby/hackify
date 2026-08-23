# shellcheck shell=bash

yellow "[33] smart-router reference fully removed (router-excision invariant)"
if [ -f "skills/hackify/references/smart-router.md" ]; then
  red "  FAIL skills/hackify/references/smart-router.md still exists (should be deleted in v0.2.2)"
  FAILED=$((FAILED + 1))
else
  green "  ok   skills/hackify/references/smart-router.md deleted"
fi
for f in "skills/hackify/SKILL.md" "skills/quick/SKILL.md"; do
  if grep -qF '(/skills/hackify/references/smart-router.md)' "$f"; then
    red "  FAIL $f still links to deleted smart-router.md"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f has no link to smart-router.md"
  fi
done

yellow "[34] skills/yolo/SKILL.md exists with name + description frontmatter and required body tokens"
check_file "skills/yolo/SKILL.md"
if [ -f "skills/yolo/SKILL.md" ]; then
  if grep -q "^name: yolo$" "skills/yolo/SKILL.md"; then
    green "  ok   skills/yolo/SKILL.md has name: yolo"
  else
    red "  FAIL skills/yolo/SKILL.md missing 'name: yolo' frontmatter"
    FAILED=$((FAILED + 1))
  fi
  if echo "yolo" | grep -Eq '^[a-z0-9-]{1,64}$'; then
    green "  ok   skills/yolo/SKILL.md slug 'yolo' matches regex ^[a-z0-9-]{1,64}\$"
  else
    red "  FAIL skills/yolo/SKILL.md slug 'yolo' fails slug regex"
    FAILED=$((FAILED + 1))
  fi
  if grep -q "^description:" "skills/yolo/SKILL.md"; then
    green "  ok   skills/yolo/SKILL.md has description: frontmatter"
  else
    red "  FAIL skills/yolo/SKILL.md missing 'description:' frontmatter"
    FAILED=$((FAILED + 1))
  fi
  check_token_present "Phase 1" "skills/yolo/SKILL.md"
  check_token_present "Phase 2.5" "skills/yolo/SKILL.md"
  check_token_present "Phase 3" "skills/yolo/SKILL.md"
  check_token_present "Phase 4" "skills/yolo/SKILL.md"
  check_token_present "Phase 5" "skills/yolo/SKILL.md"
  check_token_present "Phase 6" "skills/yolo/SKILL.md"
  check_token_present "in-chat plan" "skills/yolo/SKILL.md"
  check_token_present "auto-pass" "skills/yolo/SKILL.md"
  check_token_present "commit to current branch locally" "skills/yolo/SKILL.md"
  check_token_present "no work-doc" "skills/yolo/SKILL.md"
fi

yellow "[37] hooks/hooks.json command targets exist on disk (.sh targets executable)"
# Every ${CLAUDE_PLUGIN_ROOT}/-prefixed token in every hook command, the
# script AND its file arguments, across ALL event arrays (UserPromptSubmit,
# PreToolUse, and any added later), must resolve to a file in this repo.
# Tokens are shell-quoted inside the JSON string (so install paths with
# spaces survive word-splitting), so strip one leading/trailing quote
# before the prefix match. Iteration is a while-read over the
# newline-separated list, no unquoted word-splitting (bash 3.2 safe).
# jq path: .hooks.<event>[] (matcher groups) → .hooks[] (entries) → .command.
HOOK_TARGETS=$(jq -r '.hooks[][].hooks[].command' hooks/hooks.json 2>/dev/null \
  | tr ' ' '\n' | sed -e "s/^['\"]//" -e "s/['\"]\$//" \
  | sed -n 's|^\${CLAUDE_PLUGIN_ROOT}/||p' | sort -u)
if [ -z "$HOOK_TARGETS" ]; then
  red "  FAIL no \${CLAUDE_PLUGIN_ROOT}/ paths parsed from hooks/hooks.json (malformed JSON or empty hook arrays)"
  FAILED=$((FAILED + 1))
fi
while IFS= read -r t; do
  [ -n "$t" ] || continue
  if [ -f "$t" ]; then
    green "  ok   hooks.json target $t exists"
  else
    red "  FAIL hooks.json target $t missing on disk"
    FAILED=$((FAILED + 1))
  fi
  case "$t" in
    *.sh)
      if [ -x "$t" ]; then
        green "  ok   hooks.json target $t is executable"
      else
        red "  FAIL hooks.json target $t is not executable"
        FAILED=$((FAILED + 1))
      fi
      ;;
  esac
done <<<"$HOOK_TARGETS"

yellow "[38] all four always-on rules files are injected via UserPromptSubmit"
# Here-string, not `jq | grep -q`: grep -q short-circuits and can SIGPIPE the
# producer under pipefail (see the [24] comment in 50-runtimes-and-companions.sh).
# All four entries are checked, not just one: v0.14.0 made phase discipline
# always-on, and an entry dropped from hooks.json is that whole law gone silently.
UPS_HOOK_CMDS=$(jq -r '.hooks.UserPromptSubmit[].hooks[].command' hooks/hooks.json 2>/dev/null)
for r in hard-caps expert-mindset perf-guardrails phase-discipline; do
  if grep -qF "rules/$r.md" <<<"$UPS_HOOK_CMDS"; then
    green "  ok   hooks.json UserPromptSubmit injects rules/$r.md"
  else
    red "  FAIL hooks.json UserPromptSubmit does not inject rules/$r.md"
    FAILED=$((FAILED + 1))
  fi
done
# inject-context.sh's header enumerates the always-on files BY NAME and ships to
# dist/claude-code/; the carve-out is 33 chars against QUALIFIER_MAX_CHARS = 34 and
# qualifier() drops rather than truncates, so a reword deletes it after prompt one.
check_token_present 'rules/phase-discipline.md' "hooks/inject-context.sh"
check_token_present 'unless it is trivial or read-only' "rules/phase-discipline.md"

yellow "[38b] the always-on injector is session-aware, not per-prompt"
# v0.11.0. additionalContext persists in the transcript, so re-injecting the
# same rules text every prompt cost ~64k tokens over a long session and bought
# nothing. The injector now sends the full text on the first prompt, a pointer
# after, and a full refresh every Nth prompt. Two ways this rots: the companion
# disappears (silently reverting to per-prompt injection via the jq degrade
# path), or a failure path starts emitting NOTHING instead of the full text.
INJECT_PY="hooks/inject_context.py"
check_file "$INJECT_PY"
for tok in 'session_id' 'is_refresh_turn' 'pointer_text'; do
  check_token_present "$tok" "$INJECT_PY"
done
check_token_present "inject_context.py" "hooks/inject-context.sh"
# The degrade contract: no session identity, unreadable state, or unparseable
# stdin must fall back to the FULL body, never to an empty injection.
if grep -qF 'return body' "$INJECT_PY"; then
  green "  ok   $INJECT_PY degrades to the full rules body"
else
  red "  FAIL $INJECT_PY has no full-body degrade path (a failure would drop the law)"
  FAILED=$((FAILED + 1))
fi
check_file "hooks/test_inject_context.sh"

yellow "[39] performance review surfaces registered (Reviewer D agent + perf-scout wiring)"
check_file "agents/code-reviewer-performance.md"
check_token_present "perf-scout.md" "skills/hackify/SKILL.md"

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
for f in "$P5_PHASE_G" "$RAV_G" "$ORCH_G" "$ESC_G" "$QUICK_G" $PANEL_AGENTS "skills/hackify/SKILL.md" "skills/yolo/SKILL.md" "$LEDGER" "$CONTRACT" "$P25_PHASE" "$WORK_DOC_TPL"; do
  # One grep per file for the whole list, same verdict lines: see 00-helpers.sh.
  check_no_tokens_in "$f" 'A, B, C, D and F' 'A, B, C and F' 'A, B, C and D' 'B, C, D and F' 'as a sixth' 'Cap at 6' 'cap of 6' 'FOUR foreground reviewers' 'FIVE foreground reviewers' 'A, B, D and F always' 'five baseline Phase 5 reviewers' 'five-to-six reviewers' 'five-to-six-parallel' '5-to-6-reviewer' '5-6 reviewers' '5-to-6 parallel reviewers' '3 parallel reviewers' 'Dispatch 2 foreground reviewers' 'Parallel agents scrutinize' 'Cap B at' 'B/C/F' '3 reviewers' '2 reviewers'
done

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

P3_PHASE="skills/hackify/references/phases/phase-3-implement.md"
P5_PHASE="skills/hackify/references/phases/phase-5-review.md"
REFUTE_TPL="skills/hackify/references/parallel-agents/phase-5-refute.md"
DEPS_TPL="skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md"

# (1) Implementers batch by MODULE and are capped at 3. An uncapped batch is one
# agent holding more context than it can apply carefully, and a batch grouped by
# count rather than module pays the focus cost while saving no reads at all.
for f in "agents/wave-task-implementer.md" "skills/hackify/references/parallel-agents/phase-3-implementation.md"; do
  check_token_present '{{task_ids}}' "$f"
  check_token_present '{{task_descriptions}}' "$f"
done
check_token_present 'Cap a batch at 3 tasks' "$P3_PHASE"
check_token_present 'Group by module, never by count' "$P3_PHASE"
for f in "agents/spec-reviewer.md" "$DEPS_TPL"; do
  check_token_present 'Cap a batch at 3 tasks' "$f"
done

# (2) A batch STOPS at the first task it cannot finish. Without this a batched
# failure cascades: one bad task takes the rest of the batch down with it, which is
# the whole reason one-agent-per-task felt safe.
for f in "agents/wave-task-implementer.md" "skills/hackify/references/parallel-agents/phase-3-implementation.md"; do
  check_token_present 'STOP there' "$f"
done

# (3) The second refuter is conditional ONLY because a Critical needs both refuters
# to die. If that rule ever weakens to "one refutation kills a Critical", skipping
# the second refuter stops being free and starts deleting real defects.
check_token_present 'dies only when' "$REFUTE_TPL"
check_token_present 'only if the 1st refutes' "$REFUTE_TPL"
check_token_present 'identical either way' "$REFUTE_TPL"

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
