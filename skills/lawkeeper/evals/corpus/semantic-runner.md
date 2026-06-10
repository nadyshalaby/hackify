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
pass is expected to find. Today's oracle (20 pairs, 11 concerns):

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
| `orders.service.ts` | `style.magic-literal` (un-named 1.1 tax multiplier) |
| `billing.service.ts` | `test.untested` (branching service logic, no test anywhere) |
| `billing.service.ts` | `style.magic-literal` (un-named 0.0825 / 10000 / 0.02) |
| `users.test.ts` | `test.edge-cases` (happy-path-only pageBounds test; clamp branch untested) |
| `flags.ts` | `clean.dead-flag` (auditTrail defined, read nowhere; newCheckout is the control) |
| `env.ts` | `clean.orphan-env` (ANALYTICS_KEY validated, used nowhere) |
| `package.json` | `clean.unused-dep` (left-pad declared, imported nowhere) |
| `transport.ts` | `solid.yagni` (grpc/kafka knobs for transports that do not exist) |
| `render.ts` | `solid.ocp` (xml bolted on as a conditional beside the renderers registry) |
| `report.ts` | `cap.fn-lines` (≈49-line function body) |
| `report.ts` | `cap.fn-params` (5 parameters) |
| `report.ts` | `cap.fn-nesting` (4 levels of control flow) |

### Deliberately NOT in the oracle

- `clean.commented-code` — the blind copy strips ALL comments (step 0), so this
  violation vanishes by construction; it cannot be measured under this harness.
- `clean.unref-file` and `scope.dead-code` — in a disconnected synthetic corpus
  nearly every file/symbol is unreferenced, so the oracle cannot be localized
  (the same reason `scope.dead-code` was dropped from `orders.service.ts`).
- `solid.lsp` / `solid.isp` / `solid.dip` — need type hierarchies and an
  injection container a tiny corpus cannot plausibly host; a plant would be a
  prompt-shaped fixture, not a realistic violation.

## Procedure

0. **Strip ALL comments first (mandatory).** A subagent reads comments, so both
   the inline `// EXPECT-SEMANTIC:` markers AND the fixtures' descriptive headers
   ("presentation-layer leaks a subagent must find", "mutates without a permission
   check") would hand it the answers — an open-book test that fakes recall. Scan a
   comment-stripped copy so the subagent judges pure code. (Fixtures deliberately
   keep `//` out of string literals, so a line strip is safe.) JSON fixtures
   (`package.json`) carry their marker in a legal `"//"` key — `//`-stripping
   would break the JSON, so for `.json` the marker LINE is dropped whole, which
   keeps the manifest parseable and still removes the leak. The deterministic
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
           with open(p, encoding='utf-8') as fh:
               raw = fh.readlines()
           if name.endswith('.json'):
               lines = [l for l in raw if 'EXPECT' not in l]
           else:
               lines = [strip.sub('', l).rstrip() + '\n' for l in raw]
           with open(p, 'w', encoding='utf-8') as fh:
               fh.writelines(lines)
   print('blind copy at', dst)
   PY
   ```

1. **Dispatch the concerns.** For each concern that maps to an oracle rule, spawn
   one subagent in parallel, scoped to the **blind copy** from step 0, handing it
   the concern block from `semantic-pass.md`, the shared OUTPUT contract, **and the
   carve-out floors** (`references/carve-outs.md`) — without them a subagent flags
   exempt files (e.g. a non-idempotent migration), which the deterministic scanner
   skips, producing measurement artifacts. The `caps` subagent also needs the cap
   thresholds (global doctrine: 40 lines / 3 params / 3 nesting — the corpus has
   no harness of its own). The oracle above is covered by eleven concerns:
   - `security` → `sec.injection`, `sec.authz`
   - `dry` → `style.dry`
   - `layering` → `scope.layer`, `scope.controller-purity`
   - `single-responsibility` → `style.srp`
   - `performance` → `perf.n-plus-1`
   - `naming-explicitness` → `style.ternary`
   - `caps` → `cap.fn-lines`, `cap.fn-params`, `cap.fn-nesting`
   - `magic-literals` → `style.magic-literal`
   - `testing` → `test.untested`, `test.edge-cases`
   - `solid` → `solid.yagni`, `solid.ocp`
   - `cleanup-extras` → `clean.dead-flag`, `clean.orphan-env`, `clean.unused-dep`
2. **Collect findings per round.** A *round* dispatches all eleven concerns once.
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

Latest snapshot, **2026-06-10, full 20-pair / 11-concern oracle, 3 rounds, sonnet
subagents** (the number depends on the model and rounds — this records *what the
harness surfaces*, not a guarantee):

- **Strict recall: 59/60 pair-runs (98%); 19/20 pairs at 3/3.** The lone 2/3 is
  the DRY attribution artifact below, so **true recall is 20/20**. Every concern
  added in the breadth expansion (caps, magic-literals, testing, SOLID,
  cleanup-extras) scored 3/3 on first measurement — including the manifest-based
  `clean.unused-dep` and both contrast-localized cleanup rules.
- **DRY file-attribution is ambiguous.** A symmetric duplication has no canonical
  "violation file"; one round pins `style.dry` to `users.service.ts` while the
  oracle marks `auth.service.ts`. Counted as a strict miss but a true find — for
  cross-file rules, read a finding on *either* duplicated file as a hit.
- **Test-coverage findings pin to the SOURCE file, not the test file.** The pass
  found the planted happy-path-only gap (pageBounds' size>100 clamp never
  exercised) 3/3 but attributed it to `users.service.ts`, where the under-tested
  behavior lives — which matches the rule text ("behavior with happy-path-only
  tests"). The oracle marker was moved to the source file accordingly; detection
  was never the problem. Lesson for new fixtures: place cross-file markers where
  the rule's SUBJECT lives.
- EXTRAs that are real (not oracle): the controller authz gap (`sec.authz` 3/3 —
  planted as a layering pair, genuinely also a security finding), `report.ts`
  `perf.algorithmic` + `style.srp` (3/3 each — a 49-line aggregate-everything
  function genuinely violates both), and `test.untested` on most files (a corpus
  with one test file makes everything else genuinely untested — expected, true,
  not planted). The floors mandate held: zero exempt-file artifacts this run (no
  `sec.migration` over-flag). Triage extras before trusting; the pass surfaces
  more than the planted set.

### Earlier snapshot — the sec.authz gap (found, then CLOSED, 0.4.6)

On the original 8-pair oracle (3 rounds, sonnet): strict 18/24 before the fix,
21/24 after. The original `security` prompt led with "routes/handlers," so the
pass flagged missing-authz on the *controller* mutation (3/3) but missed the
*service-layer* `deleteUser` (0/3 — an opus run missed it too). The `sec.authz`
clause in `references/semantic-pass.md` was rewritten to cover state-changing ops
at ANY layer, with destructive ops as the canonical case and "do not assume an
upstream caller checks." Re-running then caught it **3/3** — and it stayed 3/3 in
the 20-pair snapshot above. The measurement surfaced a prompt weakness and
verified the fix: the corpus paying for itself.

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
