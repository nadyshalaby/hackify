# shellcheck shell=bash

# [75j] AND [75k], THE WIZARD CONTRACT AND THE QUESTION BANKS IT GOVERNS, split
# out of 75-ship-bar.sh at the 500-LOC cap check [80] enforces, ids unmoved for
# the reason 751-orchestration-tier.sh states at its own head.
#
# WHY THIS IS ITS OWN RESPONSIBILITY. Everything else that carried a 75 id is
# about a mechanism wired into every MODE: what the ship bar runs, what the
# orchestration defaults grant, which files mirror which. These two are about the
# QUALITY OF A QUESTION PUT TO THE USER, the Clarity law and the contract that
# states it, and they reach the mode files not at all. They sat under [75]
# because the wizard contract shipped in the same release, which is a date and
# not a boundary.
#
# TWO CHECKS AND NOT ONE, kept together because they are two halves of one
# question: [75j] runs the checker over the banks, and [75k] asserts that the
# contract those banks are judged against still states the rule. Either alone
# goes green over the other's failure, which is the shape 82-throughput-and-
# routing.sh calls pinning the claim AND banning the wording it replaced.

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
