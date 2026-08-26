# Perf-scout (deterministic performance candidate finder)

A predictable, grep-based scan that surfaces performance-violation **candidates** keyed to the stable IDs in [rules/performance.md](../../../rules/performance.md) (the canonical catalog). Run at fixed points in the workflow, by the wave agent over its own file allowlist and by the parent over the wider scopes; its output feeds the Phase 5 address-all decision table and Reviewer D (performance).

## WHAT

- **Deterministic candidate finder.** Same files in, same candidates out, plain `grep`/`awk`, no compiler, no AST, no new dependency. It maps to the shell primitive on every runtime tier.
- **Candidates, not verdicts.** A match means "look here", never "guilty". Judgment lives in the TRIAGE rules below and with Reviewer D.
- **Keyed to catalog IDs.** Every pattern cites a `perf.<domain>.<slug>` ID from `rules/performance.md`, so staging, default severity, and deduplication stay stable across runs. A pattern with no catalog ID is invalid, extend the catalog first.
- **Cheap by design.** Seconds per run, run it at every mandated point without hesitation.

## WHEN

| Run point | Scope | What happens with findings |
|---|---|---|
| **Phase 3, the AGENT, before it returns** | That wave's OWN file allowlist, the files it landed | Trivial in-allowlist candidates are fixed in place (mark `fixed`); everything else is `staged` in the wave report |
| **Phase 3, the PARENT, every round-end** | The round-touched files (what the round's waves DECLARED under `## Paths written`, never the allowlist union), before tasks tick | Each wave's dispositions carry forward unchanged; what the wider scope newly shows is `staged` for Phase 5, or sent back out as a one-task wave. The parent never writes the fix |
| **Phase 5, start** | The whole sprint diff (`git diff --name-only <base>..HEAD -- . ':(exclude)docs/work/*'`) | Staging table handed to Reviewer D as input; `staged` rows join the address-all decision table |
| **quick (5-lite mirror)** | Touched files, before the single-lens review | Findings resolved in the same pass, the quick lens includes performance |
| **yolo (mirror)** | Same three points as full hackify, both Phase 3 run points and Phase 5 start | Findings enter yolo's address-all loop, auto-fixed at every severity |

**Why the Phase 3 run point is BOTH the wave and the round.** The two scans answer questions the other cannot, so neither replaces it. The AGENT scan is keyed to the wave because that is the only moment fix-in-wave is possible at all: the agent is still holding its files, they sit inside its own allowlist, and a trivial fix lands in the same diff. The PARENT scan is keyed to the round because tasks tick at round end and the parent runs its repo-wide checks once per round, so a parent scan keyed to wave-end would run before the thing it is meant to gate. Where a round holds two or more waves it also reaches what no agent scan can: the round's declared set is the only scope in which a defect crossing two waves is visible, because no agent can scan a file it never held. **On a single-wave round that scope reason is void**, the round's declared set IS what that one wave declared, and the mandate still holds because two questions survive the collapse. First, whether the agent ran its scan at all: the wave report is a claim, and the parent's own scan is what checks it. Second, whether a fix-in-wave regressed the file after the agent's scan had already passed: a fix-in-wave edit lands AFTER the scan that surfaced the candidate, and nothing at the agent's run point re-reads the file once it has been edited, so the agent's green grades the pre-fix state and the parent's scan is the first read of the post-fix one. Canonical statement of both run points and the loop they sit in: [phases/phase-3-implement.md](phases/phase-3-implement.md).

## HOW

Ground rules for every pattern:

- **POSIX ERE, macOS/BSD-safe.** No `\b`, no `\s`, no `\d`, use `[[:space:]]`, `[0-9]`, explicit classes. Run with `grep -E -n` or `rg -n`.
- **SQL-ish patterns run case-insensitive** (`grep -i -E`), marked per table.
- **Loop-window patterns** need loop context. Use the two-step helper: find loop headers, then search a 6-line window.
- **Scope is the diff**, never the whole user repo (lawkeeper owns full-codebase sweeps).

```bash
# loop_window <file> <token-ERE>, grep a token inside loop bodies (6-line window).
loop_window() {
  grep -n -E -A 6 'for[[:space:]]*\(|while[[:space:]]*\(|for[[:space:]]+[A-Za-z_].*[[:space:]]in[[:space:]]|\.forEach\(|\.map\(' "$1" \
    | grep -E "$2"
}

# consecutive awaits, perf.network.sequential-awaits candidates (confirm independence).
awk 'index($0,"await "){ if (prev) printf "%s:%d: %s\n", FILENAME, FNR, $0; prev=1; next } { prev=0 }' "$file"
```

### JS/TS (whole-file patterns)

| Pattern (ERE) | Catalog ID | Notes / false-positive guard |
|---|---|---|
| `JSON\.parse\(JSON\.stringify\(` | perf.memory.json-deep-clone | The call is the finding. Fix: `structuredClone` or clone the mutated slice. |
| `\.forEach\([[:space:]]*async` | perf.async.await-in-loop | forEach never awaits its callback, also a perf.async.fire-and-forget candidate. |
| `Promise\.all\([[:space:]]*[A-Za-z_$][A-Za-z0-9_$.]*\.map\(` | perf.async.unbounded-fanout | Fine when the list is constant-size; flag data-sized lists. Same for `Promise\.allSettled\(`, run both. |
| `[A-Za-z]+Sync\(` | perf.async.sync-blocking | Also perf.io.sync-fs. CLI scripts, startup, and tests are fine, flag request/handler paths. |
| `new[[:space:]]+Map\(` | perf.memory.unbounded-cache | Candidate when module-scope AND written from handlers with no `.delete`/`.clear`/TTL. Run `new[[:space:]]+Set\(` too. |
| `=\{\{` | perf.frontend.unstable-props | JSX inline object prop. Cheap on plain DOM leaves; matters for memoized children and hot lists. |
| `=\{\[` | perf.frontend.unstable-props | JSX inline array prop, same guard as above. |
| `=\{\([[:space:]A-Za-z_$,]*\)[[:space:]]*=>` | perf.frontend.unstable-props | JSX inline lambda prop, same guard as above. |
| `key=\{index\}` | perf.frontend.index-key | Variants: `key=\{i\}`, `key=\{idx\}`. Confirm the identifier is the map index, not an entity id. |
| `addEventListener\(` | perf.memory.leaked-listeners | Confirm a paired `removeEventListener` in cleanup. scroll/resize/mousemove/input handlers doing real work → perf.frontend.unthrottled-handlers. |
| `setInterval\(` | perf.memory.leaked-listeners | Confirm a paired `clearInterval`. Polling an endpoint on interval → perf.network.polling-vs-push. |
| `\.subscribe\(` | perf.memory.leaked-listeners | Store the subscription and dispose it on teardown. |
| `from[[:space:]]+['"]lodash['"]` | perf.bundle.whole-library-import | Whole-lib default/namespace import. Repeat the pattern for other heavy libs (moment, rxjs, date-fns). Per-module paths are the fix. |
| `JSON\.stringify` | perf.obs.eager-log-serialization | Flag when inside log-call arguments (runs even when the level is off). MB-scale graphs per request → perf.io.sync-serialize-large. |
| `\.\.\.acc` | perf.algorithmic.spread-accumulator | Accumulator spread inside reduce/loop. Variants: `\.\.\.prev`, `\.\.\.result`, `\.\.\.out`. |
| `OFFSET[[:space:]]+` (with `-i`) | perf.data.deep-offset | Also `\.offset\(` and `skip[[:space:]]*:` in ORM query builders. Fixed small offsets are fine; parametric page math is not. |

### JS/TS, loop-window patterns (run through `loop_window`)

| Pattern (ERE) | Catalog ID | Notes / false-positive guard |
|---|---|---|
| `await[[:space:]]` | perf.async.await-in-loop | Dependent iterations (each needs the previous result) are legitimately serial. |
| `\.find[A-Za-z]*\(` | perf.data.n-plus-one | ORM/repository receiver → n-plus-one. Array receiver → perf.algorithmic.scan-in-loop instead. |
| `\.query\(` | perf.data.n-plus-one | Reads per item. Batch with JOIN / `IN (...)` / dataloader. |
| `\.save\(` | perf.data.per-item-write | Also `\.create\(`, `\.insert[A-Za-z]*\(`, `\.update[A-Za-z]*\(`, bulk APIs are the fix. |
| `fetch\(` | perf.network.chatty-calls | Any HTTP client call in a loop maps the same (axios/got/request). Retry wrappers are not chatty-calls. |
| `\.includes\(` | perf.algorithmic.scan-in-loop | Bounded constant lists are fine; data-sized collections need a Set/Map. Run `\.indexOf\(` too. |
| `\.sort\(` | perf.algorithmic.sort-in-loop | Sort once before the loop. |
| `\.u?n?shift\(` | perf.algorithmic.shift-in-loop | Matches `.shift(` and `.unshift(`. Tiny bounded queues are fine; hot loops are not. |
| `\+=[[:space:]]*['"]` | perf.algorithmic.string-concat-loop | Also flag `+=` where the LHS accumulates strings (template literals included). Numeric accumulators are fine. |
| `new[[:space:]]+RegExp\(` | perf.algorithmic.regex-in-loop | A pattern that genuinely changes per item is legitimate, hoist only invariant ones. |
| `console\.` | perf.obs.log-in-hot-loop | Logger calls (`logger.info/debug`) count too. Tooling loops over a handful of items are usually fine, hot data loops are not. |

### Python

| Pattern (ERE) | Catalog ID | Notes / false-positive guard |
|---|---|---|
| `json\.loads\(json\.dumps\(` | perf.memory.json-deep-clone | Use `copy.deepcopy`, or build the new shape directly. |
| `\.objects\.` (loop-window) | perf.data.n-plus-one | Django ORM per item, `select_related`/`prefetch_related`/`in_bulk`. Lazy FK attribute access in loops counts too. |
| `session\.` (loop-window) | perf.data.n-plus-one | SQLAlchemy per-item query/get, batch with `in_()`. |
| `cursor\.execute\(` (loop-window) | perf.data.per-item-write | `executemany` / bulk insert is the fix. |
| `time\.sleep\(` | perf.async.sleep-poll | Candidate when inside a `while` condition-wait. Backoff inside a retry helper is legitimate. |
| `requests\.` | perf.async.sync-blocking | Candidate when inside `async def`, use an async client (httpx/aiohttp). Sync scripts are fine. |
| `\+=[[:space:]]*f?['"]` (loop-window) | perf.algorithmic.string-concat-loop | `''.join(parts)` is the fix. |
| `re\.compile\(` (loop-window) | perf.algorithmic.regex-in-loop | Note: bare `re.match/search` auto-caches up to 512 patterns, weak candidate; still hoist hot ones. |
| `lru_cache\(maxsize=None\)` | perf.caching.unbounded-memo-args | Also `@(functools\.)?cache`. Bounded arg spaces (enums) are fine; user-derived args are not. |
| `\.read\(\)` | perf.io.whole-file-read | Small config files are fine; uploads/exports/logs iterate chunks or lines. |
| `pd\.concat\(` (loop-window) | perf.memory.buffer-concat-loop | Collect frames in a list, concat once. DataFrame `.append` in loops maps the same. |
| `[[:space:]]in[[:space:]]+\[` (loop-window) | perf.algorithmic.scan-in-loop | Membership against a literal list per iteration, use a set. `x in some_list` variants need type knowledge (semantic). |
| `global[[:space:]]+[a-z_]` | perf.memory.global-accumulator | Candidate when mutated inside request handlers; bounded module registries are fine. |

### Shell / subprocess (loop-window)

Added after a Phase 5 round found this repo spending roughly 15% of its own pre-commit gate here with
no catalog ID to file it under. The scout's ground rule is that every pattern cites a real ID, and for
two rounds this family had none, so findings were filed under an ID that did not exist.

| Pattern (ERE) | Catalog ID | Notes / false-positive guard |
|---|---|---|
| `\$\((wc|basename|dirname|stat|date|cut|sed|awk)[[:space:]]` (loop-window) | perf.process.spawn-per-item | One fork per item where one invocation covers the set. `wc -l` per file becomes one `xargs wc -l`; `basename` per file becomes a parameter expansion. Bounded constant lists are fine, and a single spawn outside the loop is the fix, not the finding. |
| `echo[[:space:]]+"\$[A-Za-z_]+"[[:space:]]*\|[[:space:]]*grep` (loop-window) | perf.process.spawn-per-item | A grep per token over the same held text. Batch the tokens into one `grep -f`, then fall back to the per-token loop only for inputs that screen dirty, so no diagnostic detail is lost. |

### SQL (run with `grep -i -E`)

| Pattern (ERE) | Catalog ID | Notes / false-positive guard |
|---|---|---|
| `SELECT[[:space:]]+\*` | perf.data.select-star | Migration/introspection scripts excluded; hot queries name their columns. |
| `LIKE[[:space:]]+'%` | perf.data.leading-wildcard | Leading wildcard defeats btree indexes. Trailing-only wildcards (`'x%'`) are fine. |
| `COUNT\(\*\)` | perf.data.count-for-exists | Finding only when the caller tests `> 0` / truthiness, real count displays are legitimate. |
| `OFFSET[[:space:]]+[0-9$:?]` | perf.data.deep-offset | Parametric or deep offsets → keyset. Fixed first-page offsets are fine. |
| `WHERE[[:space:]]+[A-Z_]+\(` | perf.data.missing-index | A function wrapped around a column in WHERE is non-sargable, functional index or rewrite. |
| `LIMIT` (inverted: `grep -L -i`) | perf.data.unbounded-result | Query files containing SELECT but no LIMIT. Aggregates and unique-key lookups are fine. |

### Semantic-only candidates (no reliable grep)

These catalog entries need reading, not pattern-matching, the scout lists them for Reviewer D's checklist instead: perf.data.missing-index (needs EXPLAIN), perf.network.sequential-awaits (independence, the awk helper only finds adjacency), perf.network.no-timeout, perf.caching.no-invalidation, perf.caching.stampede, perf.network.duplicate-inflight, perf.frontend.missing-virtualization, perf.memory.retained-payload.

### Stack extension (other languages)

For Go, Rust, Java, Ruby, PHP, and anything else: derive tokens from the **Detect (hint)** column of the catalog, e.g. Go `db.Query` inside `for` → perf.data.n-plus-one; Ruby `Model.find` inside `.each` → the same ID. Keep patterns POSIX-ERE and `[[:space:]]`-safe, and every new pattern MUST cite an ID that already exists in `rules/performance.md`, no ID, no pattern.

## STAGING

Stage findings in exactly this table (the AGENT appends it to its own wave report under `## Scout dispositions`, the parent transcribes those rows into the wave log and appends the round-end table beside them, and at review start it goes in the Phase 5 review section):

```markdown
### Perf-scout (<run-point-id>, <YYYY-MM-DD>)

| Finding | Catalog ID | file:line | Evidence | Proposed fix | Status |
|---|---|---|---|---|---|
| Query per task in export loop | perf.data.n-plus-one | src/export/service.ts:88 | `await repo.findOne(t.id)` inside `for (const t of tasks)` | one `findMany` with `id IN (...)` before the loop | staged |
| Sync read in request handler | perf.io.sync-fs | src/routes/report.ts:14 | `readFileSync(tplPath)` per request | async read once at startup, reuse | fixed |
| `.includes` in tag loop | perf.algorithmic.scan-in-loop | src/tags.ts:31 | scanned list is 5 static items |, | false-positive: bounded constant list |
```

- **`<run-point-id>`** names the run point that produced the table, and it is what tells two tables apart where both sit in one wave log under this same heading grammar: `<wave-id>-agent` for the wave agent's own scan over the files it landed, taking the wave id the Approach's execution-wave plan already assigns (`W9c-agent`); `R<n>-round-end` for the parent's scan over what that round's waves declared (`R9-round-end`); `phase-5` for the sprint-diff scan. Without it the round scan's first question, whether the agent ran its own scan at all, has no answer a reader can read off the log. On a single-wave round the two scopes coincide by construction and the id still earns its place, because the two SCANS do not: run point 1's green graded the pre-fix-in-wave state, and run point 2 is the first read of the post-fix one.
- **Status** is one of `staged` / `fixed` / `false-positive: <one-line reason>`.
- **Into the Phase 5 decision table** (Finding / Severity / Decision / Evidence): Finding, file:line, and Evidence carry over; Severity is the catalog default for the Catalog ID (Reviewer D may move it one level in context); `staged` rows enter as accept-candidates.

## TRIAGE

- **Every candidate gets exactly one disposition**, `staged`, `fixed`, or `false-positive`. A candidate that vanishes without a row is a protocol violation, not a judgment call.
- **Dismissing needs a one-line reason** tied to the pattern's false-positive guard or the run context (bounded input, cold path, test fixture).
- **Disputed rows go to Reviewer D**, implementer says false-positive but the evidence is unclear → Reviewer D decides; that verdict is final for the sprint.
- **Critical candidates need a co-sign.** A candidate whose catalog default is Critical cannot be dismissed by the implementer alone. Reviewer D co-signs the false-positive. In quick mode there is no Reviewer D: the dismissal carries over to the 5-lite single reviewer, whose lens includes performance, for co-sign during its review.
- **Fix-in-wave is allowed** only for trivial fixes inside the wave's file allowlist, and only at the AGENT's run point, where the agent still holds those files; mark them `fixed` with the diff in the wave report. **The parent never fixes at round-end**, it stages, or sends the work back out as a one-task wave scoped to the owning file's allowlist, because every code change is written by a dispatched agent under an allowlist. Everything else waits for the address-all loop.

## Wrong → right micro-examples (top offenders)

Helpers like `mapWithLimit` / `createLruCache` stand for your project's own pool/LRU utility, search for an existing one before writing it (DRY).

**perf.data.n-plus-one**

```ts
// wrong, one query per id
for (const id of ids) orders.push(await repo.findOne(id))
// right, one batched query
const orders = await repo.findMany({ where: { id: { in: ids } } })
```

**perf.async.await-in-loop**

```ts
// wrong, independent items, serial latency
for (const u of urls) results.push(await fetchJson(u))
// right, bounded parallelism
const results = await mapWithLimit(urls, 5, fetchJson)
```

**perf.memory.json-deep-clone**

```ts
// wrong, full serialize + parse, loses Dates/Maps
const copy = JSON.parse(JSON.stringify(state))
// right
const copy = structuredClone(state)
```

**perf.algorithmic.string-concat-loop**

```ts
// wrong, quadratic reallocation
let csv = ''
for (const row of rows) csv += toLine(row)
// right, build once
const csv = rows.map(toLine).join('')
```

**perf.data.select-star**

```sql
-- wrong, wide rows, no covering index
SELECT * FROM users WHERE org_id = $1
-- right, name the columns you read
SELECT id, email, display_name FROM users WHERE org_id = $1
```

**perf.async.unbounded-fanout**

```ts
// wrong, one socket per user, all at once
await Promise.all(userIds.map(syncUser))
// right, pool of 10
await mapWithLimit(userIds, 10, syncUser)
```

**perf.io.sync-fs**

```ts
// wrong, blocks every in-flight request
const tpl = readFileSync(tplPath, 'utf8')
// right, async, read once at startup and reuse
const tpl = await readFile(tplPath, 'utf8')
```

**perf.data.unbounded-result**

```ts
// wrong, grows with the table
const rows = await db.query('SELECT id, name FROM events ORDER BY id')
// right, keyset page
const rows = await db.query(
  'SELECT id, name FROM events WHERE id > $1 ORDER BY id LIMIT 100', [cursor]
)
```

**perf.frontend.unstable-props**

```tsx
// wrong, new object + lambda every render
<Row style={{ padding: 8 }} onSelect={() => pick(row.id)} />
// right, stable references
<Row style={rowStyle} onSelect={handlePick} />
```

**perf.memory.unbounded-cache**

```ts
// wrong, grows forever
const cache = new Map<string, User>()
cache.set(key, user)
// right, bounded LRU with TTL
const cache = createLruCache<User>({ maxSize: 5000, ttlMs: 60_000 })
```

## See also

- [rules/performance.md](../../../rules/performance.md), the canonical catalog every ID here resolves against.
- [rules/perf-guardrails.md](../../../rules/perf-guardrails.md), the always-on distilled stub.
- [review-and-verify.md](review-and-verify.md). Phase 5 address-all loop the staging table feeds.
