# Porting the scanner — on-demand deterministic audit for a non-JS stack

When the project's primary language is not the ECMAScript family, generate a throwaway scanner
for that language in-session, run it, and delete it. The goal is to give a Python/Go/Rust/Java
project the SAME deterministic core the bundled TS/JS scanner gives — grounded in the same
concepts, not invented fresh each time.

Use the bundled scanner as the reference implementation:
`<skill-dir>/scripts/{lexer,checks,exemptions,audit_scan}.py`. Mirror its
structure; swap only the language-specific parts (the masker's comment/string syntax and the
rule analogs).

## Hard contract (non-negotiable)

1. **Ephemeral.** Write the generated script under a fresh `mktemp -d`. Never write it into the
   audited project. Delete the temp dir in Phase 6.
2. **Same output schema.** Emit one JSON object identical in shape to the bundled scanner so
   Phase 4 merges it uniformly:
   ```json
   {"schema_version": 1, "root": "...", "config": {...},
    "stats": {"files_scanned": N, "files_skipped": M, "findings": K},
    "findings": [{"rule_id": "...", "category": "...", "severity": "...",
                  "confidence": "exact", "file": "rel/path", "line": 12, "end_line": 12,
                  "message": "...", "snippet": "...", "fixable": "manual"}]}
   ```
3. **False-positive discipline.** Mask comments and string literals before matching code-construct
   bans, exactly as `lexer.py` does — a ban hiding in a string or comment must NOT match. Only
   emit `confidence: exact` for checks that are truly exact; mark anything heuristic as such.
4. **Same carve-outs.** Reuse the path-exemption model from `exemptions.py`: skip dependency/
   build dirs, generated files, and migrations; waive suppression/inline-type/non-null bans in
   test files; apply the inline-type analog only to that language's equivalent of scoped modules.
5. **Read the project's bans.** Load the project's `ban-patterns.txt` (translate POSIX classes
   to the host regex engine as `audit_scan.py:_posix_to_python` does) so project-defined bans
   are honored, not duplicated.
6. **Obey the caps it enforces.** The generated script itself stays within ≤500 lines/file,
   ≤40 lines/function, ≤3 params, ≤3 nesting.

## Rule analogs by language

Keep the universal checks (file-line cap; secret regexes — those are language-independent).
Translate the construct bans to each language's real syntax. Drop a row where the language has
no analog (e.g. Python has no non-null `!`).

| rule_id | TS/JS (reference) | Python | Go | Rust | Java/C# |
|---|---|---|---|---|---|
| `cap.file-lines` | line count | line count | line count | line count | line count |
| `ban.suppression` | `@ts-ignore`, `biome-ignore`, `eslint-disable` | `# type: ignore`, `# noqa` | `//nolint` | `#[allow(...)]` | `@SuppressWarnings` |
| `ban.empty-catch` | `catch {}` | `except: pass`, bare `except:` | — (errors are values) | — | `catch (...) {}` |
| `ban.bare-error` | `throw new Error(` | `raise Exception(`/`raise Error(` | `errors.New(`/`fmt.Errorf(` (judgment) | `panic!(` (judgment) | `throw new Exception(` |
| `ban.non-null` | `x!` | — | — | `.unwrap()` / `.expect(` (judgment) | — |
| `ban.inline-type` | `interface`/`type` in scoped module | dataclass/TypedDict in a router/service module | — | — | nested class in controller |
| `sec.hardcoded-secret` | universal regexes | universal | universal | universal | universal |

Severity and category come from `rule-catalog.md` — keep them identical so the merged report is
consistent across the deterministic and on-demand engines.

## Masking notes per language

- **Python** — comments `#…` to end of line; strings `'…'`, `"…"`, and triple-quoted
  `'''…'''` / `"""…"""` (multi-line, track across lines like the JS template state); raw/f
  strings prefix-aware. No braces, so there is no brace-based structure check — leave function
  length / nesting to the linter or semantic pass.
- **Go / Rust / Java / C#** — `//` line and `/* */` block comments; `"…"` strings;
  Go/C# raw strings (backtick / `@"…"`); Rust raw strings `r#"…"#`. Brace-based, so the JS
  masker's logic transfers almost directly — only the comment/string token set changes.

When in doubt, prefer a missed finding (false negative) over a false positive: an on-demand
scanner that cries wolf is worse than one that quietly defers a class of checks to the semantic
pass. State in the report which deterministic checks the on-demand scanner actually ran.
