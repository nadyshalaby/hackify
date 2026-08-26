#!/usr/bin/env bash
# Tamper test for the batched token ban (check_no_tokens_in / ban_tokens_ok
# in scripts/validate-dod.d/00-helpers.sh).
#
# WHY THIS FILE EXISTS. [70] and [77] used to re-read every covered file once per
# banned token. Batching that into one grep per file is a rewrite of the matching
# engine those two checks are built on, and the proofs for the checks around it
# are prose records of manual runs. A prose proof cannot be re-run after the next
# edit, so the rewrite ships with an executable one instead.
#
# WHAT IT REFUSES TO LET THROUGH. Every failure mode below is one this repo has
# already shipped at least once:
#   1. a banned token that stops being banned, checked one token at a time over
#      the REAL lists parsed out of the two fragments, not a sample
#   2. a token that silently changes what grep matches (blank, whitespace-only,
#      newline-carrying, or no tokens at all), the vacuous-pass surface batching
#      adds, because grep -f reads one pattern per LINE
#   3. a check that prints red and exits 0, verified as a real process exit
#      status in BOTH directions, not as printed output
#   4. a green path that is green because it measured nothing
#
# HOW IT IS LAID OUT. This file is the driver: the counts written a second time,
# the two fragments whose ban lists it re-reads, the run order, and the verdict.
# The harness and the cases live in scripts/test_ban_tokens.d/ and are sourced in
# order, the same shape scripts/validate-dod.sh uses. The suite was split there
# when it reached the 500-LOC hard cap. Sourcing is bash's only import, so a
# driver plus fragments is the one split that changes nothing about what runs.
#
# Standalone: bash scripts/test_ban_tokens.sh, exits non-zero on any failure.
# Reads the repo, writes only under its own temp directory, mutates nothing.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

FAILED=0
source "scripts/validate-dod.d/00-helpers.sh"

TB_TMP=$(mktemp -d "${TMPDIR:-/tmp}/hackify-bantest.XXXXXX") || exit 1
trap 'rm -rf "$TB_TMP"' EXIT
TB_OUT="$TB_TMP/out.txt"
TB_PASS=0
TB_BAD=0
TB_LIST=()
# Moved by tb_plant_case and by nothing else, so it counts plants that actually
# happened rather than plants the run order implies. Read twice: tb_plant_every_token
# takes a delta across its own loop, tb_check_plant_total takes the grand total.
TB_PLANTED=0

# Counts written a SECOND time, on purpose, the same way [77] writes RR_EXPECTED
# next to its file list. A bound derived from the list cannot police the list: if
# a ban group is deleted the parsed count drops with it and a `wc`-style bound
# stays green while coverage quietly shrinks.
TB_EXPECT_70=21
TB_EXPECT_77=60
# A THIRD list, and the one this suite used to miss entirely. [77] enforces it
# against one named file instead of the six-file sweep, so it is counted apart
# from the 60 above and pinned apart from them too.
TB_EXPECT_RPT=6
# The number CHANGELOG.md stakes a claim on, "all 89 tokens in the validator's three
# batched ban lists". THREE was prose with nothing behind it, so it is written here.
# FOUR since 0.16.1, when [81] added the attribution ban. The changelog sentence that
# said three is a historical entry describing the tree at ITS release and is left
# alone; a record does not go wrong because the tree later grew.
TB_EXPECT_CALLS=4
TB_EXPECT_81=4

# The two files whose ban lists this test re-reads on every run, so it always
# tests what ships rather than a copy that can drift away from it. The names
# say [70] and [77] because they name the CHECK families, which is what the
# lists belong to; [38g]'s P5_BANS moved to 71-release-mechanism-pins.sh when
# 70 was split at the 500-LOC cap, and the check ID went with it.
TB_SRC_70="scripts/validate-dod.d/71-release-mechanism-pins.sh"
TB_SRC_77="scripts/validate-dod.d/77-reviewer-roster.sh"
TB_SRC_81="scripts/validate-dod.d/81-no-claude-attribution.sh"
# The harness and the cases, sourced in order. Definitions only: every one of
# them reads TB_TMP, TB_LIST and the counters above at CALL time, so the run
# order at the foot of this file is still the only thing that decides what runs.
TB_MODULES_DIR="$REPO_ROOT/scripts/test_ban_tokens.d"
source "$TB_MODULES_DIR/00-harness.sh"
source "$TB_MODULES_DIR/10-ban-list-cases.sh"
source "$TB_MODULES_DIR/15-wi-absent-cases.sh"
source "$TB_MODULES_DIR/20-corruption-and-wiring-cases.sh"
source "$TB_MODULES_DIR/30-inventory-pins.sh"

# WIRING GATE, and the reason this file has one at all. This driver became four
# sourced fragments when the single file hit the 500-LOC cap, and five when
# 10-ban-list-cases.sh hit the same cap in its turn. The split bought a failure
# mode the single file could not have had: delete a source line above and its
# whole section of the suite leaves with it, while the run order below simply
# calls fewer functions and the verdict still reads green. That was measured,
# not feared. Dropping 20-corruption-and-wiring-cases.sh ran 102 assertions
# instead of 112 and dropping 30-inventory-pins.sh ran 105, and BOTH printed ALL
# BAN-TOKEN TAMPER TESTS PASSED and exited 0.
#
# MEASURED AGAIN WHEN THE FIFTH FRAGMENT ARRIVED, and re-measured when the two
# union cases landed in it, because the reading has to carry its own baseline:
# against a total of 153, dropping 15-wi-absent-cases.sh ran 139 and still printed
# ALL BAN-TOKEN TAMPER TESTS PASSED and exited 0. Its three rows below had to come
# out along with the source line to get a count at all, and that is the gate
# working rather than a flaw in the reading: the two older numbers were taken
# before this gate existed and cannot be reproduced today, because a missing
# fragment now exits instead of counting. A suite whose coverage can shrink
# silently is the measures-nothing shape every case below exists to refuse, so
# the split pays for itself here rather than leaving the hole open.
#
# THE NAMES ARE WRITTEN OUT, never grepped from the fragments. A list derived
# from the files it polices goes empty at exactly the moment they go missing and
# then passes over nothing, which is the same defect wearing the guard's badge.
# The cost is real: add a case function that the run order calls and this list
# needs the name. That is the maintenance a bound has to carry to be worth
# anything, the same trade TB_EXPECT_70 and TB_EXPECT_77 already make.
#
# IT EXITS INSTEAD OF COUNTING. A truncated run reporting "105 passed" is worse
# than no run, because it looks like the real thing. So this fires before
# tb_finish is armed and leaves through the plain cleanup trap, which means no
# partial verdict is ever printed.
TB_WIRING=(
  "00-harness.sh tb_ok tb_bad tb_extract_lists tb_load_list tb_expect_red tb_expect_green"
  # Four names against a fragment that defines nine functions. The five left out
  # all hang off tb_case_green_path rather than off the run order, and the cases
  # among them are counted rather than named, by TB_FAILCLOSED and TB_MISCOUNT,
  # which is the trade 30-inventory-pins.sh writes out beside both totals. The
  # count matters outside this file too: that same fragment reads THIS row's
  # length into the reason it gives for counting the fail-closed cases by hand.
  # Add a name here and that comment goes stale, and no check can see it happen.
  "10-ban-list-cases.sh tb_plant_case tb_plant_every_token tb_case_green_path tb_case_real_file_plant"
  # 15-wi-absent-cases.sh owns THREE rows, not one. Field 0 is the fragment and
  # nothing here requires it to be unique, so that fragment's ten functions are
  # listed on three rows of readable width rather than run off the end of one.
  # ALL TEN are named, which is the whole point: nothing inside the fragment can
  # stop existing without this gate saying so, and the fragment itself now hangs
  # off a single source line above, which is exactly the shape the gate was
  # written to catch. The third row arrived with the two union cases, and adding
  # a row is the right answer rather than lengthening the other two: a row that
  # runs off the screen is a row nobody rereads.
  "15-wi-absent-cases.sh tb_load_wi_absent tb_wi_fixture_ready tb_wi_scope_ready tb_run_wi_absent_cases"
  "15-wi-absent-cases.sh tb_case_wi_scan_failed tb_case_wi_mktemp_failed tb_case_wi_unreadable_file"
  "15-wi-absent-cases.sh tb_case_wi_deleted_unstaged tb_case_wi_unmerged_index tb_check_wi_failclosed_total"
  "20-corruption-and-wiring-cases.sh tb_case_token_guard tb_run_token_guards tb_case_blank_token_end_to_end tb_case_zero_tokens tb_write_wiring_fragment tb_case_exit_wiring"
  "30-inventory-pins.sh tb_count_call_sites tb_check_call_sites tb_check_list_size tb_check_plant_total"
)

# Field 0 of every row is the fragment, the rest are the functions it owes.
# read -ra rather than unquoted word splitting, for the same bash 3.2 reason
# [37] gives in 70-invariants-and-new.sh.
tb_check_wiring() {
  local row missing=0 i
  local -a fns
  for row in "${TB_WIRING[@]}"; do
    read -ra fns <<<"$row"
    for ((i = 1; i < ${#fns[@]}; i++)); do
      declare -F "${fns[$i]}" > /dev/null 2>&1 && continue
      red "  FAIL ${fns[$i]} is not defined, so scripts/test_ban_tokens.d/${fns[0]} is not being sourced and its cases cannot run"
      missing=$((missing + 1))
    done
  done
  [ "$missing" -eq 0 ] && return 0
  red "[test_ban_tokens] $missing wiring function(s) missing, refusing to run a truncated suite"
  exit 1
}

tb_check_wiring

# ---------------------------------------------------------------------------
# Run order: list integrity first, because every section after it is only
# meaningful if the lists it parsed are the lists that ship.
# ---------------------------------------------------------------------------
# The verdict runs from the EXIT trap, not from the foot of the script, so no
# exit path reaches the shell without it. An early exit is exactly what would
# skip the pin above, and a suite that leaves without printing a verdict is
# itself the silent pass. $? is read first, on one line, because `local` on its
# own line would overwrite it: a completed run arrives here as 0 and anything
# else means the suite died on the way.
tb_finish() {
  local rc=$?
  tb_check_plant_total
  printf '\n[test_ban_tokens] %s passed, %s failed\n' "$TB_PASS" "$TB_BAD"
  rm -rf "$TB_TMP"
  if [ "$TB_BAD" -eq 0 ] && [ "$TB_PASS" -gt 0 ] && [ "$rc" -eq 0 ]; then
    green "ALL BAN-TOKEN TAMPER TESTS PASSED"
    exit 0
  fi
  red "$TB_BAD BAN-TOKEN TAMPER TEST(S) FAILED"
  exit 1
}

# Armed here rather than beside mktemp because every function it calls has to
# exist by the time it fires. Above this line the plain cleanup trap still runs.
trap tb_finish EXIT

printf '[test_ban_tokens] batched token ban, tamper tests\n'

tb_extract_lists
tb_check_call_sites
tb_check_list_size "$TB_TMP/tokens70.txt" "$TB_EXPECT_70" "[70] ban list"
tb_check_list_size "$TB_TMP/tokens77.txt" "$TB_EXPECT_77" "[77] ban list"
tb_check_list_size "$TB_TMP/tokens77rpt.txt" "$TB_EXPECT_RPT" "[77] report-input ban list"
tb_check_list_size "$TB_TMP/tokens81.txt" "$TB_EXPECT_81" "[81] attribution ban list"

tb_load_list "$TB_TMP/tokens70.txt"
tb_case_green_path

# review-and-verify.md is covered by [77], so it is planted with a [77] token,
# and 'panel is five' is the exact wording of the review-scope defect this
# sprint fixed. Scanning it with the [70] list would prove nothing.
tb_load_list "$TB_TMP/tokens77.txt"
tb_case_real_file_plant 'panel is five'

tb_run_token_guards
tb_case_blank_token_end_to_end
tb_case_zero_tokens
tb_case_exit_wiring

tb_plant_every_token "$TB_TMP/tokens70.txt" "$TB_EXPECT_70" "[70] ban list"
tb_plant_every_token "$TB_TMP/tokens77.txt" "$TB_EXPECT_77" "[77] ban list"

# The report-input bans, screened the way [77] screens them: check_no_tokens_in
# takes one path and the whole array at both call sites, so the only thing that
# differs between this section and the one above it is which array screens the
# plant. Planting these with the RR_BANS array would prove nothing about them.
tb_plant_every_token "$TB_TMP/tokens77rpt.txt" "$TB_EXPECT_RPT" "[77] report-input ban list"

# [81]'s list, planted the same way. Its tokens are trailer-shaped rather than
# bare names on purpose (the fragment says why), so planting one writes a string
# only a real trailer carries, and a green here means the net catches the real
# thing rather than a mention of it.
tb_plant_every_token "$TB_TMP/tokens81.txt" "$TB_EXPECT_81" "[81] attribution ban list"

# Ran to completion. tb_finish reads this status, so a finished run is
# distinguishable from an exit taken anywhere above rather than being whatever
# the last plant call happened to return.
exit 0
