# shellcheck shell=bash

# [77] Reviewer-roster and panel-count drift, over the file set [70]'s ban loop
# never covered.
#
# WHY THIS EXISTS: the Phase 5 panel stopped being a fixed number in v0.13.0.
# B (quality and plan) is the standing floor and always runs. A (security),
# D (performance) and F (coherence) are gated on evidence. E (design) joins on
# UI-bearing diffs. So the true floor is 1 and the ceiling is 5, and ANY
# hardcoded lower bound is wrong: it denies the gate and tells an orchestrator
# to dispatch reviewers the evidence does not justify. Phase 2.5 is the same
# story from the other side, it dispatches exactly ONE spec reviewer carrying
# three lenses (agents/spec-reviewer.md, "Dispatch exactly one"), so a plural
# spec-reviewer count is stale for the same reason.
#
# The prose describing all of that has now gone stale three releases running.
# [70]'s loop catches the sites its own file list enumerates, but that list grew
# by hand around the hackify skill, and the three sites fixed this sprint were
# in NO ban list at all. That is why they survived every earlier sweep with the
# validator fully green:
#   skills/yolo/SKILL.md:114                   "4-to-5 parallel reviewers"
#   parallel-agents/phase-5-aggregation.md:5   "2 spec reviewers", "the 5-to-6 reviewer panel"
#   references/review-scope.md:9               "The panel is five now"
#
# Why a grep is the right tool: the defect is a literal sentence a human types
# into an executable instruction. There is no structure to parse and no runtime
# to observe, the wrong number simply reads as fact to the next agent. A
# substring ban over a named file set fires on the exact words a future author
# would reach for, costs milliseconds, and carries no count of its own to rot.
#
# WHAT IS BANNED, AND WHAT DELIBERATELY IS NOT. Every token below is CLAIM
# grammar: a range ("4 to 5"), a dispatch count ("five parallel reviewers"), a
# panel identity ("the panel is five"), or a spec-reviewer plural. The bare
# count-plus-noun form ("two reviewers", "six reviewers") is NOT banned, because
# that is where legitimate prose lives. Proven by two hits inside this very file
# set: review-and-verify.md:141 says "Two reviewers consume a deterministic
# scout run", a correct statement about B and D, and review-scope.md:9 says
# "Six reviewers each ran `git diff`", the historical cost that motivated
# slicing. A ban that reddens on correct text gets deleted, so it is not bought.
# Anchor-free word ranges ("four or five") are skipped for the same reason, they
# read as ordinary quantities. Every token here was verified absent from all six
# files before being added.
#
# Documented bias: source only. dist/ is regenerated from these files, so a
# stale count in a built tree is a sync problem rather than this block's. [70]
# is source-only for the same reason.
#
# THE VACUOUS-PASS GUARD IS THE POINT OF THIS BLOCK. check_no_token runs
# `grep -rcFiI` and a path that does not exist produces no output, which sums to
# 0, which prints green. One typo in the list below and the entire check
# silently measures nothing, which is the trap this repo has already been bitten
# by. So: every path is asserted to exist and be non-empty BEFORE a single token
# is banned over it, a bad path fails loudly and is then SKIPPED so it cannot
# contribute fake greens, and the parsed-path count carries a floor so a mangled
# list cannot pass by iterating zero times. check_token_present 'reviewer' per
# file is the relevance pin: a covered file that no longer discusses reviewers
# is either the wrong path or a file whose ban list needs rethinking.

yellow "[77] reviewer-roster drift, panel counts and spec-reviewer counts in the files [70] does not cover"

RR_PA="skills/hackify/references/parallel-agents"
RR_FILES="skills/yolo/SKILL.md skills/quick/SKILL.md"
RR_FILES="$RR_FILES skills/hackify/references/review-scope.md"
RR_FILES="$RR_FILES $RR_PA/phase-5-aggregation.md"
RR_FILES="$RR_FILES skills/hackify/references/phases/phase-5-review.md"
RR_FILES="$RR_FILES skills/hackify/references/review-and-verify.md"

# Existence gate. Runs to completion before any ban, see the header.
RR_PARSED=0
RR_BAD=0
for f in $RR_FILES; do
  RR_PARSED=$((RR_PARSED + 1))
  [ -s "$f" ] && continue
  red "  FAIL $f is in the [77] file set but is missing or empty, every ban over it would report 0 hits and measure nothing"
  FAILED=$((FAILED + 1))
  RR_BAD=$((RR_BAD + 1))
done
if [ "$RR_PARSED" -lt 4 ]; then
  red "  FAIL only $RR_PARSED path(s) parsed from the [77] file set, expected at least 4 (a mangled list must redden here, not iterate zero times)"
  FAILED=$((FAILED + 1))
elif [ "$RR_BAD" -eq 0 ]; then
  green "  ok   all $RR_PARSED files in the [77] set exist and are non-empty"
fi

for f in $RR_FILES; do
  # A path that failed the gate above is skipped, never banned over.
  [ -s "$f" ] || continue
  # Relevance pin, not a matcher control: this file still talks about reviewers.
  check_token_present 'reviewer' "$f"
  # Panel width written as a range. Wrong at every spelling, because the gate
  # makes the floor 1 and a range denies it.
  for t in '4-to-5' '4 to 5' 'four-to-five' 'four to five' '5-to-6' '5 to 6' 'five-to-six' 'five to six'; do
    check_no_token "$t" "$f"
  done
  for t in '4-5 reviewers' '5-6 reviewers' '4 or 5 reviewers' '5 or 6 reviewers'; do
    check_no_token "$t" "$f"
  done
  # The same claim in adjectival form, "the 5-to-6 reviewer panel" was one of
  # the three sites fixed this sprint.
  for t in '4-reviewer' '5-reviewer' '6-reviewer' 'four-reviewer' 'five-reviewer' 'six-reviewer'; do
    check_no_token "$t" "$f"
  done
  # Dispatch counts. "4-to-5 parallel reviewers" was the yolo defect, these are
  # the grammars a rewrite of it would land on.
  for t in '2 parallel reviewers' '3 parallel reviewers' '4 parallel reviewers' '5 parallel reviewers' '6 parallel reviewers'; do
    check_no_token "$t" "$f"
  done
  for t in 'two parallel reviewers' 'three parallel reviewers' 'four parallel reviewers' 'five parallel reviewers' 'six parallel reviewers'; do
    check_no_token "$t" "$f"
  done
  # Panel identity. "The panel is five now" was the review-scope defect.
  for t in 'panel is 4' 'panel is 5' 'panel is 6' 'panel is four' 'panel is five' 'panel is six'; do
    check_no_token "$t" "$f"
  done
  for t in 'panel is now four' 'panel is now five' 'panel is now six' 'panel of four' 'panel of five' 'panel of six'; do
    check_no_token "$t" "$f"
  done
  # Claims that deny the gate outright.
  for t in 'all four reviewers' 'all five reviewers' 'all six reviewers' 'reviewers always run'; do
    check_no_token "$t" "$f"
  done
  # Phase 2.5 dispatches exactly one spec reviewer, so any count is drift.
  for t in '2 spec reviewers' '3 spec reviewers' 'two spec reviewers' 'three spec reviewers' 'both spec reviewers' 'spec reviewers in parallel'; do
    check_no_token "$t" "$f"
  done
done
