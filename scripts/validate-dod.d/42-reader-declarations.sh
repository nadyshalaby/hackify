# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [42] THE REQUIRED READING CONTRACT, BACKWARD: A FILE THAT DECLARES A READER IS
# NAMED BY THAT READER'S TEMPLATE.
#
# THE HALF [41] CANNOT REACH. [41] reads a template and asks whether its own list
# is well formed: header present, anchored, resolving. Every one of those
# questions is answered from inside the template, so a template whose list is
# perfect and SHORT passes it completely. The defect this round was opened to
# close lives in the gap that leaves: a rule file states that some agent loads
# it, the agent's template never names the file, and nothing anywhere compares
# the two. Both halves were false when this contract was written, and both were
# green.
#
# ONE ROW PER DECLARATION, AND EVERY COLUMN IS RE-READ EVERY RUN:
#   1 the file that DECLARES a reader
#   2 the verbatim sentence in it that makes the declaration
#   3 the file the declared reader is told to load
#   4 the template whose REQUIRED READING list must therefore name it
#
# THE AUTHORITY IS RE-READ AND NEVER TRUSTED, the discipline
# 58-contradiction-miner.sh states for its own routing table. Column 2 is looked
# up in column 1 on every run, and a row whose sentence has GONE reds as STALE
# rather than going on policing a declaration the repo may have deliberately
# retired. Without that, this table becomes a second and quieter source of law
# than the files it claims to be reading, which is the failure mode a manifest
# has and a scan does not.
#
# HOW THIS BACKWARD DIRECTION DIVIDES FROM [41], on a real seam and not at a line
# count: [41] asks whether a TEMPLATE's list is well formed, this asks whether a file
# DECLARING a reader is named by that reader's template. Neither is a subset of the
# other, since a perfectly formed list can omit a file declaring it governs the role.
# What this one LEANS on [41] for is the equivalence below, named here with its gap.
#
# WHY A SUBSTRING TEST AND NOT A SECOND COPY OF [41]'S PARSER. Column 4 is
# satisfied by finding the backticked, plugin_root-anchored path anywhere in the
# template, and the grep is over the WHOLE FILE. Inside the fenced prompt that is
# equivalent to "on the REQUIRED READING list", because [41] assertion (h) reds
# on an anchored path cited anywhere else in that fence, so within a green [41]
# the two questions have one answer. THE EQUIVALENCE IS A DEPENDENCY: if (h) is
# ever weakened, this test widens with it and must become a real parse.
#
# ONE GAP IN THAT EQUIVALENCE, MEASURED RATHER THAN ASSUMED AWAY. Prose OUTSIDE
# the fence is the parent's own commentary, which template-contract.md says may
# cite freely, and (h) never reads it. So an anchored citation sitting only in a
# template's parent-side tail would satisfy this grep while binding no agent.
# Counted across all 13 dispatchable templates, which is [41]'s corpus and, since the
# resolver below reaches the literal too, now this fragment's, re-measured this round:
# ZERO such citations, so the hole is real but currently empty, and it is UNGUARDED,
# no check watches it. A template that starts citing anchored paths in its tail makes
# this test weaker with nothing going red, which is why the number is written here to
# be re-measured rather than left as a reassurance.
#
# What the grep buys is one line instead of a duplicated fence tokenizer, and a
# duplicated tokenizer is two things to keep in step.
#
# WHAT THIS DOES NOT REACH, stated plainly because a backward check that only
# ever inspects a manifest nobody updates is the same rot in a new place. IT
# READS THE ROWS BELOW AND NOTHING ELSE. A file that starts declaring a reader
# tomorrow, in prose no row names, is NOT caught: nothing here mines arbitrary
# English for reader declarations, and the two seed cases show why that would be
# hopeless, one being a markdown table cell and the other a subordinate clause
# inside a paragraph about something else. What the rows DO buy is that a
# declaration cannot silently stop being true and the table cannot silently stop
# agreeing with the templates. Adding a row is a human act; this paragraph is the
# standing notice that it is owed, and the count is printed every run so the
# table cannot shrink unseen.
#
# NOTHING READ OUT OF A REPO FILE IS EXECUTED OR EXPANDED. Every row is a literal
# in this file, held in SINGLE quotes so the backticks a sentence carries stay
# backticks, and every lookup is `grep -F`, a fixed string, never a pattern built
# from a document's contents.
yellow "[42] every file that declares a hackify agent loads it is named by that agent's REQUIRED READING list"

# Columns are separated by a vertical bar, which no column may contain. Single
# quotes throughout: a sentence carrying backticks is data here, not a command.
#
# ONE ROW PER DECLARED READER, AND THE POLICY COVERS THE WHOLE TABLE. Every
# reader a declaring paragraph names is pinned below, with one class of
# exception named further down. NO SOURCE IS PINNED ON A SUBSET of its readers
# any more. An earlier revision pinned rules/security.md and rules/performance.md
# on one reader each and defended that as acceptable where the file was already
# bound somewhere, on the argument that one row proves the declaration is live
# and the rest are cheap to eyeball. The argument does not survive the defect it
# was written beside, and the readers it excused are written out in full here.
#
# BREADTH WAS THE DEFECT, and that half of the old argument still stands.
# rules/expert-mindset.md, the always-on stub, said the fuller doctrine lived in
# skills/hackify/references/expert-mindset.md and twelve templates pointed agents
# at the stub; the fuller file sat on ZERO reading lists, so twelve agents were
# told a file governed them and none was told to open it. A subset pin reopens
# exactly that hole for whichever readers the subset leaves out: they could drop
# the entry and nothing here would redden. Closing it for one file while leaving
# it open for the next is not closing it, which is why the pin is now total.
#
# THE EXCEPTION IS A READER THAT IS NOT A TEMPLATE, a resolver limit rather than
# a judgment call. Column 4 must name a file [41] scans, so a row is writable
# only for a reader dispatched from a prompt that carries a REQUIRED READING
# list. The declarations also name surfaces carrying none, and those stay
# unpinned: lawkeeper's categories, law-scout's semantic tier, the deterministic
# perf-scout, the quick mirror, and the orchestrating parent, which opens a file
# because the workflow tells it to rather than because a list binds it. Nothing
# here watches those, and nothing here can.
#
# COLUMN 2 IS A PHRASE FROM THE DECLARING PARAGRAPH AND NOWHERE ELSE IN THAT
# FILE, which is what gives the STALE rule above something to catch. Two live
# traps show why it has to be checked per row rather than assumed: the hat table
# inside skills/hackify/references/expert-mindset.md says "Phase 5 Reviewer D"
# and "Phase 4" in its own prose, and the load-by-role table in
# rules/test-scenarios.md says "Phase 5 Reviewer B" in its own. A row keyed on
# either phrase stays green with the declaration deleted, policing nothing, and
# the test-scenarios row WAS keyed that way until it was lengthened to reach into
# the declaring sentence. Every fragment below was grepped back and occurs
# exactly once in its own source. A reader dropped from the declaration reds its
# row as stale; a template that drops the entry reds on column 4.
RD_ROWS=(
  'rules/test-scenarios.md|Phase 3 testing-wave agent (`test-authoring`)|rules/test-scenarios.md|phase-3-implementation.md'
  'rules/test-scenarios.md|Phase 5 Reviewer B (re-judging every|rules/test-scenarios.md|phase-5-multi-review-b-quality-plan.md'
  'rules/test-scenarios.md|the merged all-lens reviewer at its quality pass|rules/test-scenarios.md|phase-5-multi-review-merged.md'
  'skills/hackify/references/clarify-questions/wizard-contract.md|Phase 3 implementers do|skills/hackify/references/anti-patterns.md|phase-3-implementation.md'
  'rules/security.md|Phase 3 implementers (before touching auth|rules/security.md|phase-3-implementation.md'
  'rules/security.md|Phase 5 Reviewer A (security)|rules/security.md|phase-5-multi-review-a-security.md'
  'rules/security.md|the Phase 5 escalation specialist when the lens|rules/security.md|phase-5-escalation.md'
  'rules/security.md|the merged all-lens reviewer at its security pass|rules/security.md|phase-5-multi-review-merged.md'
  'rules/performance.md|Phase 3 implementers (before touching data access|rules/performance.md|phase-3-implementation.md'
  'rules/performance.md|Phase 5 Reviewer D (performance)|rules/performance.md|phase-5-multi-review-d-performance.md'
  'rules/performance.md|the Phase 5 finding refuter|rules/performance.md|phase-5-refute.md'
  'rules/performance.md|the merged all-lens reviewer at its performance pass|rules/performance.md|phase-5-multi-review-merged.md'
  'rules/performance.md|the Phase 5 adjudication reviewer|rules/performance.md|review-and-verify.md'
  'rules/four-principles.md|Phase 3 implementers (Surgical Changes bounds the diff to the file allowlist|rules/four-principles.md|phase-3-implementation.md'
  'rules/four-principles.md|Phase 5 Reviewer B (Simplicity First is its scope-creep lens|rules/four-principles.md|phase-5-multi-review-b-quality-plan.md'
  'skills/hackify/references/expert-mindset.md|the codebase investigator|skills/hackify/references/expert-mindset.md|investigation.md'
  'skills/hackify/references/expert-mindset.md|the spec reviewer at Phase 2.5|skills/hackify/references/expert-mindset.md|phase-2.5-spec-reviewer.md'
  'skills/hackify/references/expert-mindset.md|the implementer at Phase 3|skills/hackify/references/expert-mindset.md|phase-3-implementation.md'
  'skills/hackify/references/expert-mindset.md|the cross-package verifier at Phase 4|skills/hackify/references/expert-mindset.md|phase-4-cross-package-verification.md'
  'skills/hackify/references/expert-mindset.md|A on security|skills/hackify/references/expert-mindset.md|phase-5-multi-review-a-security.md'
  'skills/hackify/references/expert-mindset.md|B on quality and plan|skills/hackify/references/expert-mindset.md|phase-5-multi-review-b-quality-plan.md'
  'skills/hackify/references/expert-mindset.md|D on performance|skills/hackify/references/expert-mindset.md|phase-5-multi-review-d-performance.md'
  'skills/hackify/references/expert-mindset.md|E on design conformance|skills/hackify/references/expert-mindset.md|phase-5-multi-review-e-design.md'
  'skills/hackify/references/expert-mindset.md|F on cross-module coherence|skills/hackify/references/expert-mindset.md|phase-5-multi-review-f-coherence.md'
  'skills/hackify/references/expert-mindset.md|the merged all-lens reviewer|skills/hackify/references/expert-mindset.md|phase-5-multi-review-merged.md'
  'skills/hackify/references/expert-mindset.md|the finding refuter|skills/hackify/references/expert-mindset.md|phase-5-refute.md'
  'skills/hackify/references/expert-mindset.md|the escalation specialist|skills/hackify/references/expert-mindset.md|phase-5-escalation.md'
  'skills/hackify/references/expert-mindset.md|the adjudication reviewer|skills/hackify/references/expert-mindset.md|review-and-verify.md'
)

# The list's LENGTH written a SECOND time, the pin check_list_size exists for and
# the same one [80] carries over CAP_APPEND_ONLY. Deleting an inconvenient row
# cannot land without also editing this number, which is the line a reviewer
# actually reads.
RD_ROWS_EXPECTED=28

# THE CORPUS IS A DIRECTORY PLUS ONE LITERAL, WHICH IS [41]'S CORPUS AND NOT A
# SUBSET OF IT. review-and-verify.md carries a fenced prompt with an INPUTS section
# and a REQUIRED READING list while living OUTSIDE parallel-agents/, so [41] scans
# it as a literal beside the glob. Pinning column 4 to the directory alone made a
# row naming that reader unwritable: it would red with "not a template", which
# accuses the table of a fault that is this fragment's. A backward check that cannot
# reach a template the forward check governs leaves that template's declarations
# unpoliced with nothing going red, so the two resolve the same set.
RD_TPL_DIR="skills/hackify/references/parallel-agents"
RD_TPL_EXTRA="skills/hackify/references/review-and-verify.md"
RD_TPL=""
RD_BAD=0

# Column 4 is a BASENAME, so the literal is matched on its own basename and every
# other name resolves under the directory. No fork: this is called once per row.
rd_tpl_path() {
  if [ "$1" = "${RD_TPL_EXTRA##*/}" ]; then
    RD_TPL="$RD_TPL_EXTRA"
  else
    RD_TPL="$RD_TPL_DIR/$1"
  fi
}

rd_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
  RD_BAD=$((RD_BAD + 1))
}

# grep TELLS "FOUND NONE" FROM "COULD NOT LOOK", 00-helpers.sh's rule above
# check_no_token. 0 is a hit, 1 is a clean miss, 2 and above is a search that
# never happened, and a count of zero taken off the third is a count of nothing.
# /usr/bin/grep by absolute path for the reason check_no_tokens_in gives: under
# the interactive shell in this environment a bare `grep` is a function honouring
# ignore files, and a search that skips a file is a search that clears it.
rd_holds() {
  /usr/bin/grep -qF -- "$1" "$2" 2> /dev/null
  case $? in
    0) return 0 ;;
    1) return 1 ;;
    *) rd_fail "[42] could not read $2 while looking for a declaration, so a clean result from it would be a count of nothing"
       return 1 ;;
  esac
}

# ONE ROW, ONE PARAMETER. The four columns arrive as one bar-separated string
# rather than four arguments, which keeps this inside the 3-parameter hard cap
# and keeps the row a single value the controls below can hand over unchanged.
rd_row() {
  local source sentence target template
  IFS='|' read -r source sentence target template <<<"$1"
  if [ ! -f "$source" ]; then
    rd_fail "[42] the reader table names $source, which is not a file; the row is stale and cannot be policing anything"
    return
  fi
  if ! rd_holds "$sentence" "$source"; then
    rd_fail "[42] $source no longer says '$sentence', so the row binding it to $template is stale; re-read the file and drop or reword the row rather than going on enforcing a declaration the repo may have retired"
    return
  fi
  [ -f "$target" ] || rd_fail "[42] $source declares that an agent loads $target, which is not a file in this plugin"
  rd_tpl_path "$template"
  if [ ! -f "$RD_TPL" ]; then
    rd_fail "[42] the reader table points at $template, which is not a file at $RD_TPL; a row may name any template [41] scans, meaning $RD_TPL_DIR/*.md or the literal $RD_TPL_EXTRA"
  elif ! rd_holds '`{{plugin_root}}/'"$target"'`' "$RD_TPL"; then
    rd_fail "[42] $source declares a reader with '$sentence', but $template never names {{plugin_root}}/$target, so that agent is told the file governs it and is never told to open it"
  fi
}

# THE CONTROLS, AND THEY ARE NOT OPTIONAL. Everything this check prints on a
# healthy tree is a zero, and rules/claim-integrity.md is explicit that "a clean
# result is only as good as the method's ability to have returned a dirty one".
# So three fixtures are planted in a temp directory and the REAL rd_row runs over
# them: one healthy row that must stay silent, one whose declaring sentence is
# absent, and one whose template never binds the declared file. Identity, not
# DRY, is the point: a control that ran a different function would prove nothing
# about the one that judges the repo.
#
# THE FIXTURES LIVE IN A TEMP DIR AND NEVER IN THE TREE. Sibling tracks are
# writing this working tree, so a probe file planted under it would surface in
# another agent's diff with nobody claiming it.
# THE FIXTURES, PLANTED IN $1. Extracted from rd_control to hold it inside the 40-line
# hard cap, and the split is on a seam: this builds the tree, rd_control judges it.
#
# THE FOURTH FIXTURE SITS AT THE LITERAL AND NOT UNDER THE DIRECTORY, which is the whole
# of what it proves. Resolved the old way it is simply absent, so the row red with "not a
# template" and that reader went unpoliced; the control is silent only if rd_tpl_path
# really reached outside $RD_TPL_DIR to find it.
rd_plant() {
  mkdir -p "$1/$RD_TPL_DIR" "$1/${RD_TPL_EXTRA%/*}"
  printf 'A doc. Phase 3 implementers do load it.\n' > "$1/declaring.md"
  printf 'the target\n' > "$1/target.md"
  printf '1. `{{plugin_root}}/target.md`, bound.\n' > "$1/$RD_TPL_DIR/bound.md"
  printf '1. `{{plugin_root}}/other.md`, not the one.\n' > "$1/$RD_TPL_DIR/loose.md"
  printf '1. `{{plugin_root}}/target.md`, bound.\n' > "$1/$RD_TPL_EXTRA"
}

rd_control() {
  local dir rc=0 got
  dir=$(mktemp -d 2>/dev/null) || {
    rd_fail "[42] could not create the control fixtures, so this check never showed it can fail"
    return
  }
  rd_plant "$dir"
  # `cd` inside a subshell only, so the orchestrator's own working directory is
  # never disturbed for the fragments sourced after this one.
  got=$(
    cd "$dir" || exit 9
    RD_BAD=0
    FAILED=0
    rd_row 'declaring.md|Phase 3 implementers do|target.md|bound.md' > /dev/null
    printf '%s ' "$RD_BAD"
    RD_BAD=0
    rd_row 'declaring.md|Phase 5 Reviewer B|target.md|bound.md' > /dev/null
    printf '%s ' "$RD_BAD"
    RD_BAD=0
    rd_row 'declaring.md|Phase 3 implementers do|target.md|loose.md' > /dev/null
    printf '%s ' "$RD_BAD"
    RD_BAD=0
    rd_row "declaring.md|Phase 3 implementers do|target.md|${RD_TPL_EXTRA##*/}" > /dev/null
    printf '%s' "$RD_BAD"
  ) || rc=$?
  rm -rf "$dir"
  if [ "$rc" -ne 0 ]; then
    rd_fail "[42] the control fixtures could not be entered (rc $rc), so this check never showed it can fail"
  elif [ "$got" != "0 1 1 0" ]; then
    rd_fail "[42] the planted controls returned '$got' where '0 1 1 0' was required (a healthy row silent, a vanished declaration red, an unbound template red, a row naming the literal outside $RD_TPL_DIR silent), so this check does not behave as its header claims and its clean lines mean nothing"
  else
    green "  ok   [42] all 4 planted controls behaved as required, so a dirty result was reachable before the clean one below was trusted"
  fi
}

rd_control
check_list_size "${#RD_ROWS[@]}" "$RD_ROWS_EXPECTED" "the [42] reader-declaration table"
for rd_entry in "${RD_ROWS[@]}"; do
  rd_row "$rd_entry"
done
# NO GREEN BESIDE A RED, 91's rule: a summary that contradicts the failures above
# it is the fail-open shape this fragment exists to refuse.
if [ "$RD_BAD" -eq 0 ]; then
  green "  ok   all ${#RD_ROWS[@]} declared reader(s) are named by the REQUIRED READING list of the template that dispatches them"
fi
