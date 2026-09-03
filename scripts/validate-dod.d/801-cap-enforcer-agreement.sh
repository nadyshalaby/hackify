# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [80c] THIS VALIDATOR AND THE LAWKEEPER SCANNER SELECT THE SAME FILES.
#
# SPLIT OUT OF 80-file-size-caps.sh ON A SEAM, NOT AT A LINE COUNT. [80] asks a
# question about FILES: which ones exist, which bound applies to each, which are over
# it and which are close. This asks a question about ENFORCERS: two of them police one
# cap, and they must waive the same basenames and raise the bound over the same set.
# Neither is a subset of the other. Every file could be inside its bound while the two
# enforcers disagree about which bound that was, and they could agree perfectly about a
# corpus [80] never finished reading. That is why the counts [80] produces are asserted
# below before anything is compared, rather than assumed to have arrived.
#
# THE SAME SEAM [80b] ALREADY SITS ON, one file further along: [80b] cross-checks the
# two LINE COUNTERS at the cap boundary, this cross-checks the two SELECTIONS. Both are
# agreement checks and neither measures a file. [80b] stays in 80 rather than moving
# here only because its probe is that fragment's own path, derived from BASH_SOURCE:
# moving it would change what it measures, which is a different edit from relocating it.
#
# IT READS WHAT [80] MEASURED AND NEVER RE-MEASURES IT. cap_files, cap_prompt_set and
# cap_prompt_tier are the sets the cap loop actually used, so this compares against the
# enforcement that really happened rather than against a second scan that could differ
# from it. That inheritance is the coupling this split creates, and it is CHECKED below
# instead of trusted: sourced without 80, `set -u` would abort the whole run with a bare
# unbound-variable message naming no check, so the guard names the fault instead.
yellow "[80c] this check and the lawkeeper scanner waive and raise the cap over the same files"

# THE PRODUCER RAN, ASSERTED RATHER THAN ASSUMED. `:-` supplies a sentinel so an unset
# name cannot abort the run under `set -u` before this line can explain itself. A
# comparison between two sets that were never built is the "both sides empty" shape
# rules/claim-integrity.md names, and it prints green.
if [ -z "${cap_files:-}" ] || [ -z "${cap_prompt_tier:-}" ]; then
  red "  FAIL [80c] 80-file-size-caps.sh did not leave a measured file set behind, so there is nothing to cross-check the scanner against and a clean result here would be a comparison between two empty sets"
  FAILED=$((FAILED + 1))
# ONE INTERPRETER GUARD FOR BOTH CALLS BELOW, and it sits here because BOTH cross-checks
# import the scanner's module. Guarding only the second left the first still reporting
# "could not read APPEND_ONLY_BASENAMES", which blames a file that is fine for a fault
# that is a missing interpreter: the exact cost this fragment exists to stop paying.
elif ! command -v python3 > /dev/null 2>&1; then
  red "  FAIL [80c] python3 is not on PATH, so neither the exemption list nor the raised tier was cross-checked against $CAP_EXEMPTIONS; the fault is the missing interpreter and not that file"
  FAILED=$((FAILED + 1))
else
# THE MODULE NAME IS DERIVED FROM CAP_EXEMPTIONS, NOT HARDCODED, and that is a fix rather
# than a tidy-up. The import used to read `from exemptions import ...` while the `[ -f ]`
# guard below tested CAP_EXEMPTIONS, so the two could disagree about which file this check
# is even about: point CAP_EXEMPTIONS at any sibling module in that directory and the guard
# passed, the real exemptions.py was imported regardless, and the ok line named a file it
# had never opened. Reproduced by pointing it at lexer.py and watching it print green. That
# is the same shape as every other defect this fragment exists to refuse, a check reporting
# on one thing while measuring another.
cap_module="${CAP_EXEMPTIONS##*/}"
cap_module="${cap_module%.py}"

# A DERIVED NAME THAT IS NOT IMPORTABLE IS A FAILURE, NEVER A SILENT SKIP. A hyphen is legal
# in a filename and illegal in a module name, so renaming the scanner's set to something like
# append-only-exemptions.py would leave the file present, the `[ -f ]` guard green, and the
# import raising. Caught here it names the real problem; left to the import it would arrive as
# "could not read APPEND_ONLY_BASENAMES", which blames the contents of a file that is fine.
case "$cap_module" in
  '' | [0-9]* | *[!A-Za-z0-9_]*) cap_module_ok=0 ;;
  *) cap_module_ok=1 ;;
esac

cap_scanner_exempt() {
  python3 -c '
import importlib, sys
sys.path.insert(0, sys.argv[1])
print("\n".join(sorted(importlib.import_module(sys.argv[2]).APPEND_ONLY_BASENAMES)))
' "${CAP_EXEMPTIONS%/*}" "$cap_module" 2> /dev/null
}

cap_one_line() { echo "$1" | tr '\n' ' '; }

# Path list to basename set, the normalization the block comment above argues for.
# `sort -u` and not `sort`, because two exempt paths sharing a basename are ONE
# basename to the scanner and the two sides must still be able to agree.
cap_to_basenames() { sed 's|.*/||' | sort -u; }

cap_scanner_list=$(cap_scanner_exempt)
cap_shell_list=$(printf '%s\n' "$CAP_APPEND_ONLY" | cap_to_basenames)
cap_shell_count=$(printf '%s\n' "$cap_shell_list" | wc -l | tr -d ' ')
if [ ! -f "$CAP_EXEMPTIONS" ]; then
  red "  FAIL $CAP_EXEMPTIONS is missing, so nothing cross-checks this exemption list against the scanner's and the two can drift unobserved"
  FAILED=$((FAILED + 1))
elif [ "$cap_module_ok" -eq 0 ]; then
  red "  FAIL '$cap_module', derived from $CAP_EXEMPTIONS, is not a plain Python module name, so the set this check compares against can never be imported"
  FAILED=$((FAILED + 1))
elif [ -z "$cap_scanner_list" ]; then
  red "  FAIL could not read APPEND_ONLY_BASENAMES out of $CAP_EXEMPTIONS; a list that cannot be read is not a list that agrees"
  FAILED=$((FAILED + 1))
elif [ "$cap_scanner_list" != "$cap_shell_list" ]; then
  red "  FAIL this check waives basename(s) [$(cap_one_line "$cap_shell_list")] from the ${CAP_MAX_LOC}-LOC cap and $CAP_EXEMPTIONS waives [$(cap_one_line "$cap_scanner_list")]; the two enforcers of one cap would exempt different files"
  FAILED=$((FAILED + 1))
else
  green "  ok   CAP_APPEND_ONLY and $CAP_EXEMPTIONS waive the same ${cap_shell_count} basename(s) from the ${CAP_MAX_LOC}-LOC cap"
fi

# THE RAISED TIER IS CROSS-CHECKED THE SAME WAY, on the history that built [80b], but COMPARED
# ON WHAT EACH SIDE SELECTS, NEVER ON PATTERN STRINGS, which is the honest normalization rather
# than the convenient one. The two do not speak one pattern language: `*` crosses `/` in a shell
# `case` and in Python's fnmatch and not in `find -maxdepth 1`, so identically spelled globs can
# select different files and differently spelled ones the same, and string equality would assert
# what neither enforcer promises. Both DO promise a verdict per file, so each gives one over the
# list this scan already read, the shell side being the set the cap loop used and never a copy.
#
# THE INTERPRETER IS CHECKED BEFORE USE AND ITS STDERR IS KEPT. `2> /dev/null` here discarded
# the one sentence saying WHY nothing came back and no `$?` was read, so a missing python3 and
# a broken exemptions.py produced the same empty string and the `-z` branch blamed the file.
# [80b] does carry `command -v python3`, in cap_agree_ready, a different call further down that
# never covered this one. Captured and put in the message, as 41-required-reading.sh does it.
cap_perr=$(mktemp 2>/dev/null) || cap_perr=''
cap_pmsg_none="python3 printed nothing on stderr"
if [ -z "$cap_perr" ]; then
  # A NOTE AND NOT A RED, because the cross-check below is UNAFFECTED: it runs with `2>
  # /dev/null`, which is exactly what this chain did before the capture was added, and the ok
  # line still prints on agreement. Only the DIAGNOSTIC is lost, so the honest tier is the soft
  # one 80-file-size-caps.sh uses for cap_stale and the near-cap warning. Reddening here would
  # fail a run whose comparison was sound, and saying the check "never ran" beside its own green
  # would be the false claim rules/claim-integrity.md exists to stop.
  yellow "  note could not create a stderr capture file, so a FAIL below can quote nothing python3 said"
  cap_perr=/dev/null
  # AND THE FALLBACK CHANGES WITH IT. `cat /dev/null` is empty, so the default text would swear
  # python3 printed nothing when the truth is that its output was discarded unread.
  cap_pmsg_none="stderr could not be captured on this run"
fi
cap_prompt_raw=$(printf '%s\n' "$cap_files" | python3 -c '
import importlib, sys
sys.path.insert(0, sys.argv[1])
mod = importlib.import_module(sys.argv[2])
hits = sorted(p for p in sys.stdin.read().splitlines() if p and mod.is_prompt_template(p))
print(len(mod.PROMPT_TEMPLATE_GLOBS))  # after the hits, so a half-read prints NOTHING and the
print("\n".join(hits))                # `-z` branch below names the real fault instead of the set
' "${CAP_EXEMPTIONS%/*}" "$cap_module" 2> "$cap_perr")
cap_pmsg=$(cat "$cap_perr" 2>/dev/null)
# NEVER `rm -f /dev/null`: on the fallback path above cap_perr IS the device, and as
# root in CI that removes it for every process after this one. 41-required-reading.sh
# guards the same way, which is the model this block cites.
[ "$cap_perr" = /dev/null ] || rm -f "$cap_perr"
cap_prompt_globs="${cap_prompt_raw%%"$CAP_NL"*}"
cap_prompt_scanner="${cap_prompt_raw#"$cap_prompt_globs"}"
cap_prompt_scanner="${cap_prompt_scanner#"$CAP_NL"}"
# LC_ALL=C SO THIS SIDE COLLATES BY CODEPOINT, which is what Python's sorted() does, and so does
# the comm below. Under en_US.UTF-8 `sort` files README.md elsewhere, and both comparisons read an
# ordering difference as a disagreement about contents. MEASURED: it was a live red right here.
cap_prompt_shell=$(printf '%s' "$cap_prompt_set" | LC_ALL=C sort)

# THE EMPTY-TIER FLOOR IS NOT DECORATION: two empty sets compare equal and print green, the "comparison whose two sides are both empty" rules/claim-integrity.md names.
if [ "$cap_prompt_tier" -eq 0 ]; then
  red "  FAIL the raised tier matched no scanned file, so the ${CAP_PROMPT_TEMPLATE_MAX_LOC}-LOC bound enforced nothing and the agreement checked below would be between two empty sets"
  FAILED=$((FAILED + 1))
elif [ -z "$cap_prompt_globs" ]; then
  red "  FAIL could not read PROMPT_TEMPLATE_GLOBS and is_prompt_template out of $CAP_EXEMPTIONS; a carve-out that cannot be read is not a carve-out that agrees: ${cap_pmsg:-$cap_pmsg_none}"
  FAILED=$((FAILED + 1))
elif [ "$cap_prompt_globs" != "$CAP_PROMPT_TEMPLATE_GLOBS_EXPECTED" ]; then
  red "  FAIL $CAP_EXEMPTIONS carries $cap_prompt_globs PROMPT_TEMPLATE_GLOBS entr(ies), expected exactly $CAP_PROMPT_TEMPLATE_GLOBS_EXPECTED; the selection check below cannot see a glob aimed at a directory cap_file_list never walks, which would widen the scanner's waiver while both selections stayed identical"
  FAILED=$((FAILED + 1))
elif [ "$cap_prompt_scanner" != "$cap_prompt_shell" ]; then
  red "  FAIL [80] held ${cap_prompt_tier} file(s) to ${CAP_PROMPT_TEMPLATE_MAX_LOC} LOC while $CAP_EXEMPTIONS waives cap.file-lines on a different set; they disagree about [$(LC_ALL=C comm -3 <(printf '%s\n' "$cap_prompt_shell") <(printf '%s\n' "$cap_prompt_scanner") | tr -d '\t' | tr '\n' ' ')]"
  FAILED=$((FAILED + 1))
else
  green "  ok   [80] and $CAP_EXEMPTIONS select the same ${cap_prompt_tier} prompt template(s), matched by its ${cap_prompt_globs} glob(s), for the raised ${CAP_PROMPT_TEMPLATE_MAX_LOC}-LOC bound"
fi
fi
