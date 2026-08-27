# Performance Guardrails (Always-On)

Injected into every prompt by hackify's `UserPromptSubmit` hook, beside the hard caps and the expert mindset. The caps set **what not to write**, the mindset sets **how to think**, this sets **what must never ship slow**. Project-agnostic; hot paths get zero tolerance.

**Canonical source: `rules/performance.md`**, the deep catalog with stable `perf.<domain>.<slug>` IDs, the severity model, and one table per domain. Do not restate the catalog here; this stub is distilled FROM it. Direction note: this pair is the INVERSE of the caps pair, there, the always-on `hard-caps.md` is canonical and `code-quality.md` is deep doctrine; here, the deep file is canonical and this always-on stub is the distillation.

## The twelve guardrails

1. **Never query or call per loop item.** No DB query, HTTP call, or ORM lazy-relation access inside a loop, batch it (JOIN, `IN (...)`, bulk endpoint, dataloader).
2. **Parallelize independent I/O.** Sequential awaits on independent calls pay the sum of latencies instead of the max. Run them together, bounded.
3. **Bound every result set.** Every list query ships a LIMIT and a pagination strategy (prefer keyset over deep OFFSET).
4. **Bound every cache.** TTL or LRU cap on every cache and memo, a cache without eviction is a memory leak.
5. **Bound every fan-out.** No `Promise.all` (or gather) over a data-sized list, use a concurrency pool or chunks.
6. **No sync blocking I/O on servers.** No sync fs, sync crypto, or MB-scale sync parse on an event loop or request path.
7. **Filter on indexes.** Every hot WHERE/JOIN/ORDER BY column is index-backed; no function wrapped around an indexed column; no leading-wildcard LIKE on big tables.
8. **No O(n²) on unbounded input.** Build a Map/Set index instead of nested scans; hoist loop-invariant work out of the loop.
9. **Batch bulk writes.** One bulk statement instead of n single-row writes, and buffer small file/socket writes instead of flushing per item.
10. **Stream large payloads.** Read, transform, and respond in streams; never buffer whole large files or responses in memory.
11. **Stable props and keys in UI hot paths.** No inline object/array/lambda props to memoized children; no index-as-key on mutable lists; virtualize long lists.
12. **Measure before optimizing.** Profile or EXPLAIN first; cheapest-correct beats clever-slow; no speculative micro-optimization that costs clarity.

## Enforcement

The deterministic perf-scout (`skills/hackify/references/perf-scout.md`) greps for these at both Phase 3 run points, the wave agent over its own file allowlist before it returns and the parent at round-end over what that round's waves declared, and again at Phase 5 start, and Reviewer D (performance) judges every staged candidate against the catalog, quick runs the same checks at its mirror points.
