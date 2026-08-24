# shellcheck shell=bash

# THE [40] ABSENCE SCAN'S FAIL-CLOSED BRANCHES, and nothing else. Split out of
# 10-ban-list-cases.sh when THAT file reached the 500-LOC hard cap, the same
# remedy test_ban_tokens.sh itself took when it hit the cap first and became a
# driver plus fragments. The section below was carried over whole, prose and
# all, because the prose is the part worth protecting in a move like this.
#
# THE NUMBER 15 puts it between 10 and 20, so the driver's source order still
# follows the names on disk, and the section below keeps the 3 it carried
# before the move. Section numbers belong to the suite rather than to whichever
# file they land in, which is why 20-corruption-and-wiring-cases.sh opens at a 3
# of its own, and why scripts/validate-dod.d/70-invariants-and-new.sh can cite
# this block by number as long as it names the file alongside it.
#
# DEFINITIONS ONLY, the same contract every sibling fragment keeps: nothing here
# runs at source time. tb_run_wi_absent_cases hangs off tb_run_fail_closed_cases
# in 10-ban-list-cases.sh, and tb_check_wi_failclosed_total off
# tb_case_green_path there and off the EXIT trap in 30-inventory-pins.sh, so the
# run order in scripts/test_ban_tokens.sh is still the only thing that decides
# what runs.

# ---------------------------------------------------------------------------
# 3. THE [40] ABSENCE SCAN'S FAIL-CLOSED BRANCHES, and why they live in this
# suite rather than beside the check they cover.
#
# wi_absent() in scripts/validate-dod.d/70-invariants-and-new.sh asks the same
# question section 2b of 10-ban-list-cases.sh asks of the batched ban: did the
# scan actually run. It is the harsher shape of it. An absence check has no hit
# to print when it fails open, so a scan that never ran and a tree that is
# genuinely clean come out of it as the identical green line, and there is
# nothing in the output to tell them apart. This suite is the only executable
# harness in the repo for a validator internal, so the cases go here rather
# than growing a second one.
#
# THE FUNCTION IS PARSED OUT OF THE SHIPPED FRAGMENT, never copied, the same
# bargain tb_extract_lists makes with the ban lists: a copy kept here would go
# on passing long after the real one regressed. Sourcing the whole fragment is
# not an option, it runs its forty top-level checks and moves FAILED on its own,
# which is the counter every assertion in this suite reads.
#
# THREE CASES, NOT ONE, and the split is structural rather than tidy.
#   (a) git grep itself exits above 1. That branch already worked before this
#       case existed, so it would never have caught the mktemp defect. It is a
#       regression pin on the branch the mktemp fix restructures around it.
#   (b) mktemp fails, so 2>"$err" dies in the shell before git ever runs and
#       bash hands back 1. With no capture file there is no stderr either, so
#       the failure wears a clean tree's exact face. All four calls then fail
#       open together and [40] cannot fail at all. This is the case that reds
#       before the mktemp fix and greens after it, and the reason the whole
#       section was written.
#   (c) git opens the repository, reaches a tracked file and cannot stat it.
#       This is the ONLY one of the three that lets git open a file at all, and
#       that is precisely what (a) and (b) cannot reach: git returns 1 after a
#       scan it could not finish, the SAME status a genuinely clean tree
#       returns, so the check printed green over a file nothing had read.
#       Stderr is the only thing that tells the two apart. Measured on git
#       2.50.1: sealed file, rc 1, empty stdout, stat error on stderr; the same
#       file readable, rc 1 and stderr empty.
# ---------------------------------------------------------------------------

# Counted the way the fail-closed cases are counted, and counted APART from them.
# TB_FAILCLOSED is scoped to the batched ban screen, and 30-inventory-pins.sh
# writes that scope into TB_EXPECT_FAILCLOSED's own comment, one case per
# check_no_token / check_no_tokens_in branch plus the missing-path route into the
# first. Folding another function's branches into that total would leave the
# constant's stated reason false while the number still added up, which is the
# stale-rationale defect this repo keeps finding and no check can see.
#
# THE PIN FIRES TWICE NOW, in-line from tb_case_green_path and again from the
# EXIT trap, where tb_check_plant_total in 30-inventory-pins.sh calls it beside
# the other two totals. The in-line call was left standing rather than moved, so
# a clean run prints this verdict twice, which costs nothing: the check reads a
# counter and asserts, so a second call cannot change what the first decided.
# What the trap side buys is the shape the in-line call alone could not catch:
# an exit taken above that line WOULD have dropped the only call out of the run,
# and nothing would have reddened. A case that stopped being called, a case
# called twice, and a run that died half way down are covered between them.
#
# The count still earns its place beside the wiring gate. tb_case_green_path is
# itself a line in the driver's run order, so its absence is visible where these
# two cases' absence is not, and the gate now names tb_case_wi_scan_failed,
# tb_case_wi_mktemp_failed and this function on a row of their own, so deleting
# one makes the suite refuse to run truncated. But the gate asks declare -F. It
# sees a function that stopped EXISTING, never one left defined and no longer
# called, and that second shape is the whole reason to count.
#
# Both claims this paragraph used to make were true when written and were
# falsified by fixes in files this fragment does not own. Stale rationale of
# exactly the kind the paragraph above names, found by a sweep and not by any
# check.
TB_WI_FAILCLOSED=0
TB_EXPECT_WI_FAILCLOSED=3

# The shipped source, read fresh on every run.
TB_WI_SRC="scripts/validate-dod.d/70-invariants-and-new.sh"

# The literal every case below scans for REALLY occurs in a tracked file that no
# WI_LIVE_PATHS exclusion covers: it is the live implementer type [40] pins as
# present. A literal that was genuinely absent would make the pre-fix green
# correct instead of fail-open, and the cases would prove nothing about the
# branch they are named for. Same reason tb_case_unreadable_single seals a file
# that carries its token instead of an empty one.
TB_WI_LIT='hackify:wave-implementer'

tb_load_wi_absent() {
  local body
  body=$(sed -n '/^wi_absent() {$/,/^}$/p' "$TB_WI_SRC")
  if [ -z "$body" ]; then
    tb_bad "wi_absent: nothing parsed out of $TB_WI_SRC, so both cases below would have measured nothing"
    return 1
  fi
  eval "$body"
  if declare -F wi_absent > /dev/null 2>&1; then
    tb_ok "wi_absent: the shipped definition parsed out of $TB_WI_SRC and is callable"
    return 0
  fi
  tb_bad "wi_absent: the parsed text left no wi_absent defined, so both cases below would have measured nothing"
  return 1
}

tb_run_wi_absent_cases() {
  tb_load_wi_absent || return
  # ABOVE the fixture guard on purpose, because that guard does not apply to this
  # case and gating it there would let a vanished literal take the Critical
  # regression pin out of the run. See the comment on tb_wi_fixture_ready.
  tb_case_wi_unreadable_file
  tb_wi_fixture_ready || return
  tb_case_wi_scan_failed
  tb_case_wi_mktemp_failed
}

# THE FIXTURE LITERAL IS PROVED PRESENT, not assumed. This guard covers cases (a)
# and (b), and neither of them can prove it for itself: (a) dies on the pathspec
# and (b) dies in the shell, so both reach their verdict without git ever opening a
# file. Let the literal fall out of the tree, which is exactly what the next rename
# does, and both go on passing over a fixture that can no longer tell a fail-open
# apart from an honestly clean tree.
# The scope checked here is ':(top)', which is the scope case (b) hands wi_absent.
# Same move tb_case_real_file_plant makes when its multibyte fixture goes plain.
#
# CASE (c) IS NOT COVERED BY THIS AND MUST NOT BE GATED ON IT. It brings its own
# fixture, a throwaway repository holding one sealed file it writes the literal
# into itself, so nothing that happens to the live tree can take that fixture away.
# It has no vanished-fixture failure mode to guard against either: measured, a scan
# scoped to one unreadable file returns rc 1 with empty stdout whether or not the
# literal is in that file, so presence is not what (c) rests on. Pointing this
# guard at (c) would mean sealing a real tracked file to satisfy it, and that would
# leave the user's own tree holding something at mode 000 after any interrupt.
tb_wi_fixture_ready() {
  # THIS FRAGMENT EXCLUDES ITSELF, for the reason WI_LIVE_PATHS excludes
  # 70-invariants-and-new.sh: the TB_WI_LIT assignment above is itself a tracked
  # occurrence, so a scan that counted it would report the literal present no
  # matter what became of the rest of the tree, and the guard could never fire.
  # MEASURED, not feared: without this exclusion, pointing TB_WI_LIT at a string
  # that exists nowhere else in the repo still passed.
  if git grep -qF -e "$TB_WI_LIT" -- ':(top)' ':(top,exclude)scripts/test_ban_tokens.d/15-wi-absent-cases.sh'; then
    tb_ok "wi_absent: the fixture literal [$TB_WI_LIT] still occurs in a live file, so a green below would be a fail-open rather than a clean tree"
    return 0
  fi
  tb_bad "wi_absent: [$TB_WI_LIT] no longer occurs in any live file, pick another fixture (both cases below would pass over one that proves nothing)"
  return 1
}

# THE SCOPE IS PROVED, NOT ASSUMED, the same discipline tb_make_unreadable applies
# to its permission bit. Each case sets WI_LIVE_PATHS because that is the global
# wi_absent reads, and an empty one would drop the pathspec entirely and scan the
# whole tree, leaving the case testing something other than what it is named for.
# This is also the read shellcheck cannot see for itself, since wi_absent arrives
# through eval rather than through a definition it can follow.
tb_wi_scope_ready() {
  [ "${#WI_LIVE_PATHS[@]}" -gt 0 ] && return 0
  tb_bad "$1: WI_LIVE_PATHS came out empty, so the call below would have scanned the whole tree instead of the fixture"
  return 1
}

# EACH CASE OWNS ITS SCOPE AND HANDS IT BACK. WI_LIVE_PATHS is the global
# wi_absent reads, and every case below used to assign it and walk away, so the
# last one to run left its pathspec sitting there for whatever came next. The
# fix is `local -a WI_LIVE_PATHS`: bash's dynamic scoping means the eval'd
# wi_absent called from inside the case still reads it, and the shell puts the
# global back on the way out, including on the early returns these cases take.
# A save-and-restore pair at the tail would miss exactly those.
tb_case_wi_scan_failed() {
  local before="$FAILED"
  local -a WI_LIVE_PATHS
  TB_WI_FAILCLOSED=$((TB_WI_FAILCLOSED + 1))
  # An unknown pathspec magic is rejected by git before it opens a single file,
  # measured at 128 here, which reaches the branch without leaning on a
  # permission bit taking effect the way the sealed-file fixtures do.
  WI_LIVE_PATHS=(':(bogusmagic)no-such-path')
  tb_wi_scope_ready "wi_absent (scan failed)" || return
  wi_absent "$TB_WI_LIT" > "$TB_OUT" 2>&1
  tb_expect_red "wi_absent (scan failed): a git grep exiting above 1 reddens instead of reporting the literal gone" "$before"
  if /usr/bin/grep -q 'finding nothing here would be finding nothing at all' "$TB_OUT"; then
    tb_ok "wi_absent (scan failed): the red says the scan never ran, not that the literal survives nowhere"
  else
    tb_bad "wi_absent (scan failed): reddened for some reason other than the scan-never-ran branch"
  fi
}

# THE SHIM IS ON A LOCAL PATH, so it cannot outlive the call whatever happens.
# The `PATH="$saved"` line below is still the narrow window, it puts the real
# mktemp back the moment wi_absent returns, but it only ever ran on the happy
# path: an early return between the two left the shim on PATH for every case
# after this one. `local PATH` is the backstop that closes that, on every exit
# from the function including the returns above it.
#
# NOT wi_absent's trap save-and-restore, and the difference is this suite's own
# shape. It prints its verdict from an EXIT trap, so a trap installed here would
# shadow tb_finish for the length of the window and a signal arriving inside it
# would cost the run its verdict entirely. The shim DIRECTORY needs no trap
# either: it is written under TB_TMP, and the driver's trap removes that tree on
# every exit path there is.
tb_case_wi_mktemp_failed() {
  local before="$FAILED"
  local shim="$TB_TMP/mktemp-shim"
  local saved="$PATH"
  local -a WI_LIVE_PATHS
  local PATH="$PATH"
  TB_WI_FAILCLOSED=$((TB_WI_FAILCLOSED + 1))
  WI_LIVE_PATHS=(':(top)')
  tb_wi_scope_ready "wi_absent (no temp file)" || return
  mkdir -p "$shim" || { tb_bad "wi_absent (no temp file): the mktemp shim could not be built, so this branch was never exercised"; return; }
  printf '#!/bin/sh\nexit 1\n' > "$shim/mktemp"
  chmod 755 "$shim/mktemp"
  # NOT a subshell. tb_expect_red reads FAILED, and 00-harness.sh spells out why
  # only a redirection on the call itself preserves it: a fork would take the
  # counter with it and the assertion would blame the wrong thing.
  PATH="$shim:$PATH"
  wi_absent "$TB_WI_LIT" > "$TB_OUT" 2>&1
  PATH="$saved"
  tb_expect_red "wi_absent (no temp file): a failed mktemp reddens instead of routing into the clean-tree green" "$before"
  if /usr/bin/grep -q 'could not create the stderr capture file' "$TB_OUT"; then
    tb_ok "wi_absent (no temp file): the red names the capture file it could not create, so the git-exited branch is not answering for it"
  else
    tb_bad "wi_absent (no temp file): reddened for some reason other than the missing-capture-file branch"
  fi
  rm -rf "$shim"
}

# Case (c). What it proves is written once, in the (c) entry of the section
# header above, and is not restated here.
#
# THE FIXTURE IS A THROWAWAY REPOSITORY, never a sealed file in the working repo.
# `git init` under TB_TMP, one file, `git add`, then the seal. Sealing a real
# tracked file would leave the user's own tree holding something at mode 000 after
# any interrupt, and no cleanup discipline is worth that risk. TB_TMP is outside
# the repo, so the literal written into the fixture is invisible to every other
# scan in this suite. An index entry is enough here, no commit: `git grep` with no
# rev reads tracked files out of the working tree, measured.
#
# GIT_DIR AND GIT_WORK_TREE RATHER THAN A cd. wi_absent runs a bare `git grep`, so
# something has to point it at the fixture, and bash restores a variable
# assignment prefixed onto a FUNCTION call the moment that call returns. A cd
# would have to be undone by hand, and a cd left behind would be far worse than a
# leaked pathspec: TB_WI_SRC is a relative path, tb_wi_fixture_ready greps the
# real tree, and the driver's EXIT trap would be removing the shell's own cwd.
#
# git add's own status is not checked, and does not need to be. An untracked
# fixture is scanned by nothing, so wi_absent returns its clean-tree green and
# tb_expect_red reddens on the spot. The failure is loud either way.
tb_case_wi_unreadable_file() {
  local before="$FAILED"
  local repo="$TB_TMP/wi-sealed"
  local rc
  local -a WI_LIVE_PATHS
  TB_WI_FAILCLOSED=$((TB_WI_FAILCLOSED + 1))
  rm -rf "$repo"
  git init -q "$repo" > /dev/null 2>&1 && printf '%s\n' "$TB_WI_LIT" > "$repo/sealed.md" || { tb_bad "wi_absent (unreadable file): the throwaway repo could not be built, so this branch was never exercised"; return; }
  git -C "$repo" add sealed.md > /dev/null 2>&1
  chmod 000 "$repo/sealed.md"
  # THE SEAL IS PROVED, NOT ASSUMED, the way tb_make_unreadable proves its own
  # bit. chmod 000 is a no-op for root and on filesystems that ignore modes, and
  # the proof is an INDEPENDENT matcher rather than the git scan, because that
  # scan is the thing under test and cannot also be its own precondition.
  /usr/bin/grep -cF -e "$TB_WI_LIT" "$repo/sealed.md" > /dev/null 2>&1
  rc=$?
  [ "$rc" -gt 1 ] || { tb_bad "wi_absent (unreadable file): grep read the sealed file at rc $rc, so nothing was sealed and this branch was never exercised"; tb_drop_unreadable "$repo"; return; }
  WI_LIVE_PATHS=(':(top)sealed.md')
  tb_wi_scope_ready "wi_absent (unreadable file)" || { tb_drop_unreadable "$repo"; return; }
  GIT_DIR="$repo/.git" GIT_WORK_TREE="$repo" wi_absent "$TB_WI_LIT" > "$TB_OUT" 2>&1
  tb_drop_unreadable "$repo"
  tb_expect_red "wi_absent (unreadable file): a tracked file git cannot stat reddens instead of reporting the literal gone" "$before"
  # git writes the stat error TWICE, measured, so this asks whether the branch's
  # own wording is there rather than counting stderr lines.
  if /usr/bin/grep -q 'but wrote to stderr' "$TB_OUT"; then
    tb_ok "wi_absent (unreadable file): the red says git wrote to stderr, so an exit status of 1 is no longer being read as a clean tree"
  else
    tb_bad "wi_absent (unreadable file): reddened for some reason other than the stderr-on-rc-1 branch"
  fi
}

tb_check_wi_failclosed_total() {
  if [ "$TB_WI_FAILCLOSED" -eq "$TB_EXPECT_WI_FAILCLOSED" ]; then
    tb_ok "wi_absent fail-closed total: $TB_WI_FAILCLOSED cases actually ran, matching the expected $TB_EXPECT_WI_FAILCLOSED"
    return
  fi
  tb_bad "wi_absent fail-closed total: $TB_WI_FAILCLOSED case(s) actually ran, expected $TB_EXPECT_WI_FAILCLOSED (a case is no longer being called, or is being called twice)"
}
