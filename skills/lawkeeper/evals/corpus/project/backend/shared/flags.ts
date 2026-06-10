// Corpus fixture: a feature flag defined but read nowhere. newCheckout is the
// contrast control — billing.service.ts reads it — so the dead flag is
// localizable even in a tiny synthetic tree (auditTrail has zero readers).
export const flags = {
  newCheckout: true,
  auditTrail: false, // EXPECT-SEMANTIC: clean.dead-flag
}
