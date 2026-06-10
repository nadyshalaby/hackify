// Corpus fixture: test-file carve-out traps. The constructs below fire in
// production code but are deliberately waived inside test files; CLEAN markers
// assert the scanner stays silent (a precision measurement). The empty-catch
// case pins the one ban that is NOT test-waived.
import { pageBounds } from './users.service'

export function brokenButWaived(input) {
  const value = input! // EXPECT-CLEAN: ban.non-null waived in tests
  if (!value) {
    throw new Error('test setup') // EXPECT-CLEAN: ban.bare-error waived in tests
  }
  try {
    return value.parse()
  } catch (e) {} // EXPECT: ban.empty-catch
  return null
}

// @ts-expect-error invalid input under test // EXPECT-CLEAN: suppression waived in tests
export const bad = brokenButWaived(undefined)

// Happy-path-only coverage of pageBounds: never exercises the size>100 clamp,
// page 0, or negative inputs — the edge cases the principles demand. Also the
// contrast control making billing.service.ts the one service with NO test.
// The test.edge-cases oracle marker lives on pageBounds itself
// (users.service.ts) — the rule's subject is the under-tested BEHAVIOR, and
// the pass consistently attributes the finding to the source file.
export function checksPageBounds() {
  const bounds = pageBounds(2, 10)
  return bounds.limit === 10 && bounds.offset === 20
}
