# shellcheck shell=bash

# [27] Marketplace channel pins are consistent with plugin.json.
#
# WHY THIS EXISTS: v0.8.0 shipped with marketplace.json `version` bumped to
# 0.8.0 but the stable channel's `source.ref` left at "v0.7.1". The version
# field is display metadata; `ref` is what Claude Code actually fetches. The
# result was a released plugin that clients reported as "already at the latest
# version (0.7.1)", the new release was invisible, with every file correct and
# every other check green. A one-line miss with a silent, total failure mode.
#
# Rules enforced:
#   a) the stable `hackify` channel's ref MUST equal "v<plugin.json version>"
#   b) the `hackify-edge` channel's ref MUST stay "main" (it tracks the branch)
#   c) every channel's `version` MUST equal plugin.json's version
#   d) every version already released BELOW the in-flight one MUST resolve to a
#      real git tag, because (a) only compares two strings and never asks
#      whether the thing they name exists

yellow "[27] marketplace channel pins match plugin.json (stable ref, edge ref, versions)"

if ! command -v jq > /dev/null 2>&1; then
  red "  FAIL jq not available, cannot verify marketplace pins"
  FAILED=$((FAILED + 1))
  return 0 2>/dev/null || true
fi

PLUGIN_VERSION="$(jq -r '.version' .claude-plugin/plugin.json 2>/dev/null)"
if [ -z "$PLUGIN_VERSION" ] || [ "$PLUGIN_VERSION" = "null" ]; then
  red "  FAIL cannot read .version from .claude-plugin/plugin.json"
  FAILED=$((FAILED + 1))
  return 0 2>/dev/null || true
fi

EXPECTED_STABLE_REF="v${PLUGIN_VERSION}"

STABLE_REF="$(jq -r '.plugins[] | select(.name == "hackify") | .source.ref' .claude-plugin/marketplace.json 2>/dev/null)"
if [ "$STABLE_REF" = "$EXPECTED_STABLE_REF" ]; then
  green "  ok   stable channel ref is $STABLE_REF (matches plugin.json $PLUGIN_VERSION)"
else
  red "  FAIL stable channel ref is '$STABLE_REF'; expected '$EXPECTED_STABLE_REF'"
  red "       clients would silently install the OLD tag and report it as latest"
  FAILED=$((FAILED + 1))
fi

EDGE_REF="$(jq -r '.plugins[] | select(.name == "hackify-edge") | .source.ref' .claude-plugin/marketplace.json 2>/dev/null)"
if [ "$EDGE_REF" = "main" ]; then
  green "  ok   edge channel ref is main (tracks the branch by design)"
else
  red "  FAIL edge channel ref is '$EDGE_REF'; expected 'main'"
  FAILED=$((FAILED + 1))
fi

mismatched=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  ch_name="${line%%|*}"
  ch_version="${line##*|}"
  if [ "$ch_version" != "$PLUGIN_VERSION" ]; then
    red "  FAIL channel '$ch_name' version is '$ch_version'; expected '$PLUGIN_VERSION'"
    FAILED=$((FAILED + 1))
    mismatched=$((mismatched + 1))
  fi
done < <(jq -r '.plugins[] | "\(.name)|\(.version)"' .claude-plugin/marketplace.json 2>/dev/null)

if [ "$mismatched" -eq 0 ]; then
  green "  ok   every channel version equals plugin.json ($PLUGIN_VERSION)"
fi

# --- [27d] tags that were never cut ------------------------------------------
#
# WHY THIS EXISTS: rule (a) above asserts the stable pin EQUALS "v<version>". It
# has never asked whether the thing that string names exists, and twice now it
# did not. 0.3.1 (release commit 91c2d72) and 0.14.0 (release commit 5a84a7a)
# both shipped with the manifest pinned at a tag nobody ever cut. Rule (a) was
# green for the whole of both releases and the stable channel was installable at
# neither. That is this check's own header describing the exact failure class it
# was written to catch, from the one angle it could not see.
#
# WHY IT IS NOT "THE PIN MUST RESOLVE": scripts/release.sh builds the tag from
# plugin.json and cuts it AFTER the release commit lands, so on a correct
# pre-release commit the pin leads the tag by design. A bare "must resolve"
# assertion would redden on every one of those commits and get deleted inside a
# week. It would also be vacuous: rule (a) already forces the pin to equal the
# in-flight version, so "resolves OR is in flight" is satisfied by (a) alone and
# measures nothing. So the in-flight version and anything sorting above it is
# exempt, everything BELOW it must be tagged, and a skipped tag is caught at the
# next version bump rather than never. That bump is the earliest moment the two
# cases are distinguishable at all.
#
# NOTE FOR THE NEXT RELEASE: 0.14.1 is exempt only while it is in flight.
# Bumping plugin.json to 0.14.2 drops it out of the window, and if v0.14.1 still
# has not been cut this check goes red on it. That is the check working, not the
# check breaking. Cut v0.14.1 at its release commit before bumping.

# Releases that went out untagged BEFORE this check existed. A ratchet, not a
# suppression: MRP_KNOWN_UNTAGGED_EXPECTED below is this list's own length
# written out a second time by hand, so appending a version to silence a
# genuinely untagged release cannot land without also editing that number, which
# is the line a reviewer actually reads. Deleting an entry while its tag is still
# missing turns this check red rather than quiet. Backfilling either tag is a
# one-line git command, which is why they are recorded here instead of being
# scoped away. The paragraph above names the release commit each one belongs at.
MRP_KNOWN_UNTAGGED="0.3.1
0.14.0"

MRP_NL='
'

yellow "[27d] every released version below the in-flight one resolves to a real git tag"

# The list's LENGTH, written a SECOND time. Why a hand-written number beats a
# bound derived from the list is argued above check_list_size in 00-helpers.sh.
# Note that this is equality, so it reddens on an addition as well as a deletion;
# it does not by itself make the list shrink-only, it makes either direction cost
# a visible edit here. Pinned OUTSIDE the MRP_VERIFIABLE block below on purpose:
# a pin that runs only once the tag read succeeded would stop guarding at exactly
# the moment the check degrades, which is the fail-open shape [27d] exists to
# catch. It still sits below the two early returns at the top of this fragment
# (no jq, unreadable plugin.json), which take [27] out entirely; those are the
# limit of this pin's reach, not something it covers.
MRP_KNOWN_UNTAGGED_EXPECTED=2
mrp_known_total=0
while IFS= read -r mrp_entry; do
  [ -n "$mrp_entry" ] || continue
  mrp_known_total=$((mrp_known_total + 1))
done <<< "$MRP_KNOWN_UNTAGGED"
check_list_size "$mrp_known_total" "$MRP_KNOWN_UNTAGGED_EXPECTED" "the [27d] MRP_KNOWN_UNTAGGED list"

MRP_CHANGELOG_VERSIONS="$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md 2>/dev/null | tr -d '#[] ')"
if MRP_TAGS="$(git tag --list 'v*' 2>/dev/null)"; then MRP_TAG_RC=0; else MRP_TAG_RC=1; fi
MRP_SHALLOW="$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)"

# Everything below this point can only run on real inputs. Each guard says in
# writing why it could not measure, because the one outcome this check must
# never produce is a green line standing in for a comparison that never ran.
MRP_VERIFIABLE=1
if [ -z "$MRP_CHANGELOG_VERSIONS" ]; then
  red "  FAIL no '## [x.y.z]' heading parsed out of CHANGELOG.md, so [27d] would have measured nothing"
  FAILED=$((FAILED + 1))
  MRP_VERIFIABLE=0
elif [ "$MRP_TAG_RC" -ne 0 ]; then
  red "  FAIL 'git tag --list' exited non-zero, so no release tag was verified; a tag read that errors must never stand in for 'no tag is missing'"
  FAILED=$((FAILED + 1))
  MRP_VERIFIABLE=0
elif [ -z "$MRP_TAGS" ]; then
  MRP_VERIFIABLE=0
  if [ "$MRP_SHALLOW" = "true" ]; then
    yellow "  skip shallow checkout carrying no tags, [27d] cannot run here; this is a local-clone branch now, CI checks out with 'fetch-depth: 0' AND 'fetch-tags: true', the only pair that lands tags"
  else
    red "  FAIL a full clone reports zero 'v*' tags, and this repo has released dozens, so the tag list is unreadable rather than genuinely empty"
    FAILED=$((FAILED + 1))
  fi
fi

if [ "$MRP_VERIFIABLE" -eq 1 ]; then
  mrp_resolved=0
  mrp_missing=0
  mrp_known=""
  mrp_known_n=0
  mrp_stale=""
  # One `sort -V` over the CHANGELOG versions with the in-flight version spliced
  # in, then read until the in-flight version turns up. Everything consumed
  # before that point sorts strictly below it and is therefore a release whose
  # tag is already due; everything at or after it is the legitimate window. The
  # tag lookup is set membership against one enumeration, not one `git rev-parse`
  # per version, because 46 spawned processes is the cost this validator spent
  # 0.14.1 removing.
  while IFS= read -r mrp_v; do
    [ -n "$mrp_v" ] || continue
    [ "$mrp_v" = "$PLUGIN_VERSION" ] && break
    case "$MRP_NL$MRP_TAGS$MRP_NL" in
      *"${MRP_NL}v${mrp_v}${MRP_NL}"*) mrp_resolved=$((mrp_resolved + 1)); continue ;;
    esac
    case "$MRP_NL$MRP_KNOWN_UNTAGGED$MRP_NL" in
      *"${MRP_NL}${mrp_v}${MRP_NL}"*) mrp_known="$mrp_known $mrp_v"; mrp_known_n=$((mrp_known_n + 1)); continue ;;
    esac
    red "  FAIL $mrp_v is a released CHANGELOG entry but tag v$mrp_v does not exist, so the stable channel was never installable at that release"
    FAILED=$((FAILED + 1))
    mrp_missing=$((mrp_missing + 1))
  done < <(printf '%s\n%s\n' "$MRP_CHANGELOG_VERSIONS" "$PLUGIN_VERSION" | sort -V)

  # Both numbers are counted above, never written down here. "all $mrp_resolved"
  # was a false total: mrp_resolved counts only the versions that DID resolve,
  # while mrp_known holds the ones knowingly recorded as never cut, so "all"
  # named the resolvers and silently dropped every recorded hole from the
  # denominator. A count that excludes the exceptions is the shape this
  # fragment's own header forbids.
  # All three buckets, not the two that happen to be non-zero on the branch that
  # prints. A version below the in-flight one resolved, was recorded as a known
  # hole, or is missing; a denominator that drops one of those is the same defect
  # this line exists to remove.
  mrp_below=$((mrp_resolved + mrp_known_n + mrp_missing))
  if [ "$mrp_missing" -eq 0 ]; then
    green "  ok   $mrp_resolved of $mrp_below released version(s) below in-flight $PLUGIN_VERSION resolve to a real git tag ($mrp_known_n recorded as never cut)"
  else
    red "       backfill with 'git tag -a v<version> <release commit>', or add the bare version to MRP_KNOWN_UNTAGGED, bump MRP_KNOWN_UNTAGGED_EXPECTED to match, and name its release commit in the comment above that list"
  fi

  # A recorded hole that has since been tagged takes the resolved branch above
  # and never reaches mrp_known, so the list would quietly outlive its reason.
  while IFS= read -r mrp_k; do
    [ -n "$mrp_k" ] || continue
    case "$MRP_NL$MRP_TAGS$MRP_NL" in
      *"${MRP_NL}v${mrp_k}${MRP_NL}"*) mrp_stale="$mrp_stale $mrp_k" ;;
    esac
  done <<< "$MRP_KNOWN_UNTAGGED"

  if [ -n "$mrp_known" ]; then
    yellow "  note never cut, recorded as predating this check:$mrp_known (stable channel is not installable at those versions)"
  fi
  if [ -n "$mrp_stale" ]; then
    yellow "  note MRP_KNOWN_UNTAGGED still lists$mrp_stale after the tag was cut, prune the entry and drop MRP_KNOWN_UNTAGGED_EXPECTED to match so the list keeps shrinking"
  fi
  yellow "  note in-flight $PLUGIN_VERSION and anything above it is exempt, scripts/release.sh cuts that tag after the release commit lands"
fi
