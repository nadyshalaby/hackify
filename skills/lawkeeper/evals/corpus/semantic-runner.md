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
   the concern block from `semantic-pass.md` plus the shared OUTPUT contract. The
   oracle above is covered by three concerns:
   - `security` → `sec.injection`, `sec.authz`
   - `dry` → `style.dry`
   - `layering` → `scope.layer`, `scope.controller-purity`
2. **Collect findings.** Merge every subagent's JSON (the shared shape:
   `{"findings": [{rule_id, file, line, message, ...}]}`) into a single
   `findings.json` — either one object with a combined `findings` array, or a
   flat array of finding objects. `score_semantic.py` accepts both.
3. **Score.** `python3 score_semantic.py findings.json` prints recall per
   `(file, rule)` plus any EXTRA findings (possible false positives — confirm
   before trusting; the semantic pass is told to prefer false negatives).
4. **Repeat** a few times per concern for a stable number.

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
