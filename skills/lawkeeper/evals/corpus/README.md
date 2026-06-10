# lawkeeper recall corpus

A synthetic project of **deliberately-violating fixtures** used to measure the
lawkeeper auditor's *precision and recall against a known oracle* — answering
"when we say lawkeeper enforces rule X, does it actually fire on X, and only on
X?" Before this corpus, the deterministic scanner had unit tests (`test_audit.py`)
but no end-to-end recall measurement, and the semantic tier had none at all.

```
corpus/
  project/              the synthetic codebase under audit (NEVER shipped)
  run_corpus.py         deterministic-tier scorer — runs in CI
  ground-truth.json     generated oracle (file, line, rule_id); kept fresh by run_corpus
  semantic-runner.md    how to score the judgment tier on demand (needs a model)
  README.md             this file
```

## The marker convention (the oracle)

Every planted violation carries an **inline marker** naming the rule it exercises.
Markers are the single source of truth — move a line and the marker moves with it,
so there is no separate line-numbered file to rot.

| Marker | Meaning | Scored by |
|---|---|---|
| `// EXPECT: <rule_id>` | the scanner MUST report `<rule_id>` on this line (recall) | `run_corpus.py` (CI) |
| `// EXPECT-CLEAN: <reason>` | the scanner must STAY SILENT here despite looking violation-ish (precision / carve-out) | `run_corpus.py` (exact-match) |
| `// EXPECT-SEMANTIC: <rule_id>` | the judgment tier's oracle — a rule only a subagent can find | `semantic-runner.md` (on demand) |

**Marker hygiene (load-bearing):** a marker carries the **bare `rule_id` only**,
never the banned token it names. `check_secrets` and `check_suppression` scan *raw*
lines, so a marker like `// EXPECT-CLEAN: @ts-ignore is fine` would itself trip
`ban.suppression`. `rule_id`s are safe — none contain the literal token they name.

## Deterministic tier — `run_corpus.py` (CI gate)

```
python3 run_corpus.py          # score + verify ground-truth.json is fresh; exit 1 on any drift
python3 run_corpus.py --emit   # regenerate ground-truth.json after editing markers
```

It runs `audit_scan.py` over `project/` and asserts the finding set equals the
`EXPECT:` set **exactly** — every expected finding caught (recall) and nothing
extra (precision; `EXPECT-CLEAN:` carve-out lines must produce no finding). Today
it covers 9 of the 10 deterministic rules at 100% recall with 0 false positives
across 7 carve-out traps (test-file waivers, non-scoped inline types, the
env-name secret guard, owned/ticketed debt markers, generated/migration files).
`ban.custom` is exercised by `test_audit.py` (it needs a project `ban-patterns.txt`).

## Semantic tier — on demand

The judgment rules (DRY, layering, controller-purity, SRP, security beyond
secrets, performance, testing, SOLID) cannot be scored deterministically — they
run in subagents. `EXPECT-SEMANTIC:` markers are their oracle; `semantic-runner.md`
documents how to dispatch the semantic pass against `project/` and diff its
findings against the oracle. Kept out of CI because it needs a model; a single run
is illustrative, not a stable metric (run each concern a few times).

## Why this is never shipped

The fixtures contain a planted hardcoded secret and other intentional violations.
They are a CI artifact only: excluded from the sync manifest (`validate-dod` `[55]`
skips `*/evals/corpus/*`) so they never reach a `dist/<runtime>/` tree, and
allow-listed in `.claude/hooks/ban-allowlist` so the on-by-default ban-blocker
does not stop you from editing them.

## Adding a fixture

1. Add the violating line to a file under `project/` with a trailing
   `// EXPECT: <rule_id>` (or `EXPECT-CLEAN` / `EXPECT-SEMANTIC`).
2. Run `python3 run_corpus.py` — calibrate against the real scanner; confirm the
   finding lands exactly where you marked it (findings report at the match-start
   line; carve-out globs need a parent path segment, e.g. `backend/migrations/x.ts`).
3. `python3 run_corpus.py --emit` to refresh `ground-truth.json`, then commit.
