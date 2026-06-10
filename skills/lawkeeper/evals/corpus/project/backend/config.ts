// Corpus fixture: deterministic-tier bans in non-scoped infrastructure code.
// Each violation carries a trailing EXPECT-marker naming the rule_id it must
// trigger (bare rule_id only — never the banned token, so a marker cannot trip
// the scanner). run_corpus.py turns these markers into the oracle.
export const region = 'us-east-1'

const apiKey = 'AKIA1234567890ABCDEF' // EXPECT: sec.hardcoded-secret
const token = 'PUBLIC_PLACEHOLDER' // EXPECT-CLEAN: env-name shape, not a credential literal

// eslint-disable-next-line  // EXPECT: ban.suppression
export function loadConfig(raw) {
  try {
    return JSON.parse(raw)
  } catch (e) {} // EXPECT: ban.empty-catch
}

export function mustGet(map, key) {
  const value = map.get(key)! // EXPECT: ban.non-null
  return value
}

export function fail() {
  throw new Error('config missing') // EXPECT: ban.bare-error
}
