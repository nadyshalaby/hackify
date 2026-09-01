# shellcheck shell=bash

# THE SUITE'S PINS ON ITS OWN INVENTORY. Every case in the sibling fragments is
# only worth what it was pointed at, so these three answer the prior question:
# how many batched ban calls actually ship, how many tokens each list really
# parsed, and how many plants the run really made. A suite that measures nothing
# passes exactly like one that measures everything, which is the whole reason
# this file exists separately from the cases it audits.
# Split out of test_ban_tokens.sh when that file reached the 500-LOC hard cap.

# Count the batched ban calls that actually SHIP, so a new one cannot appear in a new
# fragment while CHANGELOG.md still states an older count and nothing reddens.
#
# BOTH BATCHED MATCHERS, COUNTED APART AND THEN SUMMED. check_no_tokens_in gained a
# wrap-aware twin, check_no_flowed_tokens_in, and six of the seven shipped calls moved
# to it. Counting only the original name would have watched that number fall from 7 to
# 1 and read a CONVERSION as a DELETION, so the pin would have to be bumped downward
# on a change that removed no coverage at all, and the coverage bound below it would
# start comparing one matcher's call count against every parsed list. The sum is what
# the CHANGELOG sentence is about; the split is pinned separately because it is the
# half that says which matcher each shipped list is actually screened by.
#
# CALL SITES, NOT OCCURRENCES. Each name also appears in its own DEFINITION, in prose
# comments and inside one red-message string, and counting those would inflate the number
# until the pin guarded nothing. So every line has its quoted spans blanked (deleting the red
# message outright) and its comment tail cut, and then EVERY occurrence followed by whitespace
# is counted: neither definition ever qualifies, because `check_no_tokens_in() {` has none. Per
# occurrence rather than per line, because a second call fits on one line. And PROVED every
# run: 00-helpers.sh holds both definitions AND the comments AND the strings, so its count is 0.
# The two names cannot cross-count either: `check_no_flowed_tokens_in` does not contain
# `check_no_tokens_in` as a substring, so `\b` keeps each regex to its own name.
#
# EVERY TREE THAT COULD HOLD A CALL SITE, not the validator's fragment directory
# alone. hooks/ ships executable shell into a user's repository and can source
# 00-helpers.sh exactly the way a fragment does, so a batched ban added there
# would run, screen a real list, and be pinned by nothing. It carries zero such
# calls today, which is what makes this cheap to close and is also what makes it
# dangerous to close carelessly: the total does not move, so nothing on a clean
# run distinguishes a scan that reached hooks/ and found nothing from one that
# never reached it at all. THE PER-DIRECTORY EMPTINESS GUARD IS WHAT TELLS THEM
# APART, and it is why the counter exits rather than returning a number when a
# named directory globs to nothing: a renamed or moved tree stops being scanned
# loudly instead of subtracting silently. It needs no pinned file count to do it,
# so adding a fragment does not drag a constant along behind it.
#
# scripts/ ITSELF IS DELIBERATELY NOT HERE. test_ban_tokens.sh and its fragments
# call both matchers directly, dozens of times, as the cases under test. Counting
# those would swamp the shipped total with calls that ban nothing in the
# validator, which is the opposite of what this pin is for.
TB_CALL_SITE_DIRS=(scripts/validate-dod.d hooks)

tb_count_call_sites() {
  python3 - "$@" <<'CALLS'
import glob, io, os, re, sys
QUOTED = re.compile(r'"(?:\\.|[^"\\])*"|\'[^\']*\'')
LINE = re.compile(r'\bcheck_no_tokens_in\s')
FLOWED = re.compile(r'\bcheck_no_flowed_tokens_in\s')
def sites(path, rx):
    return sum(len(rx.findall(re.sub(r'(?:^|\s)#.*$', '', QUOTED.sub('""', line))))
               for line in io.open(path, encoding="utf-8"))
files = []
for d in sys.argv[1:]:
    found = sorted(glob.glob(os.path.join(d, "*.sh")))
    if not found:
        sys.exit("no .sh file under %s, so that tree was never scanned" % d)
    files += found
helpers = [f for f in files if os.path.basename(f) == "00-helpers.sh"]
print("%d %d %d" % (sum(sites(f, LINE) for f in files),
                    sum(sites(f, FLOWED) for f in files),
                    sum(sites(h, LINE) + sites(h, FLOWED) for h in helpers)))
CALLS
}

# Pinned BOTH ways: against the hand-written TB_EXPECT_CALLS, which defends the CHANGELOG.md
# sentence, and against the count of lists PARSED (planting is pinned separately, by
# tb_check_plant_total). The second half is the COVERAGE bound and it is the one that bites:
# a ban list can ship, run inside the validator and stop banning anything tomorrow without a
# single assertion here noticing, unless this suite parsed and planted it. So the answer to a
# red on that third assertion is a new list in tb_extract_lists and a new tb_plant_every_token
# sweep, never a bumped constant.
tb_check_call_sites() {
  local out rc line_n flowed_n helpers total lists
  local parsed=("$TB_TMP"/tokens*.txt)
  # 2>&1 so the counter's own refusal reaches the verdict line. It exits on a
  # directory that globs to no .sh file, and that message IS the finding.
  out=$(tb_count_call_sites "${TB_CALL_SITE_DIRS[@]}" 2>&1)
  rc=$?
  read -r line_n flowed_n helpers <<<"$out"
  lists=${#parsed[@]}
  [ -f "${parsed[0]}" ] || lists=0
  if [ "$rc" -ne 0 ]; then
    tb_bad "call-site pin: the counter refused to run over ${TB_CALL_SITE_DIRS[*]}: $out"
    return
  fi
  tb_ok "call-site pin: every one of ${#TB_CALL_SITE_DIRS[@]} scanned tree(s) (${TB_CALL_SITE_DIRS[*]}) held at least one .sh file to scan"
  if [ -z "$out" ] || [ "$helpers" != "0" ]; then
    tb_bad "call-site pin: 00-helpers.sh reported ${helpers:-no} call sites across the two batched matchers, expected 0, so the counter is being fooled by a definition, a comment or a red-message string"
    return
  fi
  tb_ok "call-site pin: both definitions, their comment mentions and their red-message strings in 00-helpers.sh count as 0 call sites"
  total=$((line_n + flowed_n))
  if [ "$total" -ne "$TB_EXPECT_CALLS" ]; then
    tb_bad "call-site pin: $total batched ban calls ship in ${TB_CALL_SITE_DIRS[*]} ($line_n line-oriented, $flowed_n flattened), expected $TB_EXPECT_CALLS (a ban list was added or removed; bump TB_EXPECT_CALLS in test_ban_tokens.sh to match, and leave old CHANGELOG entries alone)"
    return
  fi
  tb_ok "call-site pin: $total batched ban calls ship, matching the expected $TB_EXPECT_CALLS"
  if [ "$line_n" -ne "$TB_EXPECT_CALLS_LINE" ] || [ "$flowed_n" -ne "$TB_EXPECT_CALLS_FLOWED" ]; then
    tb_bad "call-site pin: the split is $line_n line-oriented and $flowed_n flattened, expected $TB_EXPECT_CALLS_LINE and $TB_EXPECT_CALLS_FLOWED (a call site changed matcher; each plant sweep in test_ban_tokens.sh names the matcher its list ships under and has to move with it, or the sweep screens that list with a matcher the validator no longer runs)"
    return
  fi
  tb_ok "call-site pin: $line_n line-oriented and $flowed_n flattened batched calls ship, matching the expected split"
  if [ "$total" -ne "$lists" ]; then
    tb_bad "call-site pin: $total calls ship but this suite parsed $lists token list(s), so a shipped ban list is never planted"
    return
  fi
  tb_ok "call-site pin: every one of the $total shipped calls has a token list this suite parses"
}

# Deliberately NOT check_list_size from 00-helpers.sh: that helper moves FAILED, which is
# the thing under test here, so borrowing it would corrupt what every assertion reads.
tb_check_list_size() {
  local listfile="$1"
  local want="$2"
  local label="$3"
  local got
  got=$(/usr/bin/grep -c '' "$listfile" 2>/dev/null) || got=0
  if [ "$got" -eq "$want" ]; then
    tb_ok "$label: $got tokens parsed, matching the expected $want"
  else
    tb_bad "$label: $got tokens parsed, expected $want (a ban group was added or dropped)"
  fi
}

# Kept alongside the per-sweep deltas, because exactly two tampers walk past them
# and this catches both. A sweep that runs TWICE passes its own delta each time,
# 23 against 23, and only the grand total moves. And an exit taken part way down
# the run order skips whole sweeps, taking their deltas out of the run with them,
# so a total firing from the EXIT trap is the last assertion still standing.
# TB_PLANTED is moved by tb_plant_case alone, so this counts what the run really
# screened rather than what the run order implies.
tb_check_plant_total() {
  local want=$((TB_EXPECT_70 + TB_EXPECT_77 + TB_EXPECT_RPT + TB_EXPECT_81))
  # Summed on a second line rather than a longer first one. The list grows every
  # time a fragment adds a ban call, and a single expression that has to be
  # rewrapped on each of those edits is a line nobody rereads before bumping it.
  want=$((want + TB_EXPECT_82 + TB_EXPECT_82C + TB_EXPECT_82G))
  # All three totals fire from this one EXIT-trap call, and they go FIRST so a
  # plant verdict returning early cannot take any of them out of the run.
  tb_check_failclosed_total
  tb_check_miscount_total
  # tb_check_wi_failclosed_total is ALSO called from tb_case_green_path in
  # 10-ban-list-cases.sh, which is the call this one exists to back up: an exit
  # taken anywhere above that line drops it out of the run and nothing reddens,
  # exactly the hole tb_check_miscount_total does not have. The in-line call is
  # left standing rather than moved, because it lives in a fragment this change
  # does not own. The cost is one duplicated verdict line on a clean run, which
  # is affordable: the check reads a counter and asserts, so a second call
  # cannot change what the first one decided.
  tb_check_wi_failclosed_total
  if [ "$TB_PLANTED" -eq "$want" ]; then
    tb_ok "plant total: $TB_PLANTED tokens actually planted, one per token in every parsed list"
    return
  fi
  tb_bad "plant total: $TB_PLANTED tokens actually planted, expected $want (a plant section is pointed at the wrong list, planted twice, or not running at all)"
}

# The fail-closed cases, counted the way the plants are, and for a sharper reason.
# They hang off tb_case_green_path rather than off their own line in the run
# order, so the run order cannot show they happened; the wiring gate cannot see
# them either, because not one of the four names it lists for
# 10-ban-list-cases.sh is one of these three, and all four survive deleting
# them. Delete the call and every remaining assertion still passes over a suite
# that stopped testing the one branch it was written for. A total read from the
# EXIT trap is what is left, and it fires whether the run finished or died half
# way down.
#
# Written by hand rather than derived, the same trade TB_EXPECT_70 makes: three is
# one case per fail-closed branch (check_no_token's and check_no_tokens_in's) plus
# the missing-path route into the first. A bound counting the functions that exist
# would drop with them and stay green.
TB_EXPECT_FAILCLOSED=3

tb_check_failclosed_total() {
  if [ "$TB_FAILCLOSED" -eq "$TB_EXPECT_FAILCLOSED" ]; then
    tb_ok "fail-closed total: $TB_FAILCLOSED cases actually ran, matching the expected $TB_EXPECT_FAILCLOSED"
    return
  fi
  tb_bad "fail-closed total: $TB_FAILCLOSED cases actually ran, expected $TB_EXPECT_FAILCLOSED (a fail-closed case is no longer being called, or is being called twice)"
}

# Counted apart from the fail-closed cases for the same reason it is written as a
# separate case: a count never taken and a count read wrong are two defects, and a
# pin that merged them would go green with either one of its cases missing. Two
# cases today, the colon filename and two hits on one line, and the pin is what
# makes a third one impossible to add silently.
TB_EXPECT_MISCOUNT=2

tb_check_miscount_total() {
  if [ "$TB_MISCOUNT" -eq "$TB_EXPECT_MISCOUNT" ]; then
    tb_ok "miscount total: $TB_MISCOUNT cases actually ran, matching the expected $TB_EXPECT_MISCOUNT"
    return
  fi
  tb_bad "miscount total: $TB_MISCOUNT case(s) actually ran, expected $TB_EXPECT_MISCOUNT (the colon-filename case or the two-hits-on-one-line case is no longer being called, or one is being called twice)"
}
