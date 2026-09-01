# shellcheck shell=bash

# THE COVERAGE THIS SUITE OWED THE OTHER HALF OF THE VALIDATOR. Every case in the
# sibling fragments plants a BANNED token and requires a red. Nothing anywhere
# planted the opposite defect, a PRESENCE pin that stops existing, and nothing
# outside scripts/validate-dod.sh named a whole fragment. Both were measured
# rather than feared:
#
#   1. A refuter deleted the line pinning the canonical per-agent budget out of
#      82-throughput-and-routing.sh, ran the whole bar and ran this suite, and BOTH
#      printed green. The only number that moved was the validator's ok-line count,
#      1700 to 1699, against a floor of 1350 that will not notice a hundred more.
#   2. Deleting a fragment together with its `source` line and its header-manifest
#      row leaves [0] green as well, because [0]'s floor is "at least 15 of each"
#      and both sides of its comparison shrink together. Checks [83], [84] and [92]
#      were reachable from scripts/validate-dod.sh and from nothing else, so each
#      one could leave the run entirely on a three-line edit. THAT COVERED THREE OF
#      FORTY-TWO, which the wave that wrote [89] measured and reported about its own
#      work: the identical edit against any unnamed fragment passed this suite in
#      silence. The whole directory is swept now, and the hand-written total below is
#      the half of the sweep a deletion cannot shrink.
#
# WHY HERE AND NOT IN A VALIDATOR FRAGMENT. A fragment cannot pin its own presence:
# the edit that removes it removes the pin with it, which is the argument [0]'s own
# header makes about the check it cannot reach. The guard has to run from a process
# the validator does not start, and this suite is one, dispatched as its own CI step.
# Split out as the sixth fragment of a driver that has hit the 500-LOC cap twice.

# The fragment whose presence pins are inventoried, reached through the driver's
# own constant so a rename moves one line rather than two.
TB_PIN_SRC="$TB_SRC_82"

# The validator, read and never written. Named once here because three functions
# below take it as a parameter, which is what lets the control point them at a
# deliberately unwired copy instead.
TB_VALIDATOR="scripts/validate-dod.sh"

# COUNTED AND WRITTEN OUT, the same trade TB_EXPECT_70 makes and for the same
# reason: a bound derived from the file it polices drops with the file and stays
# green. Thirty-two is every non-comment check_token_present call site in that
# fragment, counted per OCCURRENCE rather than per line. A raw `grep -c` returns
# thirty-four, and the two extra are prose: one comment explaining that the matcher
# is case-sensitive and one explaining why the block beside it uses the flowed twin
# instead. Both start with `#` and both are skipped, which is checked rather than
# hoped: the control below removes a real call and requires the count to move.
TB_EXPECT_82_PINS=32

# AND THE SEVENTEEN THAT ARE NOT WRITTEN AS LITERALS, which a count of the literal
# helper alone would leave uncovered while reporting a clean scan. Wave A2 of this
# sprint traded a fifteen-iteration check_token_present loop for one
# check_tokens_present_in over an array, which is why that count read 35 at the
# commit the finding was raised against and reads 34 now: a CONVERSION reading as a
# DELETION is the same trap TB_EXPECT_CALLS documents on the ban side. So the
# batched presence helpers are counted apart and pinned apart, two call sites
# carrying seventeen tokens between them, and deleting either one moves this number
# rather than nothing.
TB_EXPECT_82_BATCHED=2

# THE COUNT ALONE WOULD MISS A SWAP. Delete one pin, add another, and thirty-two
# stays thirty-two. So the pins that carry the most are named as well, and each
# one is a whole block's live half: the two canonical budget digits [82] exists to
# keep in exactly one file, the [82f] token that is that block's ONLY assertion, and
# [82e]'s surviving enum value. A named pin cannot be traded away for a cheap one.
TB_REQUIRED_82_PINS=('Per-agent task budget: 20 tasks')
TB_REQUIRED_82_PINS+=('Concurrent-wave budget: 10 waves')
TB_REQUIRED_82_PINS+=('{{concurrent_wave_target}}')
TB_REQUIRED_82_PINS+=('test-authoring')

# The fragments named here carry a CHECK ID as well as a basename, which is the one
# thing the whole-directory sweep further down cannot ask for: that sweep reads a
# manifest row's existence, this reads what the row SAYS. Written out rather than
# globbed, because a list discovered from scripts/validate-dod.d/ goes empty at
# exactly the moment a fragment goes missing and then passes over nothing.
#
# [89] JOINED THEM, and the wave that wrote it raised the finding about its own work.
# Its manifest row is the only place outside the fragment that says which check
# 89-reviewer-rename.sh declares, and an agent-type rename is resolved at DISPATCH
# time, so a half-applied one ships a green bar; that is exactly the class of check
# that must not be able to leave the run on a three-line edit.
TB_COVERED_FRAGMENTS=("83-testing-stage-shape.sh [83]")
TB_COVERED_FRAGMENTS+=("84-no-pipe-into-grep-q.sh [84]")
TB_COVERED_FRAGMENTS+=("89-reviewer-rename.sh [89]")
TB_COVERED_FRAGMENTS+=("92-work-doc-structure.sh [92]")
TB_EXPECT_COVERED=4

# ---------------------------------------------------------------------------
# THE WHOLE DIRECTORY, AND WHY FOUR NAMED ROWS ARE STILL NOT ENOUGH. The live count
# is the pin below and never this sentence, so no figure here is written twice: 47
# fragments ship in scripts/validate-dod.d/ today and four are named above, so the
# same three-line edit against any of the other 43, delete the fragment, its
# `source` line and its header-manifest row, left [0]'s at-least-15 floor green on
# both sides of its comparison, gave [76f] nothing to
# enumerate, and passed this suite in silence. Four hand-written rows is a better
# number than three and it is not a mechanism.
#
# DISCOVERY CANNOT CLOSE IT ALONE, WHICH IS THE DESIGN CONSTRAINT AND NOT A
# LIMITATION OF THIS ONE. A set read off scripts/validate-dod.d/ goes SHORT at
# exactly the moment a fragment is deleted, so a per-fragment loop over it agrees
# with the smaller tree and prints fewer greens. The only thing that reddens on a
# deletion is a bound written OUTSIDE the directory, which is the argument
# check_list_size makes in 00-helpers.sh: a bound derived from the list it polices
# cannot police that list. So the set is DISCOVERED, which means a fragment added
# tomorrow gets its wiring checked for free, and the TOTAL is written here by hand,
# which means a fragment deleted tomorrow reddens.
#
# EQUALITY AND NOT A FLOOR, deliberately, and against [0b]'s and [76i]'s reasoning
# for the opposite. Both of those police numbers that move on most waves, where an
# exact count gets bumped on reflex without being read. This directory gains a
# fragment a couple of times a sprint and loses one almost never, and every other
# bound in this suite is an equality bumped deliberately. A floor set at today's
# count would also decay in silence: at sixty fragments a floor of forty-seven
# tolerates thirteen deletions and reads exactly as green as it does today.
#
# WHAT BUMPING IT MEANS. A fragment added on purpose moves this number in the same
# change, the way TB_EXPECT_COVERED moves. A number bumped to make a red go away,
# without opening the fragment that left, is the edit this check exists to make
# somebody type out loud.
TB_FRAGMENT_DIR="scripts/validate-dod.d"
TB_EXPECT_FRAGMENT_TOTAL=47

# ---------------------------------------------------------------------------
# Writes one pinned token per line to $2 and prints the count to stdout. Exits
# non-zero on a file it cannot read or a line it cannot parse, because a parser
# that returns an empty list on a broken read is the measures-nothing shape.
#
# COMMENT LINES ARE DROPPED BEFORE ANYTHING IS COUNTED, and quoted spans are
# handed to shlex rather than a regex: three of the pinned tokens carry an
# apostrophe and are written in double quotes, one carries `{{`, `}}`, pipes and
# stars, and a regex that tried to read those would either miss them or split them.
# ---------------------------------------------------------------------------
tb_presence_pins() {
  python3 - "$1" "$2" <<'PINS'
import io, re, shlex, sys
src, out = sys.argv[1], sys.argv[2]
CALL = re.compile(r'\bcheck_token_present\s')
BATCHED = re.compile(r'\b(?:check_tokens_present_in|check_flowed_tokens_present_in'
                     r'|check_flowed_token_present)\s')
toks = []
batched = 0
try:
    lines = io.open(src, encoding="utf-8").readlines()
except (IOError, OSError) as exc:
    sys.exit("cannot read %s: %s" % (src, exc))
for n, line in enumerate(lines, 1):
    if line.lstrip().startswith("#"):
        continue
    batched += len(BATCHED.findall(line))
    m = CALL.search(line)
    if not m:
        continue
    try:
        parts = shlex.split(line[m.end():])
    except ValueError as exc:
        sys.exit("%s:%d does not parse as a shell call: %s" % (src, n, exc))
    if not parts:
        sys.exit("%s:%d calls check_token_present with no token" % (src, n))
    toks.append(parts[0])
if not toks:
    sys.exit("no check_token_present call site parsed from %s" % src)
with io.open(out, "w", encoding="utf-8") as fh:
    fh.write("".join(t + "\n" for t in toks))
sys.stdout.write("%d %d\n" % (len(toks), batched))
PINS
}

# The inventory itself, both halves. The count catches a deletion, which is the
# defect that was measured; the named pins catch the delete-one-add-one edit the
# count cannot see.
tb_check_presence_pins() {
  local pinfile="$TB_TMP/pins82.txt"
  local out n bn rc t missing=0
  out=$(tb_presence_pins "$TB_PIN_SRC" "$pinfile" 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    tb_bad "presence-pin inventory: the extractor refused $TB_PIN_SRC: $out"
    return
  fi
  read -r n bn <<<"$out"
  if [ "$bn" -ne "$TB_EXPECT_82_BATCHED" ]; then
    tb_bad "presence-pin inventory: $bn batched presence call(s) ship in $TB_PIN_SRC, expected $TB_EXPECT_82_BATCHED (the seventeen tokens they carry are pinned by nothing else outside the fragment, so a deleted call takes them all with it)"
    return
  fi
  tb_ok "presence-pin inventory: $bn batched presence calls ship in $TB_PIN_SRC, matching the expected $TB_EXPECT_82_BATCHED"
  if [ "$n" -ne "$TB_EXPECT_82_PINS" ]; then
    tb_bad "presence-pin inventory: $n presence pin(s) ship in $TB_PIN_SRC, expected $TB_EXPECT_82_PINS (a check_token_present call was added or DELETED; a deletion is the defect this pin exists for, so read the block it came out of before bumping TB_EXPECT_82_PINS)"
    return
  fi
  tb_ok "presence-pin inventory: $n presence pins ship in $TB_PIN_SRC, matching the expected $TB_EXPECT_82_PINS"
  for t in "${TB_REQUIRED_82_PINS[@]}"; do
    /usr/bin/grep -qxF -- "$t" "$pinfile" && continue
    tb_bad "presence-pin inventory: nothing in $TB_PIN_SRC pins '$t' any more, so the count above is being held up by a different pin"
    missing=$((missing + 1))
  done
  [ "$missing" -eq 0 ] || return
  tb_ok "presence-pin inventory: all ${#TB_REQUIRED_82_PINS[@]} named pins are among the $n that ship, so a delete-one-add-one edit cannot hold the count still"
}

# THE REFUTER'S EXPERIMENT, MADE EXECUTABLE. It deleted the canonical per-agent
# budget pin and watched everything stay green. This plants the same deletion into
# a copy and requires all three consequences: exactly one line leaves, the count
# drops by exactly one, and the deleted token stops being reported as pinned. A
# check widened past its own defect would pass the first and fail the last two.
tb_case_presence_pin_control() {
  local copy="$TB_TMP/82-pin-deleted.sh"
  local pinfile="$TB_TMP/pins82-deleted.txt"
  local victim="check_token_present 'Per-agent task budget: 20 tasks'"
  local before after out n bn want rc
  before=$(/usr/bin/grep -c '' "$TB_PIN_SRC" 2>/dev/null) || before=0
  /usr/bin/grep -vF -- "$victim" "$TB_PIN_SRC" > "$copy"
  after=$(/usr/bin/grep -c '' "$copy" 2>/dev/null) || after=0
  if [ "$((before - after))" -ne 1 ]; then
    tb_bad "presence-pin control: planting the deletion took $((before - after)) line(s) out of $TB_PIN_SRC, expected exactly 1, so the control is not planting what it says it plants"
    return
  fi
  tb_ok "presence-pin control: the plant removed exactly the one line carrying the canonical per-agent budget pin"
  out=$(tb_presence_pins "$copy" "$pinfile" 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    tb_bad "presence-pin control: the extractor refused the planted copy: $out"
    return
  fi
  read -r n bn <<<"$out"
  if [ "$bn" -ne "$TB_EXPECT_82_BATCHED" ]; then
    tb_bad "presence-pin control: deleting a literal pin moved the BATCHED count to $bn, expected $TB_EXPECT_82_BATCHED; the two counters are reading each other rather than failing apart"
    return
  fi
  want=$((TB_EXPECT_82_PINS - 1))
  if [ "$n" -ne "$want" ]; then
    tb_bad "presence-pin control: the planted copy counts $n presence pins, expected $want; the counter did not see the deletion, which is exactly the failure the inventory above exists to refuse"
    return
  fi
  tb_ok "presence-pin control: the deletion moves the count from $TB_EXPECT_82_PINS to $n, so the inventory above can fail"
  if /usr/bin/grep -qxF -- 'Per-agent task budget: 20 tasks' "$pinfile"; then
    tb_bad "presence-pin control: the planted copy still reports the deleted token as pinned, so the named-pin half cannot fail either"
    return
  fi
  tb_ok "presence-pin control: the deleted token is gone from the planted copy's pin list, so the named-pin half fails on the deletion too"
}

# ---------------------------------------------------------------------------
# All three halves of "this fragment is in the run": on disk, sourced, and named
# in the header manifest. Prints the first half that failed and returns 1; prints
# nothing and returns 0 when every half holds. The validator path is a parameter
# so the control can point it at a copy with the fragment stripped out.
#
# THE SOURCE LINE IS PARSED THE WAY [0] PARSES IT, `^source ` then the first
# `<digits>-<name>.sh` on the line, rather than matched as a literal. A literal
# would red on a reformatted source line, which is a reader looking at a file this
# suite does not own and must not make brittle.
#
# NO PIPE INTO grep, ANYWHERE BELOW. Check [84] bans it in scripts/ under the
# pipefail this driver sets at its head, and a SIGPIPE surfacing as 141 out of a
# coverage check would be the false green in miniature. Here-strings throughout.
# ---------------------------------------------------------------------------
tb_fragment_wired() {
  local base="$1"
  local id="$2"
  local self="$3"
  local sourced
  if [ ! -r "scripts/validate-dod.d/$base" ]; then
    printf 'scripts/validate-dod.d/%s is missing or unreadable' "$base"
    return 1
  fi
  sourced=$(tb_sourced_names "$self")
  if ! /usr/bin/grep -qxF -- "$base" <<<"$sourced"; then
    printf '%s has no source line naming %s, so every check in it is absent from the run and cannot fail it' "$self" "$base"
    return 1
  fi
  if ! /usr/bin/grep -qF -- "$base, check $id," "$self"; then
    printf "%s's header manifest has no row naming %s and check %s" "$self" "$base" "$id"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# THE THREE READERS THE SWEEP IS BUILT FROM, one per source of truth, each taking
# its path as a parameter so the control can point them at a copy.
#
# ONE PASS EACH, NEVER ONE PER FRAGMENT. Forty-three fragments times two greps is
# eighty-six processes for a question three answer, which is the spawn-per-item row
# in rules/performance.md and the same trade [40]'s wi_absent_all measured and took.
# Every membership test below is a shell `case` over a string these three built.
#
# NO PIPE ANYWHERE, which check [84] bans in scripts/ under this driver's pipefail.
# Here-strings and one process substitution, the shape flowed_flatten uses in
# 00-helpers.sh.
tb_fragment_names() {
  local d="$1" f n=0
  for f in "$d"/*.sh; do
    [ -f "$f" ] || continue
    n=$((n + 1))
    printf '%s\n' "${f##*/}"
  done
  [ "$n" -gt 0 ]
}

tb_sourced_names() {
  local sourced
  sourced=$(/usr/bin/grep -E '^source ' "$1" 2>/dev/null)
  /usr/bin/grep -oE '[0-9]+-[A-Za-z0-9._-]+\.sh' <<<"$sourced"
}

# The basename each header-manifest row OPENS with. Only the name is read, never
# what the row goes on to claim: the check id is the named-row list's question and
# a sweep that also demanded one would red on 00-helpers.sh, whose row legitimately
# describes printers rather than a check.
# AN ARRAY AND ONE printf, never a string grown per iteration: that is
# perf.algorithmic.string-concat-loop in rules/performance.md, and the driver here is
# a grep, so the row count is data rather than a bounded literal. Caught by this
# wave's own perf-scout over its own allowlist, in the first draft of this function.
tb_manifest_names() {
  local line n=0
  local -a names=()
  while IFS= read -r line; do
    line=${line#\#}
    line=${line#"${line%%[![:space:]]*}"}
    names[n]=${line%,}
    n=$((n + 1))
  done < <(/usr/bin/grep -oE '^#[[:space:]]+[0-9]+-[A-Za-z0-9._-]+\.sh,' "$1" 2>/dev/null)
  [ "$n" -eq 0 ] || printf '%s\n' "${names[@]}"
}

# One fragment against one already-built pair of haystacks. Prints the first half
# that failed and returns 1, prints nothing and returns 0 when both hold. The
# haystacks arrive newline-fenced on both ends so a `case` match is an exact whole
# line and `9-x.sh` cannot satisfy `89-x.sh`.
tb_fragment_swept() {
  local base="$1" src_hay="$2" row_hay="$3"
  case "$src_hay" in
    *$'\n'"$base"$'\n'*) ;;
    *) printf 'no source line names it, so every check it holds is absent from the run and cannot fail it'
       return 1 ;;
  esac
  case "$row_hay" in
    *$'\n'"$base"$'\n'*) ;;
    *) printf 'the header manifest has no row opening with its name, so the map a reader consults does not know it exists'
       return 1 ;;
  esac
  return 0
}

# THE WHOLE-DIRECTORY SWEEP. Discovery for the wiring, a hand-written total for the
# deletion, and the two halves fail apart: a fragment on disk that nothing sources
# moves `miss`, a fragment that left the disk entirely moves `total`. Only the second
# is new coverage, and it is the only one a deletion can reach.
#
# THE TOTAL IS CHECKED AFTER THE LOOP AND BEFORE THE ALL-CLEAR, so a run short by one
# fragment still reports whatever wiring it did find and then reds on the count rather
# than printing a tidy green over a smaller set.
tb_check_fragment_set() {
  local names src_hay row_hay base why total=0 miss=0
  if ! names=$(tb_fragment_names "$TB_FRAGMENT_DIR"); then
    tb_bad "fragment sweep: nothing matched $TB_FRAGMENT_DIR/*.sh, so a per-fragment loop over it would pass over nothing"
    return
  fi
  src_hay=$'\n'$(tb_sourced_names "$TB_VALIDATOR")$'\n'
  # BOTH HAYSTACKS ARE FENCED ON BOTH ENDS BY HAND, and the trailing one is not
  # decoration: `$( )` strips every trailing newline off what it captures, so a
  # reader that ends its own output with one still arrives here without it and the
  # LAST name in the file matches nothing. Measured, as a false red on
  # 99-work-doc-status-claims.sh, whose row is the last in the manifest.
  row_hay=$'\n'$(tb_manifest_names "$TB_VALIDATOR")$'\n'
  while IFS= read -r base; do
    [ -n "$base" ] || continue
    total=$((total + 1))
    why=$(tb_fragment_swept "$base" "$src_hay" "$row_hay") && continue
    tb_bad "fragment sweep: $base ships in $TB_FRAGMENT_DIR but $why"
    miss=$((miss + 1))
  done <<<"$names"
  if [ "$total" -ne "$TB_EXPECT_FRAGMENT_TOTAL" ]; then
    tb_bad "fragment sweep: $total fragment(s) ship in $TB_FRAGMENT_DIR, expected exactly $TB_EXPECT_FRAGMENT_TOTAL; a fragment deleted together with its source line and its manifest row moves no other number in this repo, so open the fragment that left before bumping TB_EXPECT_FRAGMENT_TOTAL"
    return
  fi
  tb_ok "fragment sweep: $total fragments ship in $TB_FRAGMENT_DIR, matching the expected $TB_EXPECT_FRAGMENT_TOTAL"
  [ "$miss" -eq 0 ] || return
  tb_ok "fragment sweep: all $total are sourced by $TB_VALIDATOR and open a header-manifest row"
}

tb_check_fragment_coverage() {
  local row base id why
  local -a f
  # FIRST, not last: the named-row half below returns early on its own bound, and a
  # sweep placed after it would leave the run on an unrelated failure.
  tb_check_fragment_set
  if [ "${#TB_COVERED_FRAGMENTS[@]}" -ne "$TB_EXPECT_COVERED" ]; then
    tb_bad "fragment coverage: ${#TB_COVERED_FRAGMENTS[@]} fragment(s) listed, expected $TB_EXPECT_COVERED (a row was dropped, which is the silent deletion this whole file is about)"
    return
  fi
  tb_ok "fragment coverage: $TB_EXPECT_COVERED fragments are listed for external coverage"
  # read -ra rather than unquoted word splitting, for the same bash 3.2 reason the
  # wiring gate in the driver gives.
  for row in "${TB_COVERED_FRAGMENTS[@]}"; do
    read -ra f <<<"$row"
    base="${f[0]}"
    id="${f[1]}"
    if why=$(tb_fragment_wired "$base" "$id" "$TB_VALIDATOR"); then
      tb_ok "fragment coverage: $base ships, $TB_VALIDATOR sources it, and its header manifest names check $id"
    else
      tb_bad "fragment coverage: check $id is no longer reachable, $why (a fragment deleted with its source line and its manifest row leaves [0]'s at-least-15 floor green on both sides, which is why these three are named from outside the validator)"
    fi
  done
}

# The control, and it is the same shape as the presence-pin one: strip the thing
# under test out of a COPY and require the check to redden. Without it this is a
# check over three files that are all present, which cannot fail and therefore
# proves nothing about the day one of them is not.
# THE SWEEP'S OWN CONTROL, and it is the count half that needs one. A discovered set
# that is complete today produces a loop over a complete set, which is the shape that
# proves nothing about the day one member is gone. So a copy of the NAME set, short by
# exactly one, is built in the temp tree and counted through the same reader, and the
# case refuses unless the total moved by one. Empty files: the reader asks whether a
# path is a regular .sh file and never what is in it, so nothing here needs contents,
# and nothing is copied out of the repository.
tb_case_fragment_set_control() {
  local dir="$TB_TMP/fragset" names base dropped='' n=0 m=0
  if ! names=$(tb_fragment_names "$TB_FRAGMENT_DIR"); then
    tb_bad "fragment-set control: the real fragment directory read back empty, so the control has nothing to shorten"
    return
  fi
  rm -rf "$dir"
  mkdir -p "$dir" || { tb_bad "fragment-set control: could not create $dir"; return; }
  while IFS= read -r base; do
    [ -n "$base" ] || continue
    n=$((n + 1))
    if [ -z "$dropped" ]; then dropped="$base"; continue; fi
    : > "$dir/$base"
  done <<<"$names"
  while IFS= read -r base; do
    [ -n "$base" ] || continue
    m=$((m + 1))
  done <<<"$(tb_fragment_names "$dir")"
  if [ "$m" -ne "$((n - 1))" ]; then
    tb_bad "fragment-set control: the shortened copy of the name set counts $m against the $((n - 1)) it was built to hold, so the reader the sweep counts with did not see the deletion"
    return
  fi
  tb_ok "fragment-set control: dropping $dropped takes the discovered total from $n to $m, so the sweep's equality against TB_EXPECT_FRAGMENT_TOTAL can fail"
}

tb_case_fragment_coverage_control() {
  local copy="$TB_TMP/validate-dod-unwired.sh"
  local base="83-testing-stage-shape.sh"
  local why
  tb_case_fragment_set_control
  /usr/bin/grep -vF -- "$base" "$TB_VALIDATOR" > "$copy"
  if why=$(tb_fragment_wired "$base" "[83]" "$copy"); then
    tb_bad "fragment-coverage control: a copy of $TB_VALIDATOR with every line naming $base removed still reported the fragment wired, so tb_check_fragment_coverage cannot fail"
    return
  fi
  tb_ok "fragment-coverage control: stripping $base out of a copy of $TB_VALIDATOR reddens ($why)"
  # The same copy through the sweep's own reader, which asks a looser question than
  # tb_fragment_wired does (a row opening with the name, no check id), so a sweep that
  # had quietly stopped reading either source of truth says so here.
  if why=$(tb_fragment_swept "$base" $'\n'"$(tb_sourced_names "$copy")"$'\n' $'\n'"$(tb_manifest_names "$copy")"$'\n'); then
    tb_bad "fragment-coverage control: the sweep's reader still reported $base wired in the stripped copy, so tb_check_fragment_set cannot fail on an unwired fragment"
    return
  fi
  tb_ok "fragment-coverage control: the sweep's reader reddens on the same stripped copy ($why)"
}
