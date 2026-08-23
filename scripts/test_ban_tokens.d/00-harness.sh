# shellcheck shell=bash

# THE HARNESS: how a case reports, and what it reads before it can report.
# Nothing here asserts anything about the ban lists; it is the scaffolding every
# case in the sibling fragments is written against. Split out of
# test_ban_tokens.sh when that file reached the 500-LOC hard cap.

tb_ok()  { TB_PASS=$((TB_PASS + 1)); printf '  pass %s\n' "$1"; }
tb_bad() { TB_BAD=$((TB_BAD + 1)); printf '  BAD  %s\n' "$1"; }

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
