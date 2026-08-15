# shellcheck shell=bash

# [75] Ship-bar wiring, the v0.9.0 always-on contract.
#
# Four mechanisms became mandatory in EVERY mode and take no user opt-in:
# the law-scout (bundled lawkeeper scanner scoped to touched files), the ship
# gate (build/boot/smoke), Reviewer F (cross-module coherence), and the
# refute-before-fix step with a settled-diff exit condition.
#
# Prose rules drift. These checks make a mode that quietly drops one of the
# four fail loudly, which is the same failure mode check [38] was written for
# after the perf-guardrails hook injection went missing.

SHIP_BAR_MODES="skills/hackify/SKILL.md skills/quick/SKILL.md skills/yolo/SKILL.md"
LAW_SCOUT_REF="skills/hackify/references/law-scout.md"
SHIP_GATE_REF="skills/hackify/references/ship-gate.md"
COHERENCE_TPL="skills/hackify/references/parallel-agents/phase-5-multi-review-f-coherence.md"
REFUTE_TPL="skills/hackify/references/parallel-agents/phase-5-refute.md"

yellow "[75] ship-bar protocol files exist and are non-empty"
for f in "$LAW_SCOUT_REF" "$SHIP_GATE_REF" "$COHERENCE_TPL" "$REFUTE_TPL"; do
  if [ ! -s "$f" ]; then
    red "  FAIL $f missing or empty"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f exists and non-empty"
  fi
done

yellow "[75b] every mode wires all four always-on mechanisms"
# One token per mechanism, chosen to be the reference path each mode must
# cite, so a mode that mentions the idea without wiring the protocol fails.
for m in $SHIP_BAR_MODES; do
  # Every token is a file path on purpose: a bare word like "coherence" would
  # pass on a mode file that merely mentions the idea in prose, including one
  # explaining why it skips the lens.
  for tok in 'law-scout.md' 'ship-gate.md' 'phase-5-refute.md' 'phase-5-multi-review-f-coherence.md'; do
    if grep -qF -- "$tok" "$m"; then
      green "  ok   $m wires '$tok'"
    else
      red "  FAIL $m does not wire '$tok' (ship-bar mechanism missing from this mode)"
      FAILED=$((FAILED + 1))
    fi
  done
done

yellow "[75c] ship gate names its three ledger rows in every mode"
for m in $SHIP_BAR_MODES; do
  for row in 'ship.build' 'ship.boot' 'ship.smoke'; do
    if grep -qF -- "$row" "$m"; then
      green "  ok   $m names ledger row '$row'"
    else
      red "  FAIL $m missing ship-gate ledger row '$row'"
      FAILED=$((FAILED + 1))
    fi
  done
done

yellow "[75d] law-scout invokes the bundled scanner by path with a scoped run"
# The law-scout's whole premise is that it runs a file inside this plugin
# rather than calling the lawkeeper skill. If the invocation or the scoping
# flag disappears, the protocol silently becomes a whole-tree sweep (or a
# skill call, which SKILL.md forbids).
for tok in 'skills/lawkeeper/scripts/audit_scan.py' '--paths-from'; do
  if grep -qF -- "$tok" "$LAW_SCOUT_REF"; then
    green "  ok   $LAW_SCOUT_REF invokes '$tok'"
  else
    red "  FAIL $LAW_SCOUT_REF missing '$tok' (scoped bundled-scanner invocation)"
    FAILED=$((FAILED + 1))
  fi
done
if grep -qF -- 'paths-from' skills/lawkeeper/scripts/audit_scan.py; then
  green "  ok   audit_scan.py implements --paths-from"
else
  red "  FAIL audit_scan.py does not implement --paths-from (law-scout cannot scope its run)"
  FAILED=$((FAILED + 1))
fi

yellow "[75e] SKILL.md carves out bundled-script execution from the no-skill-calls rule"
# SKILL.md says "Never call other skills". Running the bundled lawkeeper
# scanner by path is not a skill call, and the exemption must be stated
# where the rule is, or a future reader resolves the conflict by dropping
# the scout.
if grep -qF 'is not a skill call' skills/hackify/SKILL.md; then
  green "  ok   skills/hackify/SKILL.md states the bundled-script carve-out"
else
  red "  FAIL skills/hackify/SKILL.md does not carve bundled-script execution out of 'Never call other skills'"
  FAILED=$((FAILED + 1))
fi

yellow "[75f] review loop exits on a settled diff, not the first clean scan"
RAV="skills/hackify/references/review-and-verify.md"
if grep -qF 'unchanged since' "$RAV" || grep -qF 'settled diff' "$RAV"; then
  green "  ok   $RAV states the settled-diff exit condition"
else
  red "  FAIL $RAV missing the settled-diff exit condition (a clean scan on a stale diff must not end the loop)"
  FAILED=$((FAILED + 1))
fi

yellow "[75g] refuter defaults to keeping the finding (the shipping-code asymmetry)"
# A refuter panel tuned to 'default refuted' is right for generated content
# and wrong for shipping code: dropping a real defect costs more than fixing
# a phantom. If this bias inverts, the refuter becomes a finding shredder.
if grep -qiF 'default to keeping the finding' "$REFUTE_TPL"; then
  green "  ok   $REFUTE_TPL defaults to keeping the finding"
else
  red "  FAIL $REFUTE_TPL missing the keep-by-default asymmetry"
  FAILED=$((FAILED + 1))
fi

yellow "[75h] agent mirrors are byte-identical to the canonical source they claim to mirror"
# Four agent files assert "mirrors its fenced block byte-for-byte". Until
# v0.9.0 that was verified by hand (the 0.8.1 release notes say so). A claim
# nothing checks is a claim that drifts, and the mirrors just multiplied.
#
# Extraction: the outer fence is a line of exactly three backticks; the
# OUTPUT report skeletons inside use four, so they never terminate the block.
PA="skills/hackify/references/parallel-agents"
extract_fenced() {
  awk '/^```$/{n++} n>=1 && n<=2 {print} n==2{exit}' "$1"
}
# "<agent file>|<canonical source>" pairs.
MIRROR_PAIRS="
agents/code-reviewer-performance.md|$PA/phase-5-multi-review-d-performance.md
agents/design-conformance-reviewer.md|$PA/phase-5-multi-review-e-design.md
agents/code-reviewer-coherence.md|$PA/phase-5-multi-review-f-coherence.md
agents/finding-refuter.md|$PA/phase-5-refute.md
"
while IFS='|' read -r mirror canonical; do
  [ -n "$mirror" ] || continue
  if [ ! -f "$mirror" ] || [ ! -f "$canonical" ]; then
    red "  FAIL mirror pair missing a side: $mirror <-> $canonical"
    FAILED=$((FAILED + 1))
    continue
  fi
  if diff -q <(extract_fenced "$mirror") <(extract_fenced "$canonical") > /dev/null 2>&1; then
    green "  ok   $(basename "$mirror") is byte-identical to $(basename "$canonical")"
  else
    red "  FAIL $mirror drifted from $canonical (the file claims byte-for-byte mirroring)"
    diff <(extract_fenced "$mirror") <(extract_fenced "$canonical") | head -6 | sed 's/^/         /'
    FAILED=$((FAILED + 1))
  fi
done <<MIRROR_EOF
$MIRROR_PAIRS
MIRROR_EOF

yellow "[75i] orchestration tier + iteration driver are wired as defaults in every mode"
# `ultracode` and `/loop` became workflow DEFAULTS in v0.9.0. Both are
# Claude-Code-native tokens, so they live behind the two abstract primitives
# in runtime-adapters.md rather than in the workflow body. Three ways this
# can silently rot: a mode stops citing the contract, the runtime mapping
# loses one of the native tokens, or the standing authorization loses its
# opt-out (which would make a default grant unrevocable).
ORCH_REF="skills/hackify/references/orchestration.md"
ADAPTERS_REF="skills/hackify/references/runtime-adapters.md"

if [ ! -s "$ORCH_REF" ]; then
  red "  FAIL $ORCH_REF missing or empty"
  FAILED=$((FAILED + 1))
else
  green "  ok   $ORCH_REF exists and non-empty"
fi

for m in $SHIP_BAR_MODES; do
  if grep -qF -- 'orchestration.md' "$m"; then
    green "  ok   $m wires the orchestration contract"
  else
    red "  FAIL $m does not cite orchestration.md (tier + iteration driver missing from this mode)"
    FAILED=$((FAILED + 1))
  fi
done

# The native tokens must resolve through the adapter table, not float free.
for tok in 'ultracode' '/loop'; do
  if grep -qF -- "$tok" "$ADAPTERS_REF"; then
    green "  ok   $ADAPTERS_REF maps '$tok' to a primitive"
  else
    red "  FAIL $ADAPTERS_REF does not map '$tok' (Claude Code native token has no primitive home)"
    FAILED=$((FAILED + 1))
  fi
done
for prim in 'orchestration tier' 'iteration driver'; do
  if grep -qF -- "$prim" "$ADAPTERS_REF"; then
    green "  ok   $ADAPTERS_REF declares the '$prim' primitive"
  else
    red "  FAIL $ADAPTERS_REF missing the '$prim' primitive row"
    FAILED=$((FAILED + 1))
  fi
done

# A standing default grant that cannot be revoked is not a default, it is a
# lock-in. Every mode must name at least one opt-out phrase.
for m in $SHIP_BAR_MODES; do
  if grep -qF -- 'light mode' "$m"; then
    green "  ok   $m names the orchestration opt-out"
  else
    red "  FAIL $m does not name an opt-out for the standing ultracode grant"
    FAILED=$((FAILED + 1))
  fi
done

# The iteration driver must never be pointed at an intra-phase loop.
if grep -qF 'never the iteration driver' "$ORCH_REF"; then
  green "  ok   $ORCH_REF fences the iteration driver out of intra-phase loops"
else
  red "  FAIL $ORCH_REF missing the layer fence (a /loop inside Phase 5 breaks the ledger)"
  FAILED=$((FAILED + 1))
fi

yellow "[75j] question banks obey the wizard-contract Clarity law"
# The banks kept shipping questions the user could not answer without knowing
# hackify's internals (task IDs, phase numbers, DoD, sub-agent). The checker
# splits each bank by audience and polices only the user-facing half, so
# `Why-this-matters` keeps every internal word it needs.
if python3 scripts/check_question_clarity.py > /tmp/hackify-clarity.$$ 2>&1; then
  green "  ok   $(tail -1 /tmp/hackify-clarity.$$)"
else
  red "  FAIL question banks violate the Clarity law:"
  sed 's/^/         /' /tmp/hackify-clarity.$$
  FAILED=$((FAILED + 1))
fi
rm -f /tmp/hackify-clarity.$$

yellow "[75k] wizard contract states the always-wizard rule and the clarity law"
WIZ="skills/hackify/references/clarify-questions/wizard-contract.md"
for tok in 'Clarity law' 'every phase' 'Banned from user-facing text' 'What happens'; do
  if grep -qF -- "$tok" "$WIZ"; then
    green "  ok   $WIZ states '$tok'"
  else
    red "  FAIL $WIZ missing '$tok'"
    FAILED=$((FAILED + 1))
  fi
done
