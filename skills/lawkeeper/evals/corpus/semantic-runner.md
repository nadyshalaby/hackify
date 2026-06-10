# Semantic-tier runner — scoring the judgment rules

The deterministic tier (`run_corpus.py`) runs in CI. The judgment rules — DRY,
layering, controller-purity, SRP, security beyond secrets, performance, testing,
SOLID — cannot be scored deterministically: they are found by the semantic-pass
subagents (see `../../references/semantic-pass.md`), which read the code and
judge. This is the on-demand harness that measures how many of them actually
fire against a known oracle.

**It needs a model, so it is NOT in CI.** And it is non-deterministic — one run
is *illustrative*, not a metric. Run each concern a few times before trusting a
recall number; a single miss may be variance, a consistent miss is a real gap.

## The oracle

Every semantic violation in `project/` carries an `// EXPECT-SEMANTIC: <rule_id>`
marker. `score_semantic.py` reads them (via `run_corpus.collect_markers`) and
reduces them to unique `(file basename, rule_id)` pairs — the set the semantic
pass is expected to find. Today's oracle:

| file | rule_id |
|---|---|
| `auth.service.ts` | `sec.injection` (string-concat SQL from input) |
| `auth.service.ts` | `sec.authz` (mutation with no permission check) |
| `auth.service.ts` | `style.dry` (re-implements `users.service` pageBounds) |
| `users.controller.ts` | `scope.layer` (controller does direct DB access) |
| `users.controller.ts` | `scope.controller-purity` (branching + multiple service calls) |
| `orders.service.ts` | `perf.n-plus-1` (query issued per row inside a loop) |
| `orders.service.ts` | `style.srp` (one unit validates, taxes, persists, emails) |
| `orders.service.ts` | `style.ternary` (chained ternary) |

## Procedure

0. **Strip ALL comments first (mandatory).** A subagent reads comments, so both
   the inline `// EXPECT-SEMANTIC:` markers AND the fixtures' descriptive headers
   ("presentation-layer leaks a subagent must find", "mutates without a permission
   check") would hand it the answers — an open-book test that fakes recall. Scan a
   comment-stripped copy so the subagent judges pure code. (Fixtures deliberately
   keep `//` out of string literals, so a line strip is safe.) The deterministic
   scanner pattern-matches and never reads comments, so `run_corpus.py` keeps
   scanning the original; only the semantic subagents need the blind copy:

   ```bash
   python3 - <<'PY'
   import os, re, shutil
   src, dst = 'project', '/tmp/corpus-blind'
   shutil.rmtree(dst, ignore_errors=True); shutil.copytree(src, dst)
   strip = re.compile(r'//.*$')
   for root, _d, files in os.walk(dst):
       for name in files:
           p = os.path.join(root, name)
           lines = [strip.sub('', l).rstrip() + '\n' for l in open(p, encoding='utf-8')]
           open(p, 'w', encoding='utf-8').writelines(lines)
   print('blind copy at', dst)
   PY
   ```

1. **Dispatch the concerns.** For each concern that maps to an oracle rule, spawn
   one subagent in parallel, scoped to the **blind copy** from step 0, handing it
   the concern block from `semantic-pass.md`, the shared OUTPUT contract, **and the
   carve-out floors** (`references/carve-outs.md`) — without them a subagent flags
   exempt files (e.g. a non-idempotent migration), which the deterministic scanner
   skips, producing measurement artifacts. The oracle above is covered by six
   concerns:
   - `security` → `sec.injection`, `sec.authz`
   - `dry` → `style.dry`
   - `layering` → `scope.layer`, `scope.controller-purity`
   - `single-responsibility` → `style.srp`
   - `performance` → `perf.n-plus-1`
   - `naming-explicitness` → `style.ternary`
2. **Collect findings per round.** A *round* dispatches all six concerns once.
   Merge that round's subagent JSON (the shared shape: `{"findings": [{rule_id,
   file, line, message, ...}]}`) into one `findings-round-N.json` — either an
   object with a combined `findings` array, or a flat array of finding objects;
   `score_semantic.py` accepts both. Run **3+ rounds** (the pass is
   non-deterministic — one round is illustrative, not a metric).
3. **Score across rounds.** `python3 score_semantic.py findings-round-*.json`
   prints a **hit-rate per `(file, rule)`** (e.g. `2/3` rounds), a mean recall,
   and any EXTRA findings (possible false positives — confirm before trusting;
   the pass is told to prefer false negatives). Pass a single file for a one-off
   illustrative read.

## Observed baseline (illustrative — re-measure, don't trust the number blind)

A snapshot, **2026-06-10, 3 rounds, sonnet subagents** (the number depends on the
model and rounds — this records *what the harness surfaces*, not a guarantee):

- **Strict recall: 18/24 pair-runs at first; 21/24 (7/8 pairs) after the authz fix
  below.** The only remaining "miss" is the DRY attribution artifact, so **true
  recall is 8/8**.
- **A real gap — found, then CLOSED (the corpus working as intended).** The original
  `security` prompt led with "routes/handlers," so the pass flagged missing-authz on
  the *controller* mutation (3/3) but missed the *service-layer* `deleteUser` (0/3 —
  the opus run missed it too). The `sec.authz` clause in `references/semantic-pass.md`
  was rewritten to cover state-changing ops at ANY layer, with destructive ops as the
  canonical case and "do not assume an upstream caller checks." Re-running the security
  concern then caught `auth.service.ts: sec.authz` **3/3**. The measurement surfaced a
  prompt weakness and verified the fix.
- **DRY file-attribution is ambiguous.** A symmetric duplication has no canonical
  "violation file"; the pass pinned `style.dry` to `users.service.ts` (3/3) while
  the oracle marks `auth.service.ts`. Counted as a strict miss but a true find — for
  cross-file rules, read a finding on *either* duplicated file as a hit.
- EXTRAs that are real (not oracle): a controller authz gap, `fail()` naming, sync
  blocking-IO. The semantic pass surfaces more than the planted set; triage before
  trusting.

## Why a separate tier

A judgment finding has no exact line and no zero-false-positive guarantee, so it
cannot share the deterministic tier's exact-match gate. Keeping it here — scored
by file+rule, on demand, explicitly labelled illustrative — is the honest way to
measure it without pretending it is deterministic.

## Adding a semantic fixture

Add a deterministically-CLEAN violation (no banned tokens, or the deterministic
exact-match in `run_corpus.py` breaks) to a file under `project/`, mark it
`// EXPECT-SEMANTIC: <rule_id>`, run `python3 run_corpus.py --emit` to refresh
`ground-truth.json`, and extend the oracle table above.
