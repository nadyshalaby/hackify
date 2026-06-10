// Corpus fixture: a repository (infrastructure) is NOT a scoped module, so an
// inline interface here is allowed — the inline-type ban scopes to
// service/controller/routes/middleware/guard files. CLEAN asserts no finding.
interface QueryOpts { limit: number; offset: number } // EXPECT-CLEAN: ban.inline-type not scoped here

export function buildRange(opts) {
  return [opts.offset, opts.offset + opts.limit]
}
