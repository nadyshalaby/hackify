# Runtime adapters (primitive-to-native tool mapping)

## Why this file exists

hackify is authored against 10 abstract primitives (wizard, subagent, file-read, file-write, file-edit, search, shell, todo tracker, orchestration tier, iteration driver) rather than any single runtime's tool names. Each target runtime ships its own tool surface. Claude Code calls a file read `Read`, Gemini CLI calls it `read_file`, Codex CLI exposes it through MCP, so hackify decouples the workflow language from the tool language. This file is the single source of truth for how every primitive maps onto every supported runtime's native tools. `scripts/sync-runtimes.sh` reads this table to emit per-runtime skill bundles under `dist/<runtime>/` that reference the correct native names. When a runtime lacks a direct equivalent, the cell is marked `n/a, <reason>` honestly rather than papered over.

## The 10 primitives

- `wizard tool`, multi-question batched interactive question prompt to the user.
- `subagent dispatcher`, launches a foreground subagent with a self-contained prompt and waits for the result.
- `file-read op`, reads a local file.
- `file-write op`, writes/creates a local file.
- `file-edit op`, applies a targeted in-place edit to a local file.
- `search`, pattern search across the project (regex/literal).
- `shell`, executes a shell command (with optional timeout).
- `todo tracker`, a trackable, ordered to-do list surfaced to the user; the substrate for the phase ledger (`phase-ledger.md`). Where a runtime has no native list, the fallback is an in-chat markdown checklist, the phase ledger degrades to visible-but-not-interactive, never absent.
- `orchestration tier`, how much parallel machinery a mandatory fan-out gets (Phase 2.5 reviewers, Phase 3 waves, Phase 5 reviewers + refuters). Hackify runs at MAXIMUM tier by default in every mode. Contract, standing authorization, and the opt-out phrases: [orchestration.md](orchestration.md).
- `iteration driver`, what re-enters the workflow across turns until the phase ledger is fully ticked. On by default; operates ABOVE the phases, never inside one. Same contract file.

## Per-runtime mapping table

| Primitive | Claude Code | Codex CLI | Codex App | Gemini CLI | OpenCode | Cursor | Copilot CLI |
|---|---|---|---|---|---|---|---|
| wizard tool | `AskUserQuestion` | n/a, no batched-question primitive; emulate via single-shot chat turn | n/a, hosted UI handles questions inline; no programmatic batch tool | n/a, no batched-question primitive; emulate via single chat turn | n/a, no batched-question primitive; emulate via single chat turn | n/a, no programmatic question tool; emulate via inline prompt | n/a, no programmatic question tool; emulate via inline prompt |
| subagent dispatcher | `Agent` | n/a, no foreground subagent primitive; inline the prompt | n/a, no foreground subagent primitive; inline the prompt | n/a, no foreground subagent primitive; inline the prompt | `task` (custom mode dispatch) | n/a, no subagent primitive; inline the prompt | n/a, no subagent primitive; inline the prompt |
| file-read op | `Read` | `read_file` (MCP filesystem) | `read_file` (MCP filesystem) | `read_file` | `read` | built-in file context | built-in file context |
| file-write op | `Write` | `write_file` (MCP filesystem) | `write_file` (MCP filesystem) | `write_file` | `write` | inline edit via chat | inline edit via chat |
| file-edit op | `Edit` | `apply_patch` | `apply_patch` | `replace` | `edit` | inline edit via chat | inline edit via chat |
| search | `Grep` | `ripgrep` (via shell) | `ripgrep` (via shell) | `grep` | `grep` | built-in codebase search | n/a, no project-wide search tool; rely on shell `grep` |
| shell | `Bash` | `shell` | `shell` | `run_shell_command` | `bash` | built-in terminal | `shell` |
| todo tracker | `TodoWrite` | n/a, no todo primitive; emulate as an in-chat markdown checklist | n/a, hosted UI; emulate as an in-chat markdown checklist | n/a, no todo primitive; emulate as an in-chat markdown checklist | `todowrite` | n/a, no todo primitive; emulate as an in-chat markdown checklist | n/a, no todo primitive; emulate as an in-chat markdown checklist |
| orchestration tier | `ultracode` keyword in scope + the `Workflow` tool for fan-outs a flat batch serves poorly | n/a, no subagent primitive; max tier means the phases run inline and sequentially | n/a, same as Codex CLI | n/a, same as Codex CLI | largest parallel `task` dispatch the mode supports | n/a, no subagent primitive; phases run inline | n/a, no subagent primitive; phases run inline |
| iteration driver | `/loop` in self-paced mode carrying `continue work on <slug>` | n/a, no scheduler; parent runs phases to completion in-turn, user re-prompts to resume | n/a, same as Codex CLI | n/a, same as Codex CLI | n/a, no scheduler; same in-turn carry | n/a, no scheduler; same in-turn carry | n/a, no scheduler; same in-turn carry |

## Plugin model support matrix

| Runtime | Plugin model | Skill auto-discovery | Subagent dispatch | Notes |
|---|---|---|---|---|
| Claude Code | native | native | native | Reference runtime. Skills under `~/.claude/skills/` auto-load; `Agent` tool dispatches foreground subagents. |
| Codex CLI | best-effort | best-effort | not supported | MCP servers registered via TOML config provide tool surface. Skills emulated as prompt files referenced from `AGENTS.md`. |
| Codex App | best-effort | best-effort | not supported | Hosted plugin slots accept structured tool integrations. Skills uploaded as prompt files; no in-process subagent. |
| Gemini CLI | best-effort | best-effort | not supported | Extension JSON registers tools; `GEMINI.md` carries project context. Skills emulated as referenced markdown files. |
| OpenCode | native | native | native | Custom modes are markdown files mirroring Claude Code conventions; `task` mode dispatches subagents. |
| Cursor | best-effort | best-effort | not supported | `.mdc` rule files (legacy `.cursorrules`) carry skill content. No subagent primitive, workflows run inline. |
| Copilot CLI | not supported | not supported | not supported | No plugin or skill model. Install path is manual prompt-context copy-paste; ships best-effort only. |

## Native-tier enhancements (optional, never load-bearing)

The 8 primitives above are the only load-bearing contract: every workflow phase runs on them alone,
on every tier. The enhancements below upgrade ergonomics or wall-clock time on runtimes that support
them, nothing more. Each one carries a stated degrade path, and no workflow phase may hard-require
an enhancement; a phase that cannot run without one is a portability bug. (The deterministic
perf-scout is deliberately absent from this list: it rides the `shell` primitive and runs identically
on every tier.)

| Enhancement | What it upgrades | Phases that benefit | Degrade path |
|---|---|---|---|
| Structured subagent outputs | Reviewer/scout findings return as machine-readable, schema-validated data instead of prose tables, making aggregation and the decision table mechanical | Phase 2.5 + Phase 5 | Aggregation degrades to the word-capped markdown OUTPUT tables the templates already mandate |
| Background subagents | Long-running research/audit/scan agents run in the background and notify on completion, overlapping with user interaction | Phase 1 exploration; large Phase 5 scans | Dispatch degrades to foreground sequential subagents |
| Per-agent model/effort tiers | Mechanical work (deterministic scout runs, registration edits) rides a fast/cheap tier while deep reviewers and implementers keep the strongest tier, cost and latency drop with no rigor loss | Phase 3 + Phase 5 dispatches | Tiering degrades to a single-model runtime where all agents run equal |
| Task-tracker dependency ordering | Phase-ledger items carry blocked-by edges, so starting a phase out of order becomes mechanically impossible, extends the ordering law in `phase-ledger.md` | Every phase (ledger-wide) | Ordering degrades to the convention-enforced law `phase-ledger.md` already specifies |
| Batched wizard rounds | Several back-to-back wizard calls land in one turn, so the Phase 1 questionnaire flows as 4-question batches | Phase 1 | Batching degrades to sequential single batches |

Per-runtime support, in the same column order as the mapping table, runtime-specific tool names stay
inside the table cells, per this file's convention:

| Enhancement | Claude Code | Codex CLI | Codex App | Gemini CLI | OpenCode | Cursor | Copilot CLI |
|---|---|---|---|---|---|---|---|
| Structured subagent outputs | native, `Agent` findings returned schema-validated | n/a, no subagent primitive | n/a, no subagent primitive | n/a, no subagent primitive | unknown, `task` returns prose; schema validation unverified | n/a, no subagent primitive | n/a, no subagent primitive |
| Background subagents | native, `Agent` with `run_in_background` | n/a, no subagent primitive | n/a, no subagent primitive | n/a, no subagent primitive | unknown, `task` background dispatch unverified | n/a, no subagent primitive | n/a, no subagent primitive |
| Per-agent model/effort tiers | native, per-`Agent` `model` override; per-agent effort in agent definitions | n/a, no subagent primitive | n/a, no subagent primitive | n/a, no subagent primitive | partial, per-mode model pinning in mode files; effort control unverified | n/a, no subagent primitive | n/a, no subagent primitive |
| Task-tracker dependency ordering | native, `TodoWrite` items carry blocked-by edges | n/a, no todo primitive | n/a, no todo primitive | n/a, no todo primitive | unknown, `todowrite` exists; dependency edges unverified | n/a, no todo primitive | n/a, no todo primitive |
| Batched wizard rounds | native, back-to-back `AskUserQuestion` calls in one turn | n/a, no batched-question primitive | n/a, no batched-question primitive | n/a, no batched-question primitive | n/a, no batched-question primitive | n/a, no batched-question primitive | n/a, no batched-question primitive |

## Sync output per runtime

- `dist/claude-code/`, full skill bundle with native tool names (`AskUserQuestion`, `Agent`, `Read`, `Write`, `Edit`, `Grep`, `Bash`, `TodoWrite`); drop-in to `~/.claude/skills/hackify/`.
- `dist/codex-cli/`, prompt files plus `AGENTS.md` references; MCP filesystem config snippet for `read_file`/`write_file`/`apply_patch`.
- `dist/codex-app/`, prompt files structured for upload; manifest lists required MCP tools.
- `dist/gemini-cli/`, markdown files plus `GEMINI.md` include directives; extension JSON snippet registering `read_file`/`write_file`/`replace`/`grep`/`run_shell_command`.
- `dist/opencode/`, custom-mode markdown files using `read`/`write`/`edit`/`grep`/`bash`/`task`/`todowrite` native names.
- `dist/cursor/`, `.mdc` rule files inlining the workflow; subagent steps rewritten as inline prompts.
- `dist/copilot-cli/`, single concatenated prompt-context file with manual-install instructions; no automatic discovery.

## Host-interpreter dependencies (skills that ship an executable engine)

The eight primitives are interpreter-free: the core hackify workflow is pure markdown and runs
wherever the `shell` primitive runs. Two companion skills ship an executable engine that rides
the `shell` primitive and therefore assumes a host interpreter on PATH, honest to state, since
no runtime adapter can conjure one:

| Skill | Engine | Interpreter assumed | If absent, degradation |
|---|---|---|---|
| `lawkeeper` | `scripts/audit_scan.py` deterministic scanner (Phase 2) | `python3` | Report the gap and fall through to the interpreter-free semantic subagent pass (Phase 3). |
| `hackify` (**core**, since v0.9.0) | the law-scout runs that same `audit_scan.py --paths-from` at every Phase 3 wave-end and at Phase 5 start ([law-scout.md](law-scout.md)) | `python3` | Record `deterministic tier unavailable (no python3)` as a staging row and run the law-scout's semantic tier only, Reviewer B's seven lenses are interpreter-free. Never drop the mechanical tier silently. |
| `hackify` (**core**, since v0.9.0) | the ship gate starts and stops a real process and polls a readiness probe ([ship-gate.md](ship-gate.md)) | background process control + a port or HTTP probe from the shell primitive | On a runtime that cannot background a process or poll a port, run the build leg (a plain foreground command) and record `ship.boot` / `ship.smoke` as `⏭ skipped, runtime cannot supervise a background process`. Coverage degrades to a written gap, never to a silent pass. |
| `codewalk` | `assets/serve.js` viewer server + `build-playbook.mjs` | `node` | Fall back to the documented server chain (`python3`/`python`/`npx serve`/`php`/`ruby`) for serving the already-generated `.codewalk/<slug>/` artifact. |

Neither interpreter is a hackify-core requirement, only those two skills' engines need them,
and each degrades to a stated, non-silent fallback. Document any future skill that adds a host
interpreter here so the multi-runtime story stays honest.

## When to update this file

Update this file whenever a target runtime adds, renames, or removes a tool that maps to one of the 8 primitives, whenever a new runtime is added to the support set, or whenever a runtime's plugin model crosses a tier boundary (best-effort gains native subagent dispatch, for example). The `scripts/sync-runtimes.sh` script reads this table directly, drifting it from the script's expectations will break the per-runtime bundles in `dist/`.
