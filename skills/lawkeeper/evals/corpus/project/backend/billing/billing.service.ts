// Corpus fixture: testing + magic-literal judgment violations. Deterministically
// CLEAN — no banned tokens, no inline types (this IS a *.service.ts, so the scope
// ban applies; none planted here). Branching logic with NO test anywhere in the
// corpus (contrast: users.service.pageBounds IS exercised by users.test.ts), and
// un-named rate/threshold literals that should be module constants.
import { flags } from '../shared/flags'

export function invoiceTotal(order) { // EXPECT-SEMANTIC: test.untested
  const taxed = order.amount + order.amount * 0.0825 // EXPECT-SEMANTIC: style.magic-literal
  if (!flags.newCheckout) {
    return taxed
  }
  if (taxed > 10000) {
    return taxed - taxed * 0.02
  }
  return taxed
}
