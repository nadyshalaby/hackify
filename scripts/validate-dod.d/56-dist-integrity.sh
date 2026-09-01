# shellcheck shell=bash

# [56] Shipped-content integrity, every file the sync COPIES into dist/<runtime>/
# is byte-identical to the canonical source it was copied from.
#
# WHY THIS EXISTS: nothing compared shipped content against source. [24] asks
# whether `sync-runtimes.sh --dry-run` still PLANS a write into all seven runtime
# targets, and [55] asks whether every canonical file is NAMED in the sync
# manifest. Both are about the plan. Neither opens a shipped file, so a dist/ tree
# that is a hundred commits behind its source, or one file of which was edited by
# hand, passed the whole validator with nothing to say about it.
#
# MEASURED ON THE TREE THAT SHIPPED THIS CHECK, not imagined: at the commit this
# block was written, 68 of the 791 compared files were stale, carrying 13 source
# files as they read four hours and three commits earlier. The worst of them was
# the Phase 3 implementer mirror, then shipped as
# dist/claude-code/agents/wave-implementer.md and 3,114 bytes behind, still
# telling a wave agent the round-end scout scope was the allowlist union after
# the tree had stopped saying so. A runtime installing from dist/ got the pre-fix
# contract. The sprint's own task for re-syncing was ticked. That mirror is now
# agents/implementer.md, which changes the path in the story and nothing about
# what the story is evidence for: this check discovers every pair from the sync
# plan and the manifest, so it followed the rename with no edit.
#
# WHY NOT RE-RUN THE SYNC INTO A TEMPORARY ROOT AND DIFF THAT. It was the first
# design and it does not exist to build: sync-runtimes.sh takes no destination
# flag, it derives REPO_ROOT from its own BASH_SOURCE, and every emitter writes to
# the literal `dist/${runtime}/...` (scripts/sync-runtimes.d/00-helpers.sh:259).
# Retargeting it means copying the whole canonical tree somewhere else and running
# the script from there, which is ~800 writes to check ~800 files. Comparing the
# shipped bytes against the source bytes answers the same question with no writes
# at all, and no stored hashes to go stale.
#
# THE PLAN IS READ FROM THE SYNC SCRIPT, NEVER RESTATED HERE. The destination set
# comes from `--dry-run`, so the `dist/<runtime>/<source path>` layout lives in
# exactly one place, the same call [55] makes when it reads MIRROR_SOURCES out of
# the helper instead of keeping a second copy. A future emitter that lays its
# files out differently is covered without editing this fragment.
#
# WHAT IS NOT COMPARED, COUNTED AND PRINTED RATHER THAN LEFT SILENT. Seven of the
# 798 planned files are written from a heredoc rather than copied, so no canonical
# source exists to compare them against: five are inline in their emitter
# (claude-code, codex-cli, codex-app and opencode MANIFEST.md, gemini-cli
# GEMINI.md), dist/cursor/MANIFEST.md is piped from
# scripts/sync-runtimes.d/templates/cursor-manifest.md through the trailing-newline
# normalisation write_or_announce_heredoc applies, and dist/copilot-cli/MANIFEST.md
# is a concatenation of two template files around skills/hackify/SKILL.md. The
# first five have nothing to compare against. The last two do, modulo a transform,
# and they are the honest follow-up rather than a gap worth a wrong comparison.
# The count is ASSERTED, not merely printed. DI_GENERATED_EXPECT below pins it at
# seven and reddens on any other value, so an eighth exclusion fails the run that
# introduces it instead of widening a number on the pass line that nothing reads
# back. The pass line still carries it: the pin says the count is what it was,
# and the line is where a reader finds out what that count is.
#
# BATCHED, because 791 files is where a per-file subprocess starts costing real
# time. Two hashing invocations and two awk passes; a `cmp` per pair is 791 forks
# for the same answer.
#
# 0.18s AGAINST 791 FILES, and the command sits here because the number it
# replaced did not. This block used to read "measured at 0.2s" and the shipped
# fragment took 0.81s: the batching it describes was real, but the pair loop below
# accumulated two shell strings an append at a time, re-copying the whole
# accumulator 791 times each, and that alone outweighed everything else in the
# check. Median of five runs on a built tree after the array rewrite, 0.18s
# against 0.81s for the shipped form on the same tree, with:
#
#   bash scripts/sync-runtimes.sh   # [56] skips unless dist/ is built
#   time bash -c 'set -uo pipefail; FAILED=0
#   source scripts/validate-dod.d/00-helpers.sh
#   source scripts/validate-dod.d/56-dist-integrity.sh'
#
# Re-run that rather than adjusting the figure. A timing written into a comment
# goes stale exactly the way this one did, and it stayed wrong by 4x because
# nothing in the tree could contradict it.

yellow "[56] dist integrity, every file the sync copies into dist/<runtime>/ is byte-identical to its canonical source"

# Same subshell as [55], and for the same reason: the manifest arrays are read
# straight from the sync helper, whose function and variable definitions (red,
# green, write_*, RUNTIMES) must not clobber this validator's own.
DI_SOURCES=$(
  set +u
  . scripts/sync-runtimes.d/00-helpers.sh >/dev/null 2>&1
  printf '%s\n' "${MIRROR_SOURCES[@]}" "${CLAUDE_CODE_EXTRA[@]}"
)

# The plan, read from the shipped script. Its stdout is the only place the
# destination paths exist without this fragment restating the layout rule.
#
# THE PLANNER'S EXIT STATUS IS READ, AND ITS STDERR IS KEPT. Neither used to be.
# `2>/dev/null` with the status thrown away meant a planner that died partway
# through arrived here as a SHORT PLAN rather than as a failure: fewer pairs,
# every one of them comparing perfectly well, and the first branch to notice
# anything was the hash-count red below announcing that part of dist/ was never
# read. That line blames the shipped tree and the hasher for a defect in
# scripts/sync-runtimes.sh, which is the wrong component, and it only speaks at
# all when the truncation happens to land somewhere that changes the hash count.
# Reading rc here names the planner on the run that broke it.
#
# stderr is folded into the capture instead of discarded because every consumer
# below filters on the literal "WOULD WRITE: dist/", so a diagnostic line cannot
# be read as a destination, and on the failure path it is the only thing that
# says what actually went wrong. The planner's own red() prints to stdout, so
# its MISS lines were already in this capture; the two paths that use stderr
# (scripts/sync-runtimes.sh:54 and :65) are both fatal and both exit non-zero.
DI_READY=1
DI_PLAN_RC=0
DI_PLAN=$(bash scripts/sync-runtimes.sh --dry-run 2>&1) || DI_PLAN_RC=$?
if [ "$DI_PLAN_RC" -ne 0 ]; then
  red "  FAIL [56] scripts/sync-runtimes.sh --dry-run exited $DI_PLAN_RC, so the destination plan this check reads is a partial one and nothing below it is a verdict about dist/; the defect is in the planner, not in the shipped trees"
  printf '%s\n' "$DI_PLAN" | grep -vF 'WOULD WRITE: ' | grep -v '^$' | awk 'NR<=4' | sed 's/^/         - /'
  FAILED=$((FAILED + 1))
  DI_READY=0
fi
DI_DEST_TOTAL=$(printf '%s\n' "$DI_PLAN" | grep -c 'WOULD WRITE: dist/')

# A destination whose path-below-the-runtime IS a manifest entry was COPIED from
# that entry and is comparable. One that is not was generated from a heredoc and
# has no source to compare against. Emitted as "source|destination", the same
# separator scripts/sync_agent_mirrors.py --list uses for the same reason: no path
# in this tree contains it, so ${x%%|*} and ${x#*|} split it below without a
# literal tab and without the subshell a per-line `read` would cost.
DI_PAIRS=$(awk 'FNR == NR { if (NF) src[$0] = 1; next }
  {
    if (index($0, "WOULD WRITE: dist/") == 0) next
    dest = $0
    sub(/^.*WOULD WRITE: /, "", dest)
    rest = dest
    sub(/^dist\/[^\/]+\//, "", rest)
    if (rest in src) printf "%s|%s\n", rest, dest
  }' <(printf '%s\n' "$DI_SOURCES") <(printf '%s\n' "$DI_PLAN"))

# ACCUMULATED INTO AN ARRAY, NEVER A GROWING STRING, and this is the whole
# runtime of the check. `s="$s$line\n"` re-copies the entire accumulator on every
# append, so 791 appends move ~30KB about 791 times: rules/performance.md:45 files
# it as perf.algorithmic.string-concat-loop, severity I, remedy "Collect parts in
# an array/list; join once after the loop". Measured on this fragment before the
# rewrite, the two concatenating loops alone were 0.669s of a 0.857s check.
#
# BASH 3.2 IS THE FLOOR, not bash 4. macOS still ships 3.2.57 and this validator
# runs on developer machines as well as on the CI image, so `mapfile`/`readarray`
# are out and `arr+=("$x")` is the portable append. The other 3.2 trap is that
# scripts/validate-dod.sh sets `-u` in its `set -uo pipefail` line, under which
# "${arr[@]}" on an EMPTY array is a fatal unbound-variable error rather than an
# empty expansion (fixed in 4.4).
#
# CITED BY CONSTRUCT AND NOT BY LINE, and the correction is worth more than the
# number it replaces. This pointer used to name line 149 of that file. The line
# it meant had moved twice in one session and was sitting at 237 by the time
# anyone opened it, and check [57] never noticed. Its content tier reads a cited
# location only where the citing text quotes a phrase behind a verb, or where the
# location has gone vacant; an UNPINNED number, which is nearly every citation in
# this tree, is still judged for existence alone, so any number inside a
# four-hundred-line file passes and [57]'s own coverage line is where the live
# split is printed. Worse, the target sits below that file's hand-written header
# manifest, so every fragment anyone adds moves it again and a corrected number
# goes stale on the next wave. The 99-work-doc-status-claims.sh row in that same
# header records the identical lesson about a CHANGELOG entry and reaches the
# same answer. A construct name cannot drift that way.
# DI_LIVE_PAIRS and DI_MISSING_LIST are both legitimately empty on a healthy
# tree, so every expansion below carries the ${arr[@]+"${arr[@]}"} guard. Dropping
# one aborts the whole validator mid-run rather than failing this check.
DI_PAIR_LIST=()
while IFS= read -r di_line; do
  [ -n "$di_line" ] || continue
  DI_PAIR_LIST+=("$di_line")
done <<DI_PAIRS_EOF
$DI_PAIRS
DI_PAIRS_EOF
DI_PAIR_N=${#DI_PAIR_LIST[@]}

# THE FLOOR IS JUDGED BEFORE ANYTHING IS COMPARED, the call 55-mirror-completeness.sh
# and 97-test-suites-reachable.sh both make at their own floors and both explain the
# same way: a comparison over a collapsed set has nothing to say, so letting it
# speak first prints a verdict about dist/ when the defect is in the discovery.
# THREE WAYS THIS SET COLLAPSES AND ALL THREE ARRIVE LOOKING CLEAN. The helper
# source can fail (a moved scripts/lib/colors.sh, a syntax error), leaving the
# arrays unset under `set +u` and every printf empty. The dry run can exit before
# planning anything. And the destination format could change, leaving the awk
# matching nothing. Each one ends in zero pairs, zero mismatches and a confident
# green over a comparison that never happened.
#
# TWO BOUNDS, TWO JOBS, and neither one can do the other's. The floor refuses a
# COLLAPSED discovery: a set that fell to zero, or near it, has nothing to say and
# must not print a verdict over it. The pin refuses a QUIET SHIFT: files leaving
# the compared set for the uncompared one, which a floor cannot see because a
# floor only ever looks down. Collapsing them into one bound loses a case each
# way, and the pin is the one that reaches a seven-file shift.
#
# THE FLOOR WAS 390 AGAINST A LIVE 791, WHICH IS MORE SLACK THAN IT EVER NEEDED.
# Half the shipped tree could stop being compared and this check would still print
# green. The slack only has to cover manifest churn, and churn is a handful of
# source files a wave at six destinations each. 700 leaves room for roughly 15
# source files to retire before it speaks, far more than a wave moves and far less
# than the half it used to ignore. A legitimate trim past it reddens naming this
# line, which is the same deliberate one-line bump the pin asks for, and is the
# point of both. The live total is printed on the pass line rather than restated
# here, for the reason 55-mirror-completeness.sh gives at its own: a count written
# into a comment goes stale on the next wave that adds a file.
DI_PAIR_FLOOR=700

# The exclusion set: planned destinations with no canonical source behind them,
# every one of them named in the WHAT IS NOT COMPARED block at the top of this
# fragment. Computed HERE rather than beside the pass line so the pin below runs
# even on a clone where dist/ has never been synced and the comparison itself is
# skipped. The plan is a property of the sync script, not of the shipped tree, so
# a check on the plan has no business waiting for a tree that may not exist.
DI_GENERATED=$((DI_DEST_TOTAL - DI_PAIR_N))

# SEVEN, and the header block names each one. Bump this ONLY together with that
# block, and only for a destination that genuinely has no canonical source: a
# COPIED file that quietly drops out of the manifest lands in this same count and
# arrives looking exactly like a new heredoc, which is the whole reason the number
# is pinned instead of printed.
DI_GENERATED_EXPECT=7

# Both bounds are gated on DI_READY so a dead planner reddens ONCE, naming
# itself, instead of three times: a truncated plan collapses the pair count and
# moves the exclusion too, and two more reds about the consequences would bury
# the one line that names the cause.
if [ "$DI_READY" -eq 1 ] && [ "$DI_PAIR_N" -lt "$DI_PAIR_FLOOR" ]; then
  red "  FAIL [56] the sync plan and the manifest agreed on only $DI_PAIR_N comparable file(s) against a floor of $DI_PAIR_FLOOR (the dry run planned $DI_DEST_TOTAL destination(s)); the discovery collapsed rather than dist/ being clean, so no shipped file was compared against its source"
  FAILED=$((FAILED + 1))
  DI_READY=0
fi

# THE COMPARISON IS ABANDONED ON A MOVED PIN RATHER THAN NARROWED, because the
# pass line below does not merely count the exclusions, it says what they ARE:
# "written from a heredoc, carry no canonical source". Let the comparison run over
# whatever survived and that sentence becomes false for every file that fell out
# of the manifest, and the check would ship a green whose parenthetical is the
# defect. A number this fragment cannot account for means the discovery no longer
# matches what the pairing believes it is comparing, which is the floor's own
# reason for refusing to speak.
if [ "$DI_READY" -eq 1 ] && [ "$DI_GENERATED" -ne "$DI_GENERATED_EXPECT" ]; then
  red "  FAIL [56] $DI_GENERATED of the $DI_DEST_TOTAL planned destination(s) have no canonical source to compare against, against the $DI_GENERATED_EXPECT this check pins ($DI_PAIR_N pair(s) matched the manifest); either an emitter began writing a file from a heredoc, or a file the sync used to COPY left the manifest and is now shipped with nothing checking it. Name it in the WHAT IS NOT COMPARED block at the top of scripts/validate-dod.d/56-dist-integrity.sh and bump DI_GENERATED_EXPECT, or put it back in the manifest"
  FAILED=$((FAILED + 1))
  DI_READY=0
fi

# THE SKIP IS A PRINTED LINE AND NEVER A SILENT PASS, matching the dist/ branch
# 57-doc-links.sh already carries: dist/ is gitignored wholesale (`*` plus
# `!.gitignore`), so a fresh clone has the directory and none of the trees, and a
# clone that has never synced must not read as either clean or broken. The runtime
# names come from the plan rather than from a second list.
if [ "$DI_READY" -eq 1 ]; then
  DI_BUILT=0
  while IFS= read -r di_rt; do
    [ -n "$di_rt" ] || continue
    [ -d "dist/$di_rt" ] && DI_BUILT=$((DI_BUILT + 1))
  done <<DI_RT_EOF
$(printf '%s\n' "$DI_PLAN" | grep -oE 'WOULD WRITE: dist/[^/]+/' | sed 's|.*dist/||; s|/$||' | sort -u)
DI_RT_EOF
  if [ "$DI_BUILT" -eq 0 ]; then
    yellow "  skip no dist/<runtime>/ tree is built, run scripts/sync-runtimes.sh to cover the shipped copies ($DI_PAIR_N would be compared)"
    DI_READY=0
  fi
fi

# A destination that is not on disk is reported as missing rather than handed to
# the hasher, which would exit non-zero over the whole batch and lose every other
# verdict with it. `[ -f ]` is a builtin, so the 791 tests cost no processes.
#
# THE TWO CATEGORIES ARE KEPT DISJOINT, and they were not when this was first
# written: a missing destination stayed in the list the comparison read, so it was
# counted once as missing and again as unreadable, and one deleted file was
# reported as two defects on two lines. A pair with a side that is not there has
# nothing to compare, so it leaves the comparison set here and is carried by the
# missing count alone.
DI_MISSING=0
DI_MISSING_LIST=()
DI_HASH_LIST=()
DI_LIVE_PAIRS=()
if [ "$DI_READY" -eq 1 ]; then
  # The pairs are already in DI_PAIR_LIST, so this walks the array rather than
  # re-reading the heredoc a second time.
  for di_line in ${DI_PAIR_LIST[@]+"${DI_PAIR_LIST[@]}"}; do
    di_src=${di_line%%|*}
    di_dst=${di_line#*|}
    [ -n "$di_dst" ] || continue
    if [ -f "$di_dst" ]; then
      DI_HASH_LIST+=("$di_dst")
      DI_LIVE_PAIRS+=("$di_src|$di_dst")
    else
      DI_MISSING=$((DI_MISSING + 1))
      DI_MISSING_LIST+=("         - $di_dst (planned from $di_src)")
    fi
  done
fi

# One hasher, chosen once, and NO fallback to a weaker digest. shasum ships with
# perl on macOS and on the CI image; sha256sum is the coreutils spelling. Both
# print `<digest>  <path>`, which is what the comparison below reads. Neither
# present is a check that cannot run, and that is a red: a shipped file nobody
# could hash must never be the reason dist/ prints green.
di_hash_stdin() {
  if command -v shasum > /dev/null 2>&1; then
    xargs -0 shasum -a 256
  else
    xargs -0 sha256sum
  fi
}

if [ "$DI_READY" -eq 1 ] \
   && ! command -v shasum > /dev/null 2>&1 \
   && ! command -v sha256sum > /dev/null 2>&1; then
  red "  FAIL [56] neither shasum nor sha256sum is on PATH, so no shipped file was compared against its source; this run says nothing about whether dist/ matches the tree"
  FAILED=$((FAILED + 1))
  DI_READY=0
fi

if [ "$DI_READY" -eq 1 ]; then
  # Sources are deduplicated because one canonical file is copied into as many as
  # seven destinations, and hashing it seven times buys nothing.
  DI_HASH_INPUT=$( { printf '%s\n' "$DI_SOURCES" | sort -u; printf '%s\n' ${DI_HASH_LIST[@]+"${DI_HASH_LIST[@]}"}; } | grep -v '^$')
  DI_HASH_WANT=$(printf '%s\n' "$DI_HASH_INPUT" | grep -c .)
  DI_HASHES=$(printf '%s\n' "$DI_HASH_INPUT" | tr '\n' '\0' | di_hash_stdin 2>/dev/null)
  DI_HASH_GOT=$(printf '%s\n' "$DI_HASHES" | grep -c '  ')
  if [ "$DI_HASH_GOT" -ne "$DI_HASH_WANT" ]; then
    # FAIL CLOSED ON A DIGEST THAT NEVER RAN. xargs may split a long list across
    # several invocations and a hasher that dies on one of them takes a whole
    # batch of files out of the comparison silently, which would leave every pair
    # in that batch unexamined and every other pair still printing a verdict.
    red "  FAIL [56] hashed $DI_HASH_GOT file(s) of the $DI_HASH_WANT the comparison needs, so part of dist/ was never read and a clean result over the rest would be a count of nothing"
    FAILED=$((FAILED + 1))
    DI_READY=0
  fi
fi

if [ "$DI_READY" -eq 1 ]; then
  DI_REPORT=$(awk 'FNR == NR {
      gap = index($0, "  ")
      if (gap) hash[substr($0, gap + 2)] = substr($0, 1, gap - 1)
      next
    }
    {
      bar = index($0, "|")
      if (!bar) next
      s = substr($0, 1, bar - 1)
      d = substr($0, bar + 1)
      n++
      if (!(s in hash)) { print "UNREAD|" s; bad++ }
      else if (!(d in hash)) { print "UNREAD|" d; bad++ }
      else if (hash[s] != hash[d]) { print "DRIFT|" d " (differs from " s ")"; bad++ }
    }
    END { printf "TOTAL %d %d\n", n, bad + 0 }' \
    <(printf '%s\n' "$DI_HASHES") <(printf '%s\n' ${DI_LIVE_PAIRS[@]+"${DI_LIVE_PAIRS[@]}"}))
  DI_COMPARED=$(printf '%s\n' "$DI_REPORT" | awk '/^TOTAL /{print $2}')
  DI_BAD=$(printf '%s\n' "$DI_REPORT" | awk '/^TOTAL /{print $3}')
  if [ "$DI_BAD" -eq 0 ] && [ "$DI_MISSING" -eq 0 ]; then
    green "  ok   all $DI_COMPARED file(s) the sync copies into $DI_BUILT built dist/<runtime>/ tree(s) are byte-identical to their canonical source ($DI_GENERATED planned file(s) are written from a heredoc, carry no canonical source, and are not compared)"
  else
    # The remedy is named without backticks on purpose: inside a double-quoted
    # red line they would be command substitution, and this validator would RUN
    # the sync it is reporting on, editing the tree it audits at the moment it
    # decides that tree is wrong.
    red "  FAIL dist/ ships $DI_BAD file(s) that differ from the canonical source they were copied from and $DI_MISSING the sync plans but never wrote, out of $DI_COMPARED compared; the shipped trees are stale or hand-edited, and running scripts/sync-runtimes.sh is what repairs them"
    printf '%s\n' "$DI_REPORT" | grep -E '^(DRIFT|UNREAD)\|' | awk 'NR<=6' | sed 's/^[A-Z]*|/         - /'
    [ ${#DI_MISSING_LIST[@]} -gt 0 ] && printf '%s\n' "${DI_MISSING_LIST[@]}" | awk 'NR<=6'
    FAILED=$((FAILED + 1))
  fi
fi
