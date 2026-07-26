# shellcheck shell=bash

# [27] Marketplace channel pins are consistent with plugin.json.
#
# WHY THIS EXISTS: v0.8.0 shipped with marketplace.json `version` bumped to
# 0.8.0 but the stable channel's `source.ref` left at "v0.7.1". The version
# field is display metadata; `ref` is what Claude Code actually fetches. The
# result was a released plugin that clients reported as "already at the latest
# version (0.7.1)" — the new release was invisible, with every file correct and
# every other check green. A one-line miss with a silent, total failure mode.
#
# Rules enforced:
#   a) the stable `hackify` channel's ref MUST equal "v<plugin.json version>"
#   b) the `hackify-edge` channel's ref MUST stay "main" (it tracks the branch)
#   c) every channel's `version` MUST equal plugin.json's version

yellow "[27] marketplace channel pins match plugin.json (stable ref, edge ref, versions)"

if ! command -v jq > /dev/null 2>&1; then
  red "  FAIL jq not available — cannot verify marketplace pins"
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
