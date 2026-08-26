#!/usr/bin/env bash
# [81] No Claude attribution in commits or PR bodies.
#
# WHY THIS EXISTS AS A CHECK AND NOT ONLY AS PROSE. The rule this guards is one
# the runtime harness actively pushes the other way: Claude Code ships a standing
# instruction to end every commit message with a Co-Authored-By trailer and to
# footer every PR body with a generated-with line. So the failure mode here is
# not a careless edit, it is a default reasserting itself, which is the kind that
# comes back quietly and repeatedly. Prose alone lost that argument once already,
# every one of the five sites below USED to instruct the trailer.
#
# TWO HALVES, and both are needed. The ban catches the attribution walking back
# into the shipped surface. The presence pins catch the opposite tamper, someone
# deleting the rule sentence: with the rule gone and no banned token yet written,
# a ban-only check is perfectly green over a skill that no longer says anything.
#
# THE SCAN LIST IS EXHAUSTIVE OVER WHAT SHIPS, and the exclusions below are the
# whole of the difference. Everything a user installs is walked: the six trees of
# CAP_SEARCH_PATHS in 80-file-size-caps.sh minus scripts/, plus .claude-plugin/
# and README.md. hooks/ is in that list on purpose rather than by accident, it is
# the tree that injects rule text into every prompt through UserPromptSubmit, so
# it is the likeliest place for commit guidance to come back and the worst place
# for this check to have been green over.
#
# NOT SCANNED, deliberately, and this is the complete list: scripts/ (this file
# names the tokens it bans, so scanning itself would be an instant false red),
# dist/ (generated copies of the shipped trees, so a clean source is a clean dist
# and [56] already proves they match), and docs/work/ (archived work-docs are
# historical records of what happened, including commits that really did carry
# trailers; rewriting history to satisfy a rule adopted later is exactly the
# falsification rules/claim-integrity.md bans).

yellow "[81] commits and PR bodies carry no Claude attribution"

# THE TOKENS ARE TRAILER-SHAPED, NOT MENTION-SHAPED, and that is load-bearing
# rather than loose. A rule that forbids a trailer has to NAME the trailer to be
# readable, so every site stating this rule contains the words `Co-Authored-By:`
# and `Claude-Session:`. Banning those bare strings reds the rule for stating
# itself, which is the shape this check first shipped in and failed on within a
# minute. Each token therefore carries the part only a REAL trailer has: the
# value after the colon, the bracketed link form of the footer, the address. Do
# not "tighten" these back to the bare names; that turns the rule text into a
# violation of itself. Screened case-insensitively by check_no_tokens_in's
# grep -i, so a lower-cased or shouted variant is caught by the same entry.
CA_BANS=('Co-Authored-By: Claude' 'Claude-Session: https' 'Generated with [Claude Code]' 'noreply@anthropic.com')
check_list_size "${#CA_BANS[@]}" 4 "the [81] attribution ban list"

# Directories, not files: grep -r walks them, so a NEW skill or agent file that
# reintroduces the trailer is caught without this list being edited to name it.
for ca_path in skills agents rules commands hooks .claude-plugin README.md; do
  check_no_tokens_in "$ca_path" "${CA_BANS[@]}"
done

# The rule itself, at each site that states it. Worded differently per site on
# purpose, each one is the sentence a reader of THAT file meets, so a pin here is
# a pin on the reader's actual instruction rather than on a boilerplate line.
check_token_present 'NO CLAUDE ATTRIBUTION, in the commit or anywhere else it lands.' \
  "skills/hackify/references/implement-and-test.md"
check_token_present 'carries NO Claude attribution' \
  "skills/hackify/references/phases/phase-6-finish.md"
check_token_present 'no generated-with footer and no Claude attribution of any kind' \
  "skills/hackify/references/finish.md"
check_token_present 'carries no Claude attribution' \
  "skills/yolo/evals/evals.json"

# THE OVERRIDE MUST STAY SAID OUT LOUD. A reader who meets only "do not add the
# trailer" while the harness instruction says "always add the trailer" has two
# rules and no precedence, and the harness one is the one in front of them at the
# moment they write the commit. Both prose sites name the conflict and resolve it.
check_token_present 'this rule OVERRIDES it' "skills/hackify/references/implement-and-test.md"
check_token_present 'this overrides it' "skills/hackify/references/finish.md"
check_token_present 'the harness may instruct otherwise and this overrides it' \
  "skills/hackify/references/phases/phase-6-finish.md"
