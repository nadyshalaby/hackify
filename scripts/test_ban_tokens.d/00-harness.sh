# shellcheck shell=bash

# THE HARNESS: how a case reports, and what it reads before it can report.
# Nothing here asserts anything about the ban lists; it is the scaffolding every
# case in the sibling fragments is written against. Split out of
# test_ban_tokens.sh when that file reached the 500-LOC hard cap.

tb_ok()  { TB_PASS=$((TB_PASS + 1)); printf '  pass %s\n' "$1"; }
tb_bad() { TB_BAD=$((TB_BAD + 1)); printf '  BAD  %s\n' "$1"; }

# Fail-closed cases that actually RAN, moved by those cases in
# 10-ban-list-cases.sh and read once by tb_check_failclosed_total in
# 30-inventory-pins.sh. Same bargain TB_PLANTED makes: these cases hang off
# tb_case_green_path rather than off their own line in the run order, so nothing
# in the run order can show they happened, and a counter is the only thing that
# tells "ran and passed" apart from "was never called".
TB_FAILCLOSED=0

# The neighbouring defect, counted apart from it because it is not the same one.
# Fail-closed is a count that was never taken; a miscount is a count that was
# taken and read wrong. Both end in a green over content the check did not
# actually clear, and both hang off tb_case_green_path, so both need a counter.
TB_MISCOUNT=0

# ---------------------------------------------------------------------------
# The unreadable-path fixture. grep exits 2 on a path it cannot read, which is
# the branch the fail-closed cases exist for, and the ONLY reliable way to
# produce that status is a real permission bit.
#
# EXACTLY ONE FILE IN THE DIRECTORY, and it is sealed. A readable sibling would
# print its own count line, so the substitution would come back non-empty and the
# failure would hide behind a number instead of an empty stdout, which is the
# harder shape and not the one being tested here.
#
# THE MODE IS PROVED, NOT ASSUMED. `chmod 000` is a no-op for root and on
# filesystems that ignore modes, and `[ -r ]` answers yes for root regardless, so
# the precondition is checked by running the matcher itself and requiring the
# status the cases are about to assert against. A fail-closed case that quietly
# could not seal anything is the measures-nothing shape this whole suite refuses.
# Caller owns cleanup through tb_drop_unreadable.
# ---------------------------------------------------------------------------
tb_make_unreadable() {
  local dir="$1"
  local rc
  rm -rf "$dir"
  mkdir -p "$dir" || return 1
  printf 'panel is five\n' > "$dir/sealed.md" || return 1
  chmod 000 "$dir/sealed.md" || return 1
  /usr/bin/grep -rcFiI -- 'panel is five' "$dir" > /dev/null 2>&1
  rc=$?
  [ "$rc" -gt 1 ]
}

# THE MODE IS RESTORED BEFORE THE REMOVAL, and the file is sealed rather than its
# parent for the same reason: `rm -rf` needs write on the DIRECTORY, so a sealed
# file still unlinks while a sealed directory would defeat the EXIT trap and leave
# temp trees behind for good. Restoring here rather than leaning on the trap also
# means a case that dies half way through leaves nothing at mode 000.
tb_drop_unreadable() {
  local dir="$1"
  chmod 644 "$dir/sealed.md" 2>/dev/null
  rm -rf "$dir"
}

# ---------------------------------------------------------------------------
# Token-list extraction. shlex parses the shell single-quoting exactly, so a
# token containing spaces survives, and newline-delimited output is safe because
# a token carrying a newline is itself a defect the token guard reddens.
# ---------------------------------------------------------------------------
tb_extract_lists() {
  python3 - "$TB_SRC_70" "$TB_SRC_77" "$TB_TMP" <<'PY'
import io, re, shlex, sys, os
src70, src77, tmp = sys.argv[1], sys.argv[2], sys.argv[3]

# All three lists are shell arrays, so one parser serves all of them, and it reads
# bare words and quoted words alike. An empty parse exits non-zero right here
# instead of writing an empty list, because a section handed nothing to plant
# prints nothing and passes, which is the exact bug this suite exists to refuse.
# The old "expected exactly 1 batched ban call" assert stood here and is retired,
# not dropped: it policed one file by reading one call's literal arguments, and
# tb_check_call_sites below counts the batched calls across the whole fragment
# directory instead, which is the wider claim CHANGELOG.md actually makes.
def parse_array(path, name):
    pat = re.compile(r'^%s\+?=\((.*)\)\s*$' % name)
    toks = []
    for line in io.open(path, encoding="utf-8"):
        m = pat.match(line)
        if m:
            toks.extend(shlex.split(m.group(1)))
    if not toks:
        sys.exit("no %s group parsed from %s" % (name, path))
    return toks

lists = (("tokens70.txt", parse_array(src70, "P5_BANS")),
         ("tokens77.txt", parse_array(src77, "RR_BANS")),
         ("tokens77rpt.txt", parse_array(src77, "RR_RPT")))
for name, toks in lists:
    with io.open(os.path.join(tmp, name), "w", encoding="utf-8") as fh:
        fh.write("".join(t + "\n" for t in toks))
PY
}

# Load one newline-delimited token file into TB_LIST, the array every ban call
# below is made with. Read into a global rather than echoed back, because a
# command substitution would flatten the tokens that contain spaces.
tb_load_list() {
  local listfile="$1"
  local t
  TB_LIST=()
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    TB_LIST+=("$t")
  done < "$listfile"
}

# ---------------------------------------------------------------------------
# Assertions. Every one checks the FAILED counter as well as the printed text,
# because "prints red, exits 0" is the specific bug 77-reviewer-roster.sh
# documents against itself and the bug a subshell increment reintroduces.
# Redirection on a function call does not fork, so FAILED survives the capture.
# ---------------------------------------------------------------------------
tb_expect_red() {
  local label="$1"
  local before="$2"
  if [ "$FAILED" -le "$before" ]; then
    tb_bad "$label: printed its verdict but FAILED did not move ($before -> $FAILED)"
    return
  fi
  if ! /usr/bin/grep -q 'FAIL' "$TB_OUT"; then
    tb_bad "$label: FAILED moved but no FAIL line was printed"
    return
  fi
  tb_ok "$label"
}

tb_expect_green() {
  local label="$1"
  local before="$2"
  if [ "$FAILED" -ne "$before" ]; then
    tb_bad "$label: clean input still moved FAILED ($before -> $FAILED)"
    return
  fi
  if /usr/bin/grep -q 'FAIL' "$TB_OUT"; then
    tb_bad "$label: clean input printed a FAIL line"
    return
  fi
  tb_ok "$label"
}
