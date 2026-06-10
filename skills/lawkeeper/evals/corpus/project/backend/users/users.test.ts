// Corpus fixture: test-file carve-out traps. The constructs below fire in
// production code but are deliberately waived inside test files; CLEAN markers
// assert the scanner stays silent (a precision measurement). The empty-catch
// case pins the one ban that is NOT test-waived.
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
