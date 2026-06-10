// Corpus fixture: more judgment-tier violations across new concerns.
// Deterministically CLEAN — no banned tokens. Function names are NEUTRAL (they
// don't name the violation); the violation lives in the body, so the blind copy
// the semantic runner scans doesn't leak the answer.

// One query per id inside a loop (classic N+1).
export function fetchTotals(db, orderIds) {
  const totals = []
  for (const id of orderIds) {
    totals.push(db.queryOne('orderTotal', id)) // EXPECT-SEMANTIC: perf.n-plus-1
  }
  return totals
}

// One unit doing four jobs: validate, compute tax, persist, and send a receipt.
export function processOrder(db, mailer, order) { // EXPECT-SEMANTIC: style.srp
  if (order.amount < 0) {
    return null
  }
  const taxed = { ...order, total: order.amount * 1.1 } // EXPECT-SEMANTIC: style.magic-literal
  db.insert('orders', taxed)
  return mailer.send(order.email, 'receipt')
}

// Chained ternary that should be a lookup or if/else ladder.
export function tier(score) {
  return score > 90 ? 'A' : score > 80 ? 'B' : score > 70 ? 'C' : 'F' // EXPECT-SEMANTIC: style.ternary
}
