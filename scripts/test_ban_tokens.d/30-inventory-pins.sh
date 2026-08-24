# shellcheck shell=bash

# THE SUITE'S PINS ON ITS OWN INVENTORY. Every case in the sibling fragments is
# only worth what it was pointed at, so these three answer the prior question:
# how many batched ban calls actually ship, how many tokens each list really
# parsed, and how many plants the run really made. A suite that measures nothing
# passes exactly like one that measures everything, which is the whole reason
# this file exists separately from the cases it audits.
# Split out of test_ban_tokens.sh when that file reached the 500-LOC hard cap.

# Count the batched ban calls that actually SHIP, so a fourth one cannot appear in a new
# fragment while CHANGELOG.md still says three and nothing reddens.
#
# CALL SITES, NOT OCCURRENCES. The name also appears in the DEFINITION, in prose comments
# and inside one red-message string, and counting those would inflate the number until the
# pin guarded nothing. So every line has its quoted spans blanked (deleting the red message
# outright) and its comment tail cut, and then EVERY occurrence followed by whitespace is
# counted: the definition never qualifies, because `check_no_tokens_in() {` has none. Per
# occurrence rather than per line, because a second call fits on one line. And PROVED every
# run: 00-helpers.sh holds the definition AND the comments AND the string, so its count is 0.
tb_count_call_sites() {
  python3 - "$1" <<'CALLS'
import glob, io, os, re, sys
QUOTED = re.compile(r'"(?:\\.|[^"\\])*"|\'[^\']*\'')
CALL = re.compile(r'\bcheck_no_tokens_in\s')
def sites(path):
    return sum(len(CALL.findall(re.sub(r'(?:^|\s)#.*$', '', QUOTED.sub('""', line))))
               for line in io.open(path, encoding="utf-8"))
d = sys.argv[1]
print("%d %d" % (sum(sites(f) for f in sorted(glob.glob(os.path.join(d, "*.sh")))),
                 sites(os.path.join(d, "00-helpers.sh"))))
CALLS
}

# Pinned BOTH ways: against the hand-written three, which defends the CHANGELOG.md sentence,
# and against the count of lists PARSED (planting is pinned separately, by tb_check_plant_total).
tb_check_call_sites() {
  local out total helpers lists
  local parsed=("$TB_TMP"/tokens*.txt)
  out=$(tb_count_call_sites "scripts/validate-dod.d")
  total=${out%% *}
  helpers=${out##* }
  lists=${#parsed[@]}
  [ -f "${parsed[0]}" ] || lists=0
  if [ -z "$out" ] || [ "$helpers" != "0" ]; then
    tb_bad "call-site pin: 00-helpers.sh reported ${helpers:-no} call sites, expected 0, so the counter is being fooled by the definition, a comment or the red-message string"
    return
  fi
  tb_ok "call-site pin: the definition, its comment mentions and its red-message string in 00-helpers.sh count as 0 call sites"
  if [ "$total" -ne "$TB_EXPECT_CALLS" ]; then
    tb_bad "call-site pin: $total batched ban calls ship in scripts/validate-dod.d/, expected $TB_EXPECT_CALLS (one was added or removed and CHANGELOG.md still claims three)"
    return
  fi
  tb_ok "call-site pin: $total batched ban calls ship, matching the expected $TB_EXPECT_CALLS"
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
  local want=$((TB_EXPECT_70 + TB_EXPECT_77 + TB_EXPECT_RPT))
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
    tb_ok "plant total: $TB_PLANTED tokens actually planted, one per token in all three lists"
    return
  fi
  tb_bad "plant total: $TB_PLANTED tokens actually planted, expected $want (a plant section is pointed at the wrong list, planted twice, or not running at all)"
}

# The fail-closed cases, counted the way the plants are, and for a sharper reason.
# They hang off tb_case_green_path rather than off their own line in the run
# order, so the run order cannot show they happened; the wiring gate cannot see
# them either, because not one of the eleven names it lists for
# 10-ban-list-cases.sh is one of these three, and all eleven survive deleting
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
# pin that merged them would go green with either one of its cases missing. One
# case today, and the pin is what makes a second one impossible to add silently.
TB_EXPECT_MISCOUNT=1

tb_check_miscount_total() {
  if [ "$TB_MISCOUNT" -eq "$TB_EXPECT_MISCOUNT" ]; then
    tb_ok "miscount total: $TB_MISCOUNT case actually ran, matching the expected $TB_EXPECT_MISCOUNT"
    return
  fi
  tb_bad "miscount total: $TB_MISCOUNT case(s) actually ran, expected $TB_EXPECT_MISCOUNT (the colon-filename case is no longer being called, or is being called twice)"
}
