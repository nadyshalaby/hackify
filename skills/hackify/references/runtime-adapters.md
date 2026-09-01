# Runtime adapters (primitive-to-native tool mapping)

## Why this file exists

hackify is authored against 12 abstract primitives (wizard, subagent, file-read, file-write, file-edit, search, shell, todo tracker, orchestration tier, iteration driver, completion sentinel, always-on injection) rather than any single runtime's tool names. Each target runtime ships its own tool surface. Claude Code calls a file read `Read`, Gemini CLI calls it `read_file`, Codex CLI exposes it through MCP, so hackify decouples the workflow language from the tool language. This file is the single source of truth for how every primitive maps onto every supported runtime's native tools. The per-runtime emitters under `scripts/sync-runtimes.d/` write the skill bundles in `dist/<runtime>/` that carry the correct native names. Nothing machine-reads the table below, so the table and those emitters are kept in agreement by hand. When a runtime lacks a direct equivalent, the cell is marked `n/a, <reason>` honestly rather than papered over.

## The 12 primitives

- `wizard tool`, multi-question batched interactive question prompt to the user.
- `subagent dispatcher`, launches a foreground subagent with a self-contained prompt and waits for the result.
- `file-read op`, reads a local file.
- `file-write op`, writes/creates a local file.
- `file-edit op`, applies a targeted in-place edit to a local file.
- `search`, pattern search across the project (regex/literal).
- `shell`, executes a shell command (with optional timeout).
- `todo tracker`, a trackable, ordered to-do list surfaced to the user; the substrate for the phase ledger (`phase-ledger.md`). Where a runtime has no native list, the fallback is to print the ledger in chat as a markdown checklist and re-print it at every phase boundary, plus the work-doc's `## 0. Phase ledger` block in full hackify, which is the durable copy. The phase ledger degrades to visible-but-not-interactive, never absent.
- `orchestration tier`, how much parallel machinery a mandatory fan-out gets (Phase 2.5's single spec reviewer, Phase 3 waves, the Phase 5 reviewer panel plus its single refuter). Hackify runs at MAXIMUM tier by default in every mode. Contract, standing authorization, and the opt-out phrases: [orchestration.md](orchestration.md).
- `iteration driver`, what re-enters the workflow across turns until the phase ledger is fully ticked. On by default; operates ABOVE the phases, never inside one. Same contract file.
- `completion sentinel`, a one-line completion condition an INDEPENDENT evaluator re-checks after every turn, so "done" is not the parent's own opinion. On by default in every mode; parent-only, never proposed from a subagent. Unlike the other two it has no reliable tool call, the parent always prints a paste-ready line and calls the native tool only when it is genuinely in scope. Same contract file.
- `always-on injection`, a per-prompt context injector that puts the plugin's non-negotiable laws in front of the model on every message, independent of which skill is loaded. Native only on Claude Code, the `UserPromptSubmit` hook in `hooks/hooks.json`, currently five rules files. Where no such primitive exists, the same laws reach the model through `SKILL.md` prose alone, which is weaker, and that gap is why the Claude Code path exists.

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
| todo tracker | `TodoWrite` when the session exposes it; it is gated and frequently absent, so fall back to printing the ledger in chat at every phase boundary, plus the work-doc's `## 0. Phase ledger` block in full hackify, the durable copy | n/a, no todo primitive; emulate as an in-chat markdown checklist | n/a, hosted UI; emulate as an in-chat markdown checklist | n/a, no todo primitive; emulate as an in-chat markdown checklist | `todowrite` | n/a, no todo primitive; emulate as an in-chat markdown checklist | n/a, no todo primitive; emulate as an in-chat markdown checklist |
| orchestration tier | `ultracode` keyword in scope + the `Workflow` tool for fan-outs a flat batch serves poorly | n/a, no subagent primitive; max tier means the phases run inline and sequentially | n/a, same as Codex CLI | n/a, same as Codex CLI | largest parallel `task` dispatch the mode supports | n/a, no subagent primitive; phases run inline | n/a, no subagent primitive; phases run inline |
| iteration driver | `/loop` in self-paced mode carrying `continue work on <slug>` | n/a, no scheduler; parent runs phases to completion in-turn, user re-prompts to resume | n/a, same as Codex CLI | n/a, same as Codex CLI | n/a, no scheduler; same in-turn carry | n/a, no scheduler; same in-turn carry | n/a, no scheduler; same in-turn carry |
| completion sentinel | conditional, `/goal <condition>` printed for the user to paste (needs a trusted workspace and unrestricted hooks); the `ProposeGoal` tool only when it is in scope, parent-only, blocked in plan mode | n/a, no session-goal primitive; degrades to the anchor's Success Signals + Phase 4 acceptance rows | n/a, same as Codex CLI | n/a, same as Codex CLI | n/a, no session-goal primitive; same degrade | n/a, no session-goal primitive; same degrade | n/a, no session-goal primitive; same degrade |
| always-on injection | native, the `UserPromptSubmit` hook in `hooks/hooks.json`, currently five rules files | n/a, no per-prompt injection primitive; the same laws reach the model through `SKILL.md` prose alone, which is weaker | n/a, same as Codex CLI | n/a, same as Codex CLI | n/a, no per-prompt injection primitive; same degrade | n/a, no per-prompt injection primitive; same degrade | n/a, no per-prompt injection primitive; same degrade |

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

The first 8 primitives above (wizard through todo tracker) are the only load-bearing contract: every
workflow phase runs on them alone, on every tier. The last 4 (orchestration tier, iteration driver,
completion sentinel, always-on injection) raise the ceiling where a runtime supports them and
degrade to a stated fallback where it does not, so no phase may hard-require one. The enhancements
below upgrade ergonomics or wall-clock time on runtimes that support them, nothing more. Each one carries a stated degrade path, and no workflow phase may hard-require
an enhancement; a phase that cannot run without one is a portability bug. (The deterministic
perf-scout is deliberately absent from this list: it rides the `shell` primitive and runs identically
on every tier.)

| Enhancement | What it upgrades | Phases that benefit | Degrade path |
|---|---|---|---|
| Structured subagent outputs | Reviewer/scout findings return as machine-readable, schema-validated data instead of prose tables, making aggregation and the decision table mechanical | Phase 2.5 + Phase 5 | Aggregation degrades to the word-capped markdown OUTPUT tables the templates already mandate |
| Background subagents | Long-running research/audit/scan agents run in the background and notify on completion, overlapping with user interaction | Phase 1 exploration; large Phase 5 scans | Dispatch degrades to foreground sequential subagents |
| Per-agent model/effort tiers | Mechanical work (deterministic scout runs, registration edits) rides a fast/cheap tier while deep reviewers and implementers keep the strongest tier, cost and latency drop with no rigor loss | Phase 3 + Phase 5 dispatches | Tiering degrades to a single-model runtime where all agents run equal |
| Task-tracker dependency ordering | Phase-ledger items carry blocked-by edges, so a tracker that has them refuses an out-of-order start instead of leaving it to the written law, extends the ordering law in `phase-ledger.md` | Every phase (ledger-wide) | Ordering degrades to the convention-enforced law `phase-ledger.md` already specifies |
| Batched wizard rounds | Several back-to-back wizard calls land in one turn, so the Phase 1 questionnaire flows as 4-question batches | Phase 1 | Batching degrades to sequential single batches |
| Published work-doc page | The work-doc itself is published as a page and republished on every phase tick, so the user holds one link that stays current instead of a file path they have to open by hand | Phase 2 step 1 onward, every ledger tick | The work-doc stays a file on disk at `docs/work/<slug>.md` and the update log still prints to chat, so ledger item `6d` closes on those two alone; a runtime with no publish tool says so once, in one line, then carries on ([work-doc-artifact.md](work-doc-artifact.md)) |
| Session orientation map | A fresh session is told what this plugin ships, which entry point fits the prompt in front of it, and which rule files are the law, before it picks a route | Routing, ahead of Phase 1 | The map file still ships to the runtime, at `dist/<runtime>/rules/plugin-map.md`, so a model or a user can open it by hand; nothing reads it into the session, and routing falls back to whatever skill descriptions that runtime's own discovery surfaces. `copilot-cli` mirrors no `rules/` tree at all, so there the map is absent rather than merely unread |

Per-runtime support, in the same column order as the mapping table, runtime-specific tool names stay
inside the table cells, per this file's convention:

| Enhancement | Claude Code | Codex CLI | Codex App | Gemini CLI | OpenCode | Cursor | Copilot CLI |
|---|---|---|---|---|---|---|---|
| Structured subagent outputs | native, `Agent` findings returned schema-validated | n/a, no subagent primitive | n/a, no subagent primitive | n/a, no subagent primitive | unknown, `task` returns prose; schema validation unverified | n/a, no subagent primitive | n/a, no subagent primitive |
| Background subagents | native, `Agent` with `run_in_background` | n/a, no subagent primitive | n/a, no subagent primitive | n/a, no subagent primitive | unknown, `task` background dispatch unverified | n/a, no subagent primitive | n/a, no subagent primitive |
| Per-agent model/effort tiers | native, per-`Agent` `model` override; per-agent effort in agent definitions | n/a, no subagent primitive | n/a, no subagent primitive | n/a, no subagent primitive | partial, per-mode model pinning in mode files; effort control unverified | n/a, no subagent primitive | n/a, no subagent primitive |
| Task-tracker dependency ordering | conditional, `TodoWrite` items carry blocked-by edges when the session exposes the tool; it is frequently absent, and ordering then rests on the printed ledger block plus the work-doc's `## 0. Phase ledger` section, a written law, never tool-level edges | n/a, no todo primitive | n/a, no todo primitive | n/a, no todo primitive | unknown, `todowrite` exists; dependency edges unverified | n/a, no todo primitive | n/a, no todo primitive |
| Batched wizard rounds | native, back-to-back `AskUserQuestion` calls in one turn | n/a, no batched-question primitive | n/a, no batched-question primitive | n/a, no batched-question primitive | n/a, no batched-question primitive | n/a, no batched-question primitive | n/a, no batched-question primitive |
| Published work-doc page | native, the `Artifact` tool publishes the work-doc file and redeploys to the same URL on every republish **from the same conversation**; from a different one, a republish that does not pass the existing URL back mints a separate artifact instead of updating the first, which is why the URL is recorded in the work-doc's `page_url` frontmatter field rather than kept in the session ([work-doc-artifact.md](work-doc-artifact.md)) | unknown, no page-publishing tool verified for this runtime | unknown, no page-publishing tool verified for this runtime | unknown, no page-publishing tool verified for this runtime | unknown, no page-publishing tool verified for this runtime | unknown, no page-publishing tool verified for this runtime | unknown, no page-publishing tool verified for this runtime |
| Session orientation map | native, the `SessionStart` hook in `hooks/hooks.json` injects `rules/plugin-map.md` once per session | n/a, no session-start injection primitive; the mirrored map sits on disk unread | n/a, no session-start injection primitive; the mirrored map sits on disk unread | n/a, no session-start injection primitive; the mirrored map sits on disk unread | n/a, no session-start injection primitive; the mirrored map sits on disk unread | n/a, no session-start injection primitive; the mirrored map sits on disk unread | n/a, no session-start injection primitive, and no mirrored `rules/` tree either; the map is absent here |

Six `unknown` cells and not six `n/a`, on purpose. Every `n/a` in this table is grounded in
the primitive mapping table above it, and that table carries no publish primitive for any
runtime, Claude Code included, so it cannot ground an absence claim here. Nobody has checked
those six runtimes' own tool lists for a way to publish a page, and the honest cell for an
unchecked claim is `unknown`. The wording is identical in all six because it is one
unverified claim, not six separate investigations. Publishing is optional everywhere, so an
`unknown` costs nothing: the degrade path is the file on disk, which every runtime already
gets.

The six `n/a` cells on the session orientation map row are grounded the way that sentence
demands, in the `always-on injection` row of the mapping table. Only Claude Code carries a
hook facility that runs plugin-supplied context into a session, and `hooks/` is mirrored into
`dist/claude-code/` alone, so on the other six runtimes there is nothing for a `SessionStart`
entry to attach to. That is a stated boundary rather than an invented fallback, and the
distinction is deliberate: the map is a document, not a mechanism, so the honest degrade is
the document arriving unread. Naming a substitute injector here would describe something this
repo does not ship, and a fabricated cell is worse than a stated gap.

## Sync output per runtime

- `dist/claude-code/`, full skill bundle with native tool names (`AskUserQuestion`, `Agent`, `Read`, `Write`, `Edit`, `Grep`, `Bash`, `TodoWrite`); drop-in to `~/.claude/skills/hackify/`.
- `dist/codex-cli/`, prompt files plus `AGENTS.md` references; MCP filesystem config snippet for `read_file`/`write_file`/`apply_patch`.
- `dist/codex-app/`, prompt files structured for upload; manifest lists required MCP tools.
- `dist/gemini-cli/`, markdown files plus `GEMINI.md` include directives; extension JSON snippet registering `read_file`/`write_file`/`replace`/`grep`/`run_shell_command`.
- `dist/opencode/`, custom-mode markdown files using `read`/`write`/`edit`/`grep`/`bash`/`task`/`todowrite` native names.
- `dist/cursor/`, `.mdc` rule files inlining the workflow; subagent steps rewritten as inline prompts.
- `dist/copilot-cli/`, single concatenated prompt-context file with manual-install instructions; no automatic discovery.

## Host-interpreter dependencies (skills that ship an executable engine)

The eight load-bearing primitives are interpreter-free: the core hackify workflow is pure markdown
and runs wherever the `shell` primitive runs. Two companion skills ship an executable engine that rides
the `shell` primitive and therefore assumes a host interpreter on PATH, honest to state, since
no runtime adapter can conjure one:

| Skill | Engine | Interpreter assumed | If absent, degradation |
|---|---|---|---|
| `lawkeeper` | `scripts/audit_scan.py` deterministic scanner (Phase 2) | `python3` | Report the gap and fall through to the interpreter-free semantic subagent pass (Phase 3). |
| `hackify` (**core**, since v0.9.0) | the law-scout runs that same `audit_scan.py --paths-from` at both Phase 3 run points, the agent over its own file allowlist and the parent at round-end, and at Phase 5 start ([law-scout.md](law-scout.md)) | `python3` | Record `deterministic tier unavailable (no python3)` as a staging row and run the law-scout's semantic tier only, Reviewer B's seven lenses are interpreter-free. Never drop the mechanical tier silently. |
| `hackify` (**core**, since v0.9.0) | the ship gate starts and stops a real process and polls a readiness probe ([ship-gate.md](ship-gate.md)) | background process control + a port or HTTP probe from the shell primitive | On a runtime that cannot background a process or poll a port, run the build leg (a plain foreground command) and record `ship.boot` / `ship.smoke` as `⏭ skipped, runtime cannot supervise a background process`. Coverage degrades to a written gap, never to a silent pass. |
| `codewalk` | `assets/serve.js` viewer server + `build-playbook.mjs` | `node` | Fall back to the documented server chain (`python3`/`python`/`npx serve`/`php`/`ruby`) for serving the already-generated `.codewalk/<slug>/` artifact. |

Neither interpreter is a hackify-core requirement, only those two skills' engines need them,
and each degrades to a stated, non-silent fallback. Document any future skill that adds a host
interpreter here so the multi-runtime story stays honest.

## When to update this file

Update this file whenever a target runtime adds, renames, or removes a tool that maps to any of the 12 primitives, whenever a new runtime is added to the support set, or whenever a runtime's plugin model crosses a tier boundary (best-effort gains native subagent dispatch, for example). No script reads this table, so drift here is silent rather than loud: a cell that stops matching its emitter under `scripts/sync-runtimes.d/` breaks nothing and reports nothing. Change both in the same commit.
