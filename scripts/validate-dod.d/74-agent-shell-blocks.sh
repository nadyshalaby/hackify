# ---------------------------------------------------------------------------
# [74] every fenced shell block in a dispatchable agent template parses
# ---------------------------------------------------------------------------
# WHY THIS EXISTS. A sub-agent template's VERIFICATION section ships runnable
# shell, and the agent runs it as its own pass/fail gate. Nothing else in this
# validator ever parses that shell, so a syntax error in it is invisible: the
# template is markdown, so no linter opens it; the agent that runs it reports
# the abort as its own failure, if it reports anything at all.
#
# This is not hypothetical. `phase-3-module-implementation.md` shipped a `case`
# whose pattern's `)` closed the enclosing `$(`, in bash 3.2, which is macOS's
# /bin/bash. The whole block was a parse error, so the allowlist check, the
# per-track database check and the project gate all never executed, and the
# full validator, a 159-test tamper battery and the ban-token suite were green
# over it for the entire sprint. A Phase 5 reviewer found it by reading.
#
# THAT FILE IS GONE AND THE LESSON IS NOT. 0.17.1 merged its prompt into
# `phase-3-implementation.md`, which is still listed below and still carries a
# fenced VERIFICATION block with a `case` in it. The incident is kept here rather
# than deleted with the file, because it is the answer to "why does a markdown
# validator parse shell", and a check whose reason has been edited out of it is
# the next check somebody deletes as unexplained.
#
# The check parses rather than runs: running would execute a template's project
# gate, which is arbitrary shell by design. Placeholders are substituted with
# inert text first, because `{{x}}` is not valid shell and would red every
# template.
yellow "[74] every fenced shell block in a dispatchable agent template parses under /bin/bash"

ASB_DIR="skills/hackify/references/parallel-agents"
# Written out rather than globbed, the same argument the mirror and template
# lists make: a template that stops being listed stops being checked, and a
# glob makes that silent. The count below is written a second time on purpose.
ASB_FILES=(
  "$ASB_DIR/phase-3-implementation.md"
  "$ASB_DIR/phase-2.5-spec-reviewer.md"
  "$ASB_DIR/investigation.md"
  "$ASB_DIR/phase-5-refute.md"
  "$ASB_DIR/phase-5-aggregation.md"
  "$ASB_DIR/phase-5-multi-review-a-security.md"
  "$ASB_DIR/phase-5-multi-review-b-quality-plan.md"
  "$ASB_DIR/phase-5-multi-review-d-performance.md"
  "$ASB_DIR/phase-5-multi-review-e-design.md"
  "$ASB_DIR/phase-5-multi-review-f-coherence.md"
  "$ASB_DIR/phase-5-multi-review-merged.md"
)
ASB_EXPECTED=11

check_list_size "${#ASB_FILES[@]}" "$ASB_EXPECTED" "the [74] template set"

ASB_SCANNED=0
ASB_BLOCKS=0
for asb_f in "${ASB_FILES[@]}"; do
  if [ ! -f "$asb_f" ]; then
    red "  FAIL [74] $asb_f is listed but not on disk"
    FAILED=$((FAILED + 1))
    continue
  fi
  ASB_SCANNED=$((ASB_SCANNED + 1))
  asb_tmp="$(mktemp)"
  # Pull every ```bash fence, blank the placeholders, and parse the result.
  awk '/^```bash$/{inb=1;next} /^```$/{if(inb){print "### END-OF-BLOCK ###";inb=0};next} inb{print}' \
    "$asb_f" \
    | sed -e 's/{{[a-z_]*}}/placeholder_value/g' -e 's/<[^>]*>/placeholder_value/g' \
    > "$asb_tmp"
  if [ ! -s "$asb_tmp" ]; then
    green "  ok   $(basename "$asb_f") declares no fenced shell block to parse"
    rm -f "$asb_tmp"
    continue
  fi
  ASB_BLOCKS=$((ASB_BLOCKS + 1))
  if asb_err="$(/bin/bash -n "$asb_tmp" 2>&1)"; then
    green "  ok   $(basename "$asb_f") fenced shell parses under $(/bin/bash --version | head -1 | awk '{print $4}')"
  else
    red "  FAIL $(basename "$asb_f") fenced shell does NOT parse, so the agent's own gate aborts before it checks anything: $asb_err"
    FAILED=$((FAILED + 1))
  fi
  rm -f "$asb_tmp"
done

green "  ok   [74] checked $ASB_BLOCKS fenced shell block(s) across $ASB_SCANNED listed template(s); a block that failed to parse is reported on its own line above, not subtracted from this count"
