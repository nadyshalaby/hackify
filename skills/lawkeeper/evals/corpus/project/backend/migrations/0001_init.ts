// Corpus fixture: a migration file. is_generated() exempts */migrations/* from
// EVERY rule, so the scanner skips this file entirely — the violation below is
// a CLEAN trap for the generated-file carve-out (it must NOT be reported).
export function up() {
  throw new Error('not idempotent') // EXPECT-CLEAN: migration is generated-exempt
}
